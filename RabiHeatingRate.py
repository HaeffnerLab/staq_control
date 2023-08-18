9from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
from RabiFlopping import RabiFlopping


class rabi_time_scan(RabiFlopping):
    scannable_params = {
        'RabiFlopping.duration':  [(0., 50., 3, 'us'), 'rabi'],
        }


class RabiHeatingRate(pulse_sequence):
 
    scannable_params = {
        'Heating.background_heating_time':  [(0., 50., 2., 'us'), 'rabi'],
              }
    sequence = rabi_time_scan
        
        
