from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from common.client_config import client_info as cl


from subsequences.EmptySequence import EmptySequence 
from RabiFlopping import RabiFlopping
from Spectrum import Spectrum
from CalibAllLines import Calibrations_CalibAllLines


class Calibrations_ScheduleCalibrations(EmptySequence):
    
    scannable_params = {'RabiFlopping.duration': [(0.0, 0.0, 1.0, 'us'), 'rabi'],}
    checked_params = ['RabiFlopping.duration'] 
    
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        import labrad
        cxn = labrad.connect()

        # priority can be: 'Normal', 'First in Queue', or 'Pause All Others'
        # sc.new_sequence(sequence_name, settings,  duration, priority, start_now)

        # Add here the sequences to be scheduled 
        sc.new_sequence_schedule('Calibrations_CalibAllLines', 
            [('CalibLine2', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz ')), 
            ('CalibLine1', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz'))], 
            U(1, 'min'), 
            'First in Queue', 
            False)

        # Kill this sequence 
        ID, name = sc.get_running()[0]
        sc.stop_sequence(ID)
        cxn.disconnect()