from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

class LightShiftGate_DD(pulse_sequence):
    
    #name = 'Ramsey'

    fixed_params = {
                    'StateReadout.readout_mode': "pmt_states"}

    scannable_params = {
                        
        'LightShift.duration': [(0, 0.5, 0.02, 'ms') ,'starkshift'],
        'LightShift.gate2_detuning':[(5,100,10,'kHz'),'starkshift'],
        'LightShift.gate1_amplitude':[(-30,-14,1,'dBm'),'ramsey'],
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

                  'Ramsey.dynamic_decoupling_enable',
                  'Ramsey.dd_repetitions',
                                                      ]

    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShift import LightShift
        
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
            timeShift=ls.duration

        # building the sequence
        self.addSequence(StatePreparation)     

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                         'Excitation_729.changeDDS': True 
                                          })    

        if r.dynamic_decoupling_enable==False or r.dd_repetitions == 0:
          self.addSequence(LightShift,{'LightShift.duration':  timeShift,
                                       'LightShift.second_gate': True,  
                                       'LightShift.gate1_phase': U(0,'deg'),
                                       'LightShift.gate2_phase': U(0,'deg'),
                                       'LightShift.changeDDS': True,   
                                        })
        else:
          pulse_len=(0.5)*timeShift/(r.dd_repetitions)
          time = (pulse_len + rf.duration)
          time = time['s']

          detuning = ls.gate2_detuning['Hz']

          extraPhase = U(np.rad2deg(-time*np.abs(detuning)*2.*np.pi)%360.,'deg')
          
          for i in range(int(r.dd_repetitions)):  

            self.addSequence(LightShift,{'LightShift.duration':  pulse_len,
                                         'LightShift.second_gate': True,  
                                         'LightShift.gate1_phase': U(0,'deg'),
                                         'LightShift.gate2_phase': U(0,'deg'),
                                         'LightShift.changeDDS': False,   
                                          })

            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          }) 

            self.addSequence(LightShift,{'LightShift.duration':  pulse_len,
                                         'LightShift.second_gate': True,  
                                         'LightShift.gate1_phase': U(0,'deg'),
                                         'LightShift.gate2_phase': ls.gate2_echoPhase + extraPhase,
                                         'LightShift.changeDDS': False   
                                          })
            

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
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