from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

class LightShiftGateRamp(pulse_sequence):
    
    #name = 'Ramsey'

    scannable_params = {
                        
        'LightShift.duration': [(0, 1.0, 0.5, 'ms') ,'starkshift'],
        'LightShift.gate2_detuning':[(-100,100,10,'kHz'),'starkshift'],
        'LightShift.gate2_echoPhase':[(0,360,5,'deg'),'starkshift'],
        'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey'],
        }

    show_params= ['LightShiftGate.parity',

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
                  'LightShift.echoPhase_enable',
                  'LightShift.rampTime',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',

                  'Ramsey.echo_enable',
                                                      
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable']

    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftRamp import LightShiftRamp
        
        frequency_advance_duration = U(6, 'us')
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping   
        # calculating the 729 freq form the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        print "1234"
        print " freq 729 " , freq_729
        print " Wait time ", self.parameters.RamseyScanGap.ramsey_duration
        
        ls = self.parameters.LightShift
        timeShift=.5*ls.duration

        # building the sequence
        self.addSequence(StatePreparation)     

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg') 
                                          })       

        self.addSequence(LightShiftRamp,{'LightShift.duration':  timeShift,
                                     'LightShift.second_gate': True,  
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg')   
                                      }) 

        if self.parameters.Ramsey.echo_enable:
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  rf.duration,
                                           'Excitation_729.rabi_excitation_phase': U(0, 'deg') 
                                            })
       
            time = (timeShift + frequency_advance_duration*3 + rf.duration)
            print "time",time
            time = time['s']
            print "time", time

            detuning = ls.gate2_detuning['Hz']

            extraPhase = U(np.rad2deg(-time*detuning*2.*np.pi)%360.,'deg')
            print "phase",extraPhase

        else:
            extraPhase = U(0,'deg')

        self.addSequence(LightShiftRamp,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': ls.gate2_echoPhase + extraPhase,
                                     'LightShift.second_gate': True,
                                      })

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg')
                                          }) 
        if self.parameters.LightShiftGate.parity:
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                             'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                             'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                             'Excitation_729.rabi_excitation_phase': self.parameters.Ramsey.second_pulse_phase 
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