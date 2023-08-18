from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

class StarkForce(pulse_sequence):
    
    #name = 'Ramsey'

    scannable_params = {
                        
        'LightShift.duration': [(0, 1.0, 0.5, 'ms') ,'starkshift'],
        'LightShift.rsb_pitime': [(0, 5.0, 120.0, 'us') ,'starkshift'],
        'RamseyScanGap.ramsey_duration': [(0, 1.0, 0.5, 'ms') ,'ramsey']
        }

    show_params= ['LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.gate1_echophase',
                  'LightShift.gate2',
                  'LightShift.gate2_amplitude',
                  'LightShift.gate2_echophase',
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

    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.StateReadout import StateReadout
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShift import LightShift
        
        frequency_advance_duration = U(6,'us')
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping   
        # calculating the 729 freq form the Rabi flop params
        freq_rsb=self.calc_freq(rf.line_selection , rf.selection_sideband , -1)

        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        print "1234"
        print " freq 729 " , freq_729
        print " Wait time ", self.parameters.RamseyScanGap.ramsey_duration
        
        extraTime = self.parameters.RamseyScanGap.ramsey_duration
        ls = self.parameters.LightShift
        timeShift=.5*ls.duration

        frequency_advance_duration = U(6, 'us')
        ampl_off = U(-63.0, 'dBm')

        # building the sequence
        self.addSequence(StatePreparation)   

        self.addSequence(LightShift,{'LightShift.duration':  frequency_advance_duration,
                                       'LightShift.second_gate': True,
                                       'LightShift.gate1_phase': U(0, 'deg'),
                                       'LightShift.gate2_phase': U(0,'deg'),
                                       'LightShift.gate1_amplitude': ampl_off,
                                       'LightShift.gate2_amplitude': ampl_off,
                                       #'LightShift.changeDDS': True,
                                           }) 
        #intial state=DD
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+self.parameters.RamseyScanGap.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': True,
                                          })

        #first displacement phase = 0
        self.addSequence(LightShift,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0, 'deg'),
                                     'LightShift.gate2_phase': U(0, 'deg'),
                                     'LightShift.second_gate': True,
                                     #'LightShift.changeDDS': True,
                                      }) 
        #print('lightshift p1 duration:',timeShift)

        if self.parameters.Ramsey.echo_enable:
          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : .5*extraTime})

          self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+self.parameters.RamseyScanGap.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          })

          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : .5*extraTime})

          time = (timeShift  + rf.duration)
          time = time['s']

          detuning = ls.gate2_detuning['Hz']

          extraPhase = U(np.rad2deg(-time*np.abs(detuning)*2.*np.pi)%360.,'deg')

        else:
          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : extraTime})
          extraPhase = U(0,'deg')

        #print('gap duration:',extraTime)

        self.addSequence(LightShift,{'LightShift.duration': timeShift,
                                     'LightShift.gate1_phase':ls.gate1_echoPhase,
                                     'LightShift.gate2_phase':U((ls.gate2_echoPhase['deg']+extraPhase['deg'])%360,'deg'),
                                     'LightShift.second_gate': True,
                                     #'LightShift.changeDDS': False,
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
    def run_initial(cls,cxn, parameters_dict):
      pass
        
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        #print "Running in loop Rabi_floping"
        pass
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass

        

#if __name__=='__main__':
#    #pv = TreeDict.fromdict({'DopplerCooling.duration':U(5, 'us')})
    #ex = Sequence(pv)
    #psw = pulse_sequence_wrapper('example.xml', pv)
#    print 'executing a scan gap'
#    Ramsey.execute_external(('Ramsey.ramsey_time', 0, 10.0, 0.1, 'ms'))