
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time

class StarkForce_TTL(pulse_sequence):
    
    #name = 'Ramsey'

    scannable_params = {
                        
        'LightShift.duration': [(0.0001, 1.0, 0.5, 'ms') ,'starkshift'],
        'LightShift.rsb_pitime': [(0, 5.0, 120.0, 'us') ,'starkshift'],
        'RamseyScanGap.ramsey_duration': [(0, 1.0, 0.5, 'ms') ,'ramsey']
        }

    show_params= ['LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.gate2_amplitude',
                  'LightShift.gate3_amplitude',
                  'LightShift.rsb_pitime',
                  'LightShift.mutual_detuning',
                  'LightShift.gate2_detuning',
                  'LightShift.order',
                  'LightShift.selection_sideband',

                  'RamseyScanGap.ramsey_duration',
                  'RamseyScanPhase.scanphase',
                  'RamseyScanGap.detuning',

                  'Ramsey.echo_enable',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                                                      
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable']
                 
    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        ######### set marconi freq
        #pass
        # getting the params
        ls = parameters_dict.LightShift  

        if ls.gate1 == "gate1":
          # creating an marconi instance
          #global marconi_3
          marconi = cxn.marconi_2024 #gate 1
          marconi_2 = cxn.marconi_2024_g2 #gate 2
          #marconi_3 = cxn.marconi_2024_g3 #gate 3
                                    
          gate_freq=ls.gate_frequency
          detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*parameters_dict.TrapFrequencies[ls.selection_sideband]*ls.order
          f=gate_freq+ detuning
           
          a1=ls.gate1_amplitude     
          a2=ls.gate2_amplitude
          a3=ls.gate3_amplitude                       
          # changing the frequency and amplitude of the marconi's
          marconi.amplitude(a1)
          marconi.frequency(gate_freq)
          marconi_2.amplitude(a2)
          marconi_2.frequency(f)
          #marconi_3.amplitude(a3)
          #marconi_3.frequency(f)

          print "Gate 1 run initial " , gate_freq, "at ", a1
          print "Gate 2 run initial " , f, "at ", a2
          #print "Gate 3 run initial " , f, "at ", a3

          global first_run
          first_run=True

          time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.StateReadout import StateReadout
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftTTL import LightShiftTTL
        
        frequency_advance_duration = U(6,'us')
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping
        r = self.parameters.Ramsey      
        # calculating the 729 freq form the Rabi flop params
        freq_rsb=self.calc_freq(rf.line_selection , rf.selection_sideband , -1)

        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        print "1234"
        print " freq 729 " , freq_729
        print " Wait time ", self.parameters.RamseyScanGap.ramsey_duration
        
        extraTime = self.parameters.RamseyScanGap.ramsey_duration
        ls = self.parameters.LightShift
        timeShift=.5*ls.duration

        if r.echo_enable:
          total_time = (timeShift  + rf.duration)
          total_time = total_time['s']

          detuning = ls.gate2_detuning['Hz']

          extraPhase = U(np.rad2deg(-total_time*np.abs(detuning)*2.*np.pi)%360.,'deg')

          '''global first_run
                              
                                        if first_run:
                                          global marconi_3
                                          marconi_3.phase(extraPhase) 
                                          print "phase", extraPhase
                                          first_run=False
                                          time.sleep(0.5)'''

        else:
          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : extraTime})
          extraPhase = U(0,'deg')
          print "phase", extraPhase


        # building the sequence
        self.addSequence(StatePreparation)   

        #intial state=DD
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+self.parameters.RamseyScanGap.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': True,
                                          })

        #first displacement phase = 0
        self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                     'LightShift.second_gate': True,  
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'), 
                                     'LightShift.second_gate2': False,
                                      }) 
        #print('lightshift p1 duration:',timeShift)

        if r.echo_enable:
          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : .5*extraTime})

          self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+self.parameters.RamseyScanGap.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          })

          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : .5*extraTime})

        #print('gap duration:',extraTime)

        self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'),
                                     'LightShift.second_gate': True,
                                     'LightShift.second_gate2': False,
                                      })

        #final state=SS
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+self.parameters.RamseyScanGap.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          })
        
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_rsb+self.parameters.RamseyScanGap.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  ls.rsb_pitime,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': True,
                                          }) 

        
        self.addSequence(StateReadout)
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        #print "Running in loop Rabi_floping"
        global first_run
        first_run=True
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass

        

#if __name__=='__main__':
#    #pv = TreeDict.fromdict({'DopplerCooling.duration':U(5, 'us')})
    #ex = Sequence(pv)
    #psw = pulse_sequence_wrapper('example.xml', pv)
#    print 'executing a scan gap'
#    Ramsey.execute_external(('Ramsey.ramsey_time', 0, 10.0, 0.1, 'ms'))