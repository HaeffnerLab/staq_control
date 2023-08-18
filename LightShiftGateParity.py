from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

class LightShiftGateParity(pulse_sequence):
    
    #name = 'Ramsey'

    fixed_params = {
                    'StateReadout.readout_mode': "pmt_parity",
                    'RabiFlopping.line_selection': 'S-1/2D-1/2',
                    'RabiFlopping.order': 0,
                    'StatePreparation.sideband_cooling_enable': True,
                    'StatePreparation.optical_pumping_enable': True,
                    'SidebandCooling.line_selection': 'S-1/2D-5/2',
                    'SidebandCooling.order': -1,
                    'SidebandCooling.sideband_selection': 'axial_frequency',}

    scannable_params = {
      
        'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey'],
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
                  'LightShift.echoPhase_enable',

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
        from subsequences.LightShift import LightShift
        
        frequency_advance_duration = U(6, 'us')
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping   
        # calculating the 729 freq from the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        
        ls = self.parameters.LightShift

        ## Can fix time to be exactly the desired gate time.
        if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
        else:
            timeShift=.5*ls.duration

        # building the sequence
        self.addSequence(StatePreparation)     

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                         'Excitation_729.changeDDS': True 
                                          })       

        self.addSequence(LightShift,{'LightShift.duration':  timeShift,
                                     'LightShift.second_gate': True,  
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'),
                                     'LightShift.changeDDS': True,   
                                      }) 

        if self.parameters.Ramsey.echo_enable:
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  rf.duration,
                                           'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                           'Excitation_729.changeDDS': False,  
                                            })
       
            time = (timeShift + rf.duration)
            time = time['s']

            detuning = ls.gate2_detuning['Hz']

            extraPhase = U(np.rad2deg(-time*np.abs(detuning)*2.*np.pi)%360.,'deg')

        else:
            extraPhase = U(0,'deg')

        self.addSequence(LightShift,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': ls.gate2_echoPhase + extraPhase,
                                     'LightShift.second_gate': True,
                                     'LightShift.changeDDS': False, 
                                      })

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          })
        ## Parity check pi/2 
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration/2.,
                                         'Excitation_729.rabi_excitation_phase': self.parameters.Ramsey.second_pulse_phase,
                                         'Excitation_729.changeDDS': False, 
                                          }) 

        self.addSequence(StateReadout)
        
    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(True)
        
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        #print "Running in loop Rabi_floping"
        pass
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(False)

        

#if __name__=='__main__':
#    #pv = TreeDict.fromdict({'DopplerCooling.duration':U(5, 'us')})
    #ex = Sequence(pv)
    #psw = pulse_sequence_wrapper('example.xml', pv)
#    print 'executing a scan gap'
#    Ramsey.execute_external(('Ramsey.ramsey_time', 0, 10.0, 0.1, 'ms'))