import numpy as np
import labrad 
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
from common.client_config import client_info as cl
from signals import Signals as sig

global calibration_count     
calibration_count = 0   
global initial_sequence 
initial_sequence = ''
global initial_sequence_settings
initial_sequence_settings = []


class CalibLine1(pulse_sequence):

    scannable_params = {'Excitation729.frequency729' : [(-7.0, 7.0, 0.7, 'kHz'), 'calibLine1', True]}
    checked_params = ['Excitation729.frequency729']

    def sequence(self):
        from StatePreparation import StatePreparation
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.StateReadout import StateReadout

        p = self.parameters
        line1 = p.DriftTracker.line_selection_1

        freq729 = self.calc_freq(line1)
        freq729 = freq729 + p.Excitation729.frequency729
        amp729 = p.CalibrateLines.amplitude729_line1
        channel729 = p.CalibrateLines.channel_729
        dur729 = p.CalibrateLines.duration729
        print 'amp729 ', amp729

        self.addSequence(StatePreparation, {'StatePreparation.sideband_cooling_enable': False,
                                            'Heating.background_heating_time': U(0,'ms')})
        self.addSequence(RabiExcitation, {'Excitation_729.rabi_excitation_frequency': freq729,
                                         'Excitation_729.rabi_excitation_amplitude': amp729,
                                         'Excitation_729.rabi_excitation_duration': dur729,
                                         'Excitation_729.channel_729': channel729
                                          })
        self.addSequence(StateReadout)

    @classmethod
    def run_initial(cls, cxn, parameters_dict):

        carrier_translation = {'S+1/2D-3/2':'c0',
                               'S-1/2D-5/2':'c1',
                               'S+1/2D-1/2':'c2',
                               'S-1/2D-3/2':'c3',
                               'S+1/2D+1/2':'c4',
                               'S-1/2D-1/2':'c5',
                               'S+1/2D+3/2':'c6',
                               'S-1/2D+1/2':'c7',
                               'S+1/2D+5/2':'c8',
                               'S-1/2D+3/2':'c9',
                               }

        line = parameters_dict.DriftTracker.line_selection_1
        shift = parameters_dict.Carriers[carrier_translation[line]]

        pv = cxn.parametervault
        pv.set_parameter('Display', 'shift', shift)

    @classmethod
    def run_finally(cls,cxn, parameters_dict, all_data, freq_data):
        global carr_1_global

        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "error with the data"
            return

        peak_fit = cls.gaussian_fit(freq_data, all_data)
        if not peak_fit:
            carr_1_global = None
            ident = int(cxn.scriptscanner.get_running()[0][0])
            print "Can't fit peak, stopping sequence {}".format(ident)                   
            cxn.scriptscanner.stop_sequence(ident)
            return

        print "peak_fit{}".format(peak_fit)
        peak_fit = U(peak_fit,'MHz')

        carr_1_global = peak_fit


class CalibLine2(pulse_sequence):

    scannable_params = {'Excitation729.frequency729' : [(-7.0, 7.0, 0.7, 'kHz'), 'calibLine2', True]}
    checked_params = ['Excitation729.frequency729']

    def sequence(self):
        from StatePreparation import StatePreparation
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.StateReadout import StateReadout

        p = self.parameters
        line2 = p.DriftTracker.line_selection_2

        freq729 = self.calc_freq(line2)
        freq729 = freq729 + p.Excitation729.frequency729
        amp729 = p.CalibrateLines.amplitude729_line2
        channel729 = p.CalibrateLines.channel_729
        dur729 = p.CalibrateLines.duration729

        self.addSequence(StatePreparation, {'StatePreparation.sideband_cooling_enable': False,
                                            'Heating.background_heating_time':U(0,'ms')})
        self.addSequence(RabiExcitation, {'Excitation_729.rabi_excitation_frequency': freq729,
                                         'Excitation_729.rabi_excitation_amplitude': amp729,
                                         'Excitation_729.rabi_excitation_duration': dur729,
                                         'Excitation_729.channel_729': channel729
                                         })
        self.addSequence(StateReadout)

    @classmethod
    def run_initial(cls,cxn, parameters_dict):

        carrier_translation = {'S+1/2D-3/2':'c0',
                               'S-1/2D-5/2':'c1',
                               'S+1/2D-1/2':'c2',
                               'S-1/2D-3/2':'c3',
                               'S+1/2D+1/2':'c4',
                               'S-1/2D-1/2':'c5',
                               'S+1/2D+3/2':'c6',
                               'S-1/2D+1/2':'c7',
                               'S+1/2D+5/2':'c8',
                               'S-1/2D+3/2':'c9',
                               }
        line = parameters_dict.DriftTracker.line_selection_2
        shift = parameters_dict.Carriers[carrier_translation[line]]

        pv = cxn.parametervault
        pv.set_parameter('Display', 'shift', shift)
        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(True)

    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, freq_data):
        
        global carr_1_global 
        
        carr_1 = carr_1_global
        
        if not carr_1:
            return
        
        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "ValueError"
            return
            
        peak_fit = cls.gaussian_fit(freq_data, all_data)
        
        if not peak_fit:
            print "peak fitting did not work"
            return
        
        peak_fit = U(peak_fit, "MHz") 
          
        carr_2 = peak_fit
        
        line_1 = parameters_dict.DriftTracker.line_selection_1
        line_2 = parameters_dict.DriftTracker.line_selection_2
        submission = [(line_1, carr_1), (line_2, carr_2)]

        global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password,tls_mode='off')
        global_sd_cxn.sd_tracker_global.set_measurements(submission, cl.client_name) 
        global_sd_cxn.disconnect()

        # Save last position of the lines 
        sc = cxn.scriptscanner 
        sc.set_parameter('CalibrateLines', 'line_1_old_value', carr_1)
        sc.set_parameter('CalibrateLines', 'line_2_old_value', carr_2)
        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(False)


class Calibrations_CalibAllLines(pulse_sequence):

    is_composite = True
    fixed_params = {
                    'Display.relative_frequencies': False,
                    # 'StatePreparation.sideband_cooling_enable': False,
                    'StateReadout.readout_mode': "pmt_excitation"}
                    
    sequence = [CalibLine1, CalibLine2] 

    show_params= ['DriftTracker.line_selection_1',
                'DriftTracker.line_selection_2',
                'CalibrateLines.amplitude729_line1',
                'CalibrateLines.amplitude729_line2',
                'CalibrateLines.channel_729',
                'CalibrateLines.duration729'
                ]

    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        
#         p_cxn=cxn.pulser
#         p_cxn.line_trigger_state(True)
        
        global calibration_count

        # Check if there are lines saved in the drift tracker 
        global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
        if len(dict(global_sd_cxn.sd_tracker_global.get_line_center_global())[cl.client_name]) == 0:

            # Retrieve last position of lines 
            val_1 = parameters_dict.CalibrateLines.line_1_old_value 
            val_2 = parameters_dict.CalibrateLines.line_2_old_value 
            line_1 = parameters_dict.DriftTracker.line_selection_1
            line_2 = parameters_dict.DriftTracker.line_selection_2

            # Save last line position in drift tracker 
            submission = [(line_1, val_1), (line_2, val_2)]
            global_sd_cxn.sd_tracker_global.set_measurements(submission, cl.client_name) 

            # Change range of scannable parameters
            sc = cxn.scriptscanner
            sc.emit_scannable_modified(('Calibrations_CalibAllLines', 'CalibLine1', 'Excitation729.frequency729', (-100.0, 100.0, 10.0)))
            sc.emit_scannable_modified(('Calibrations_CalibAllLines', 'CalibLine2', 'Excitation729.frequency729', (-100.0, 100.0, 10.0)))

            # Change 729 power
            # new_amp_line_1 = sc.get_parameter('CalibrateLines', 'amplitude729_line1') + U(10.0, 'dBm')
            # new_amp_line_2 = sc.get_parameter('CalibrateLines', 'amplitude729_line2') + U(10.0, 'dBm')
            # sc.set_parameter('CalibrateLines', 'amplitude729_line1', new_amp_line_1)
            # sc.set_parameter('CalibrateLines', 'amplitude729_line2', new_amp_line_2)
            sc.set_parameter('CalibrateLines', 'amplitude729_line1', U(-31.0, 'dBm'))
            sc.set_parameter('CalibrateLines', 'amplitude729_line2', U(-29.0, 'dBm'))

            # Run another CalibAllLines
            calibration_count = 1 
            settings = [('CalibLine2', ('Excitation729.frequency729', -100.0, 100.0, 10.0, 'kHz')), 
                        ('CalibLine1', ('Excitation729.frequency729', -100.0, 100.0, 10.0, 'kHz'))]
            sc.new_sequence('Calibrations_CalibAllLines', settings, 'First in Queue')

            # Kill this sequence and store the name of the current sequence, 
            # which is different from Calibrations_CalibAllLines if Calibrations_CalibAllLines
            # is called as part of another (composite) sequence
            ID, name = sc.get_running()[-1]
            global initial_sequence
            global initial_sequence_settings
            if name != 'Calibrations_CalibAllLines':
                initial_sequence = name
                initial_sequence_settings = sc.get_current_sequence_settings()
            sc.stop_sequence(ID)

        global_sd_cxn.disconnect()


    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, freq_data):
        global calibration_count 
    
        if calibration_count == 1: 
            # Remove the first point in drift tracker 
            global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
            global_sd_cxn.sd_tracker_global.remove_line_center_measurement(0, cl.client_name) # cl.client_name = 'staq'
            #global_sd_cxn.sd_tracker_global.remove_b_measurement(0, cl.client_name) 
            global_sd_cxn.disconnect()

            # Change range of scannable parameters
            sc = cxn.scriptscanner
            sc.emit_scannable_modified(('Calibrations_CalibAllLines', 'CalibLine1', 'Excitation729.frequency729', (-7.0, 7.0, 0.7)))
            sc.emit_scannable_modified(('Calibrations_CalibAllLines', 'CalibLine2', 'Excitation729.frequency729', (-7.0, 7.0, 0.7)))

            # Change 729 power
            #new_amp_line_1 = sc.get_parameter('CalibrateLines', 'amplitude729_line1') - U(10.0, 'dBm')
            #new_amp_line_2 = sc.get_parameter('CalibrateLines', 'amplitude729_line2') - U(10.0, 'dBm')
            new_amp_line_1 =  U(-41.0, 'dBm')
            new_amp_line_2 =  U(-39.0, 'dBm')
            sc.set_parameter('CalibrateLines', 'amplitude729_line1', new_amp_line_1)
            sc.set_parameter('CalibrateLines', 'amplitude729_line2', new_amp_line_2)

            # Run other 2 calibAllLines
            calibration_count = 2 
            settings = [('CalibLine2', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz')), 
                        ('CalibLine1', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz'))]
            sc.new_sequence('Calibrations_CalibAllLines', settings, 'First in Queue')
            sc.new_sequence('Calibrations_CalibAllLines', settings, 'First in Queue')

        elif calibration_count == 2:
            calibration_count = 3

        elif calibration_count == 3: 
            #after getting 3 sets of lines, set these powers
            sc = cxn.scriptscanner
            new_amp_line_1 =  U(-44.0, 'dBm')
            new_amp_line_2 =  U(-41.0, 'dBm')
            sc.set_parameter('CalibrateLines', 'amplitude729_line1', new_amp_line_1)
            sc.set_parameter('CalibrateLines', 'amplitude729_line2', new_amp_line_2)
            # Remove the first point in drift tracker 
            global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
            global_sd_cxn.sd_tracker_global.remove_line_center_measurement(0, cl.client_name) # cl.client_name = 'staq'
            #global_sd_cxn.sd_tracker_global.remove_b_measurement(0, cl.client_name) 
            global_sd_cxn.disconnect()
            calibration_count = 0

            # If the initial sequence was't Calibrations_CalibAllLines, then launch it again
            sc = cxn.scriptscanner
            print 'initial sequence was: ', initial_sequence
            if initial_sequence != 'Calibrations_CalibAllLines' and initial_sequence != '':
                sc.new_sequence(initial_sequence, initial_sequence_settings)
        else: 
            pass

#         p_cxn=cxn.pulser
#         p_cxn.line_trigger_state(False)

