from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time

class LightShiftGate_TTL(pulse_sequence):
    
    #name = 'Ramsey'

    fixed_params = {
                    'StateReadout.readout_mode': "pmt_states"}

    scannable_params = {
                        
        'LightShift.duration': [(0.0001, 0.5, 0.02, 'ms') ,'starkshift'],
        'LightShift.gate2_detuning':[(5,100,10,'kHz'),'starkshift'],
        'LightShift.gate2_amplitude':[(-30,-14,1,'dBm'),'ramsey'],
        'LightShift.gate2_echoPhase': [(0, 360, 15, 'deg') ,'ramsey']
        }

    show_params= [
                  'LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.gate2',
                  'LightShift.gate2_amplitude',
                  'LightShift.gate2_echoPhase',
                  'LightShift.mutual_detuning',
                  'LightShift.gate2_detuning',
                  'LightShift.order',
                  'LightShift.selection_sideband',
                  'LightShift.fixedTime',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',

                  'Ramsey.echo_enable',
                  'Ramsey.second_pulse_phase',
                                                      ]

    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        ######### set marconi freq
        #pass
        # getting the params
        ls = parameters_dict.LightShift
        rf = parameters_dict.RabiFlopping  
        r = parameters_dict.Ramsey   

        if ls.gate2 == "gate2":
          # creating an marconi instance
          marconi = cxn.marconi_2024
          marconi_second = cxn.marconi_2024_g2
                                    
          gate_freq=ls.gate_frequency
          detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*parameters_dict.TrapFrequencies[ls.selection_sideband]*ls.order
          f=gate_freq+ detuning
                                    
          a=ls.gate2_amplitude
                                                      
          # changing the amplitude and frequency of the marconi
          marconi.frequency(f)
          marconi.amplitude(a)

          print "run initial " , f, "at ", a

          ## Can fix time to be exactly the desired gate time.
          if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
          else:
            timeShift=.5*U(0.0001,'ms')

          timelen = (timeShift + rf.duration)
          timelen = timelen['s']

          detuning = ls.gate2_detuning['Hz']
         
          if r.echo_enable:
            extraPhase = U(np.rad2deg(-timelen*np.abs(detuning)*2.*np.pi)%360.,'deg')
          else:
            extraPhase = U(0,'deg')

          print extraPhase,timelen

          marconi_second.frequency(f)
          marconi_second.amplitude(a)
          marconi_second.phase(extraPhase) 

          global prev_time
          global prev_amp  

          prev_time = .5*U(0.0001,'ms')     
          prev_amp = ls.gate2_amplitude
          time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''                                            
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftTTL import LightShiftTTL
        
        frequency_advance_duration = U(6, 'us')
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping  
        r = self.parameters.Ramsey   
        # calculating the 729 freq from the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        
        ls = self.parameters.LightShift

        ## Can fix time to be exactly the desired gate time.
        if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
        else:
            timeShift=.5*ls.duration

        frequency_advance_duration = U(6, 'us')
        ampl_off = U(-63.0, 'dBm')

        # building the sequence
        self.addSequence(StatePreparation)  

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                         'Excitation_729.changeDDS': True 
                                          })       

        print 'gatelen', timeShift
        self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                     'LightShift.second_gate': True,  
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'), 
                                     'LightShift.second_gate2': False,
                                      }) 

        if r.echo_enable:
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  rf.duration,
                                           'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                           'Excitation_729.changeDDS': False,  
                                            })

        self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'),
                                     'LightShift.second_gate': True,
                                     'LightShift.second_gate2': True,
                                      })

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase':  r.second_pulse_phase,
                                         'Excitation_729.changeDDS': False,
                                          }) 

        self.addSequence(StateReadout)

        
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        print x
        #print "Running in loop Rabi_floping"
        ######### set marconi freq
        #pass
        # getting the params
        
        global prev_time
        global prev_amp

        ls = parameters_dict.LightShift
        rf = parameters_dict.RabiFlopping  
        r = parameters_dict.Ramsey 
                                            
        if ls.gate2 == "gate2":
          # creating an marconi instance
          marconi = cxn.marconi_2024
          marconi_second = cxn.marconi_2024_g2
                                                            
          gate_freq=ls.gate_frequency
          detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*parameters_dict.TrapFrequencies[ls.selection_sideband]*ls.order
          f=gate_freq+ detuning

          amp_index=ls.gate2_amplitude-prev_amp
          a=ls.gate2_amplitude+amp_index                                                                 
          # changing the amplitude and frequency of the marconi
          marconi.frequency(f)
          marconi.amplitude(a)
                                                            
          print "run continuous " , f, "at ", a 

          if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
          else:
            timeShift=.5*ls.duration

          timelen = (timeShift + rf.duration)
          timelen = timelen['s']

          detuning = ls.gate2_detuning['Hz']

          time_index=timeShift['s']-prev_time['s']
          total_time=timelen+time_index

          if r.echo_enable:
            extraPhase = U(np.rad2deg(-(total_time)*np.abs(detuning)*2.*np.pi)%360.,'deg')
          else:
            extraPhase = U(0,'deg')

          print  "DURATION IS " , ls.duration, ' AND amp is', a
          print  "Time index IS " , U(time_index, 's') , ' AND AMP index is', amp_index

          marconi_second.frequency(f)
          marconi_second.amplitude(a)
          marconi_second.phase(extraPhase)

          prev_time=timeShift
          prev_amp=ls.gate2_amplitude

          time.sleep(0.5) #'''

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass
