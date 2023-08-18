from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
from LightShiftGateParity_TTL import LightShiftGateParity_TTL

class Light_Shift_Gate_Parity_TTL_Scan(LightShiftGateParity_TTL):
    
    #name = 'LightShiftGateParity_TTL'

    scannable_params = {
       'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey'],               
      }

    @classmethod
    def run_finally(cls, cxn, parameter_dict, data, data_x):
      data=data.sum(1)
      fit_params=cls.parity_sin_fit(data_x, data, return_all_params = True)
      return fit_params[0]

class LightShiftGateParityTTLScan(pulse_sequence):
    
    scannable_params = {
        'LightShift.duration': [(30, 50, 1, 'us') ,'starkshift'],
        'LightShift.power_offset':[(-10,10,1,'dBm'),'ramsey'],
        'LightShift.gate1_amplitude':[(-10,10,1,'dBm'),'ramsey'],
        'LightShift.gate2_amplitude':[(-10,10,1,'dBm'),'ramsey'],
        'LightShift.PiOverTwoTimeDuration' :[(0.0,50,1,'us'),'ramsey'],
        'LightShift.PiTimeDuration' :[(0.0,50,1,'us'),'ramsey'],
    }

    sequence = Light_Shift_Gate_Parity_TTL_Scan