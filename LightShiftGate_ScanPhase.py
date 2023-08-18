from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
from LightShiftGate import LightShiftGate

class lsg_scan_phase(LightShiftGate):
    
    #name = 'Ramsey'

    scannable_params = {
         
       'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey'],
      }

    @classmethod
    def run_finally(cls,cxn, parameter_dict, data, data_x):
      	data=np.transpose(data)[0]
      	fit_params=cls.sin_fit(data_x,data, return_all_params = True)
      	return 2*fit_params[0]

class LightShiftGateScanPhase(pulse_sequence):
    
    scannable_params = {'LightShift.duration': [(0, 0.5, 0.02, 'ms') ,'starkshift'],}

    sequence = lsg_scan_phase