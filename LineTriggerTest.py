from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
import time
from treedict import TreeDict
import numpy as np



class LineTriggerTest(pulse_sequence):
    
                          
    scannable_params = {   'Motion_Analysis.ramsey_duration': [(0, 10.0, 0.5, 'ms') ,'ramsey']}
 

    show_params= ['Motion_Analysis.pulse_width_397',
                  'Motion_Analysis.amplitude_397',
                  'Motion_Analysis.sideband_selection',
                  'Motion_Analysis.detuning',


                 
                 
                ]

    fixed_params = {'Display.relative_frequencies': True

                    }
    
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        pass
    
    @classmethod
    def run_in_loop(cls, cxn, parameters_dict, data_so_far,data_x):
        pass
       


    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        pass
        # cxn.pulser.switch_manual('397mod', False)
        

        
    def sequence(self):        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.OpticalPumping import OpticalPumping
        from subsequences.MotionalAnalysis import MotionalAnalysis
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
        from subsequences.RabiExcitation import RabiExcitation
        
        

        self.end = U(10., 'us')
        self.addSequence(TurnOffAll)
        
        self.addSequence(MotionalAnalysis)
        




