import numpy as np
import os
import sys
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
from common.client_config import client_info as cl
from RabiFlopping import RabiFlopping
from Spectrum import Spectrum
from subsequences.EmptySequence import EmptySequence 
from scipy.special import eval_genlaguerre as laguerre
from CalibAllLines import Calibrations_CalibAllLines
from LightShiftGate_TTL import LightShiftGate_TTL

# for fitting
sys.path.append('../../../../RealSimpleGrapher/analysis')
from fitting import FitWrapper

global line_trigger_was_on
line_trigger_was_on = False

def U2toAx(x):
    z=np.array([ 41991.07151819, 788751.9357591 ])
    p = np.poly1d(z)
    return p(x)/1.e6

class dataset:
    def __init__(self, x, y):
        N = len(x)
        self.data = np.zeros((N,2))
        self.data[:,0] = x
        self.data[:,1] = y


class Calibrations_AxialModeFrequency(Spectrum):

    scannable_params = {'Spectrum.sideband_detuning' :[(-7.0, 7.0, .5, 'kHz'), 'spectrum', True]}

    checked_params = ['Spectrum.sideband_detuning'] 

    fixed_params = {
                    'Spectrum.manual_amplitude_729': U(-36,'dBm'),
                    'Spectrum.manual_excitation_time': U(500.0,'us'),
    				'Spectrum.order': -1,
                    'Spectrum.selection_sideband': 'axial_frequency',
                    'Display.relative_frequencies': True,
                    'StatePreparation.sideband_cooling_enable': False,
                    'StatePreparation.optical_pumping_enable': True,
                    'SidebandCooling.line_selection': 'S-1/2D-5/2',
                    'StateReadout.readout_mode': "pmt_excitation",
					}

    show_params= ['Spectrum.manual_amplitude_729',
                  'Spectrum.manual_excitation_time',
                  ]
    
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        super(Calibrations_AxialModeFrequency, cls).run_initial(cxn, parameters_dict)        
        
        # turn on line triggering
        p_cxn=cxn.pulser
        if p_cxn.line_trigger_state():
            global line_trigger_was_on
            line_trigger_was_on = True
        else: 
            p_cxn.line_trigger_state(True)
        
#         sc = cxn.scriptscanner
#         old_axial_freq = sc.get_parameter('TrapFrequencies', 'axial_frequency')['MHz']
        
#         dac = cxn.dac_server
#         U2_val=dac.get_multipole_values()
#         U2_val=U2_val[2][1]
#         ax_guess=U2toAx(U2_val)
        
#         if old_axial_freq-.007>ax_guess or old_axial_freq+.007<ax_guess:
#             sc.set_parameter('TrapFrequencies', 'axial_frequency', U(ax_guess,'MHz'))
            
#             # Run another AxialModeFrequency
#             settings = [('Calibrations_AxialModeFrequency', ('Spectrum.sideband_detuning', -7.0, 7.0, .5, 'kHz'))]
#             sc.new_sequence('Calibrations_AxialModeFrequency', settings, 'First in Queue')

#             # Kill this sequence
#             ID, name = sc.get_running()[-1]
#             sc.stop_sequence(ID)
        
    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, x):

        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "error with the data"
            return

        # Prepare fit class 
        ds = dataset(x, all_data)	
    	fitWrap = FitWrapper(ds, 0)
    	fitWrap.setModel('Lorentzian')
		
		# Set guessing values for the parameters
        for p in fitWrap.getParameters():
            fitWrap.getManualValue(p) 
        sc = cxn.scriptscanner
        #old_axial_freq = sc.get_parameter('TrapFrequencies', 'axial_frequency')      
        
        #fitWrap.setManualValue('center', old_axial_freq['MHz'])
        #fitWrap.setManualValue('center', 1.4)
        
        #fitWrap.setManualValue('scale', 0.0002)
        #print max(all_data), .0005*max(all_data)
        fitWrap.setManualValue('scale', .0005*max(all_data))
        

        # Fit
    	fitWrap.doFit()
    	for p in enumerate(fitWrap.getParameters()):
            print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

        center = fitWrap.getFittedValue('center')
        center = U(-1.0*center, 'MHz')
        print 'aaaaaaaaaaaaaaaaaaaaaaaaaaa center', center
        # Save pi time in the parameters' vault
        if max(all_data)>.08:
            sc.set_parameter('TrapFrequencies', 'axial_frequency', center)
        #sc.add_parameter_to_logger('axialFrequency', center)
        
        #turn off linetriggering
        p_cxn=cxn.pulser
        global line_trigger_was_on
        if line_trigger_was_on: 
            line_trigger_was_on = False
        else: 
            p_cxn.line_trigger_state(False)



class Calibrations_PiTime(RabiFlopping):
    scannable_params = {'RabiFlopping.duration': [(0., 6., .3, 'us'), 'rabi'],}
    checked_params = ['RabiFlopping.duration']
    
    fixed_params = {'RabiFlopping.line_selection': 'S-1/2D-1/2',
                    'RabiFlopping.order': 0,
                    'StatePreparation.sideband_cooling_enable': True,
                    'StatePreparation.optical_pumping_enable': True,
                    'SidebandCooling.line_selection': 'S-1/2D-5/2',
                    'SidebandCooling.order': -1,
                    'SidebandCooling.selection_sideband': 'axial_frequency',
                    }

    show_params= ['RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  ]

    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        super(Calibrations_PiTime, cls).run_initial(cxn, parameters_dict)        

        # turn on line triggering
        p_cxn=cxn.pulser
        if p_cxn.line_trigger_state():
            global line_trigger_was_on
            line_trigger_was_on = True
        else: 
            p_cxn.line_trigger_state(True)

    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, x):

        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "error with the data"
            return

        # Prepare fit class 
        ds = dataset(x, all_data)   
        fitWrap = FitWrapper(ds, 0)
        fitWrap.setModel('SinusoidSquared')
        
        # Force guess of initial parameters
        for p in fitWrap.getParameters():
            fitWrap.getManualValue(p) 

        # Fit
        fitWrap.doFit()
        for i, p in enumerate(fitWrap.getParameters()):
            print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

        freq = fitWrap.getFittedValue('freq')
        t0 = fitWrap.getFittedValue('t0')

        rf_pitime = (1/freq)/4 + t0
        rf_pi2time = rf_pitime*.5 + t0

        rf_pitime = U(rf_pitime, 'us')
        rf_pi2time = U(rf_pi2time, 'us')

        print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
        print rf_pitime, rf_pi2time

        # Save pi time in the parameters' vault
        sc = cxn.scriptscanner 
        sc.set_parameter('RabiFlopping', 'duration', rf_pitime)
        sc.set_parameter('LightShift', 'PiTimeDuration', rf_pitime)
        sc.set_parameter('LightShift', 'PiOverTwoTimeDuration', rf_pi2time)
        
        #turn off linetriggering
        p_cxn=cxn.pulser
        global line_trigger_was_on
        if line_trigger_was_on: 
            line_trigger_was_on = False
        else: 
            p_cxn.line_trigger_state(False)
        
        # Try to add the new value into logger database 
        #try: 
            #sc.add_parameter_to_logger('piTime', rf_pitime)
            #print 'Logged values so far: ', sc.get_logged_parameter_values('piTime')

        #except ValueError: 
            ## Clear logger (?)
            #return


class SBC_RedSidebandDuration(RabiFlopping):

    scannable_params = {'RabiFlopping.duration': [(0., 100.0, 5.0, 'us'), 'rabi'],}

    checked_params = ['RabiFlopping.duration']

    fixed_params = {'RabiFlopping.line_selection': 'S-1/2D-1/2',
                    'RabiFlopping.order': -1,
                    'RabiFlopping.selection_sideband': 'axial_frequency',
                    'StatePreparation.sideband_cooling_enable': False,
                    'StatePreparation.optical_pumping_enable': True,
                    'SidebandCooling.line_selection': 'S-1/2D-5/2',
                    }

    show_params= ['RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  ]

    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, x):

        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "error with the data"
            return

        #index = np.argmax(all_data)
        #redSidebandDuration = .75 * x[index] 
        index=0
        while index<len(x) and all_data[index]<.8*max(all_data):
            redSidebandDuration=x[index]
            index+=1
        redSidebandDuration = U(redSidebandDuration, 'us')

        # Open labrad connection to Script Scanner
        sc = cxn.scriptscanner 

        # Save in the parameters' vault
        sc.set_parameter('RabiFlopping', 'duration', redSidebandDuration)
        #sc.add_parameter_to_logger('redSidebandDuration', redSidebandDuration)


class SBC_BestRepumperPower(RabiFlopping):

    scannable_params = {'SidebandCooling.sideband_cooling_amplitude_854': [(-25.0, -13.0, 1, 'dBm'), 'rabi'],}

    checked_params = ['SidebandCooling.sideband_cooling_amplitude_854']

    fixed_params = {'RabiFlopping.line_selection': 'S-1/2D-1/2',
    				'RabiFlopping.order': -1,
                    'RabiFlopping.selection_sideband': 'axial_frequency',
                    'StatePreparation.sideband_cooling_enable': True,
                    'StatePreparation.optical_pumping_enable': True,
                    'SidebandCooling.line_selection': 'S-1/2D-5/2',
                    'SidebandCooling.order': -1,
                    'SidebandCooling.selection_sideband': 'axial_frequency',
                    #'RabiFlopping.duration':U(20,'us'),
					}

    show_params= ['RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  ]
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        super(SBC_BestRepumperPower, cls).run_initial(cxn, parameters_dict)        
        
        # turn on line triggering
        p_cxn=cxn.pulser
        if p_cxn.line_trigger_state():
            global line_trigger_was_on
            line_trigger_was_on = True
        else: 
            p_cxn.line_trigger_state(True)

    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, x):
    	pass
        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "error with the data"
            return

        ds = dataset(x, all_data)
        if min(all_data)>.2:
            raise ValueError('Sideband cooling is NOT working!')
    	fitWrap = FitWrapper(ds, 0)
    	fitWrap.setModel('Gaussian')
		
		# Force guess of initial parameters
        for p in fitWrap.getParameters():
            fitWrap.getManualValue(p) 

        # Fit
     	fitWrap.doFit()

     	for i, p in enumerate(fitWrap.getParameters()):
            print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

        power854 = fitWrap.getFittedValue('mean')
        power854 = U(power854, 'dBm')
        print 'power854   ', power854

        # Save pi time in the parameters' vault
        sc = cxn.scriptscanner 
        sc.set_parameter('SidebandCooling', 'sideband_cooling_amplitude_854', power854)

        #sc.add_parameter_to_logger('amplitude854', power854)
        #turn off linetriggering
        p_cxn=cxn.pulser
        global line_trigger_was_on
        if line_trigger_was_on: 
            line_trigger_was_on = False
        else: 
            p_cxn.line_trigger_state(False)


class Calibrations_SidebandCooling(pulse_sequence):
    
    sequence = [SBC_RedSidebandDuration, SBC_BestRepumperPower]


class OP_BestRepumperPower(RabiFlopping):

    scannable_params = {'OpticalPumping.optical_pumping_amplitude_854': [(-28.0, -10.0, 1, 'dBm'), 'rabi'],}

    checked_params = ['OpticalPumping.optical_pumping_amplitude_854']

    fixed_params = {'RabiFlopping.line_selection': 'S+1/2D+1/2',
    				'RabiFlopping.order': 0,
                    'StatePreparation.sideband_cooling_enable': False,
                    'StatePreparation.optical_pumping_enable': True,
					}

    show_params= ['RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  ]

    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, x):
    	pass
        try:
            all_data = all_data.sum(1)
        except ValueError:
            print "error with the data"
            return

  #       ds = dataset(x, all_data)
  #   	fitWrap = FitWrapper(ds, 0)
  #   	fitWrap.setModel('Gaussian')
		
		# # Force guess of initial parameters
  #       for p in fitWrap.getParameters():
  #           fitWrap.getManualValue(p) 

  #       # Fit
  #    	fitWrap.doFit()

  #    	for i, p in enumerate(fitWrap.getParameters()):
  #           print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

  #       power854 = fitWrap.getFittedValue('mean')

        mins=[i for i in range(len(all_data)) if all_data[i]<=min(all_data)]
        if len(mins)>3:
            power854=x[mins[2]]
        elif len(mins)==1:
            power854=x[mins[0]]
        else:
            power854=x[mins[1]]
        power854 = U(power854, 'dBm')
        print 'power854   ', power854

        # Save pi time in the parameters' vault
        sc = cxn.scriptscanner 
        sc.set_parameter('OpticalPumping', 'optical_pumping_amplitude_854', power854)
        #sc.add_parameter_to_logger('amplitude854', power854) #need a diff name ow conflicts w/ SBC


class Calibrations_OpticalPumping(pulse_sequence):
    
    sequence = [(Calibrations_PiTime, {'RabiFlopping.line_selection': 'S-1/2D-1/2','StatePreparation.sideband_cooling_enable': False,'StatePreparation.optical_pumping_enable': False}), (OP_BestRepumperPower, {})]
    
class Calibrations_LightShiftGate(pulse_sequence):
    
    #sequence = [Calibrations_CalibAllLines, Calibrations_AxialModeFrequency, Calibrations_SidebandCooling, Calibrations_PiTime]    
     #sequence = [Calibrations_CalibAllLines, Calibrations_AxialModeFrequency, SBC_BestRepumperPower, Calibrations_PiTime, Calibrations_PiOverTwoTime]    
    #sequence = [Calibrations_CalibAllLines, Calibrations_AxialModeFrequency, SBC_BestRepumperPower, Calibrations_PiTime]  
    #sequence = [Calibrations_CalibAllLines, Calibrations_AxialModeFrequency, SBC_BestRepumperPower, Calibrations_PiFullSequence]
    sequence = [Calibrations_CalibAllLines, Calibrations_AxialModeFrequency, Calibrations_SidebandCooling, Calibrations_PiTime]  
    @classmethod
    def run_finally(cls, cxn, parameter_dict, cnts, seq_name):
        sc=cxn.scriptscanner
        sc.set_parameter('LightShift', 'gate2_amplitude', U(1.0,'dBm'))
        sc.set_parameter('LightShift', 'gate1_amplitude', U(1.0,'dBm'))  
        sc.set_parameter('LightShift', 'gate1', 'gate1')  
     
        act_dur=sc.get_parameter('LightShift', 'duration')
        act_dur=act_dur['us']  
        detuning=sc.get_parameter('LightShift', 'gate2_detuning')
        pred_dur=2000./abs(detuning['kHz'])
        sc.set_parameter('LightShift', 'duration', U(pred_dur,'us'))
    

# class Calibrations_PiTime_Old(RabiFlopping):

#     scannable_params = {'RabiFlopping.duration': [(0., 7., .5, 'us'), 'rabi'],}
#     #scannable_params = {'RabiFlopping.duration': [(.2, 75., 5., 'us'), 'rabi'],}

#     checked_params = ['RabiFlopping.duration']
    
#     fixed_params = {'RabiFlopping.line_selection': 'S-1/2D-1/2',
#                     'RabiFlopping.order': 0,
#                     'StatePreparation.sideband_cooling_enable': True,
#                     'StatePreparation.optical_pumping_enable': True,
#                     'SidebandCooling.line_selection': 'S-1/2D-5/2',
#                     'SidebandCooling.order': -1,
#                     'SidebandCooling.selection_sideband': 'axial_frequency',
#                     }

#     show_params= ['RabiFlopping.rabi_amplitude_729',
#                   'RabiFlopping.duration',
#                   ]

#     @classmethod
#     def run_initial(cls, cxn, parameters_dict):
#         super(Calibrations_PiTime, cls).run_initial(cxn, parameters_dict)        

#         # turn on line triggering
#         p_cxn=cxn.pulser
#         if p_cxn.line_trigger_state():
#             global line_trigger_was_on
#             line_trigger_was_on = True
#         else: 
#             p_cxn.line_trigger_state(True)

#     @classmethod
#     def run_finally(cls, cxn, parameters_dict, all_data, x):

#         try:
#             all_data = all_data.sum(1)
#         except ValueError:
#             print "error with the data"
#             return

#         # Prepare fit class 
#         ds = dataset(x[8:-1], all_data[8:-1])   
#         fitWrap = FitWrapper(ds, 0)
#         fitWrap.setModel('Rabi')
        
#         # Force guess of initial parameters
#         for p in fitWrap.getParameters():
#             fitWrap.getManualValue(p) 

#         # Fit
#         fitWrap.doFit()
#         for i, p in enumerate(fitWrap.getParameters()):
#             print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

#         fit_val=fitWrap.evaluateFittedParameters()#a=-1)
#         fit_val=np.transpose(fit_val)
#         smooth_x=fit_val[0]
#         smooth_y=fit_val[1]
#         rf_pitime=smooth_x[np.where(max(smooth_y)==smooth_y)][0]
#         # half=max(smooth_y)/2.

#         ds2 = dataset(x[0:8], all_data[0:8])   
#         fitWrap2 = FitWrapper(ds2, 0)
#         fitWrap2.setModel('Rabi')
        
#         # Force guess of initial parameters
#         for p in fitWrap2.getParameters():
#             fitWrap2.getManualValue(p) 

#         # Fit
#         fitWrap2.doFit()
#         for i, p in enumerate(fitWrap2.getParameters()):
#             print '{}\t{}'.format(p, fitWrap2.getFittedValue(p))

#         fit_val2=fitWrap2.evaluateFittedParameters()#a=-1)
#         fit_val2=np.transpose(fit_val2)
#         smooth_x2=fit_val2[0]
#         smooth_y2=fit_val2[1]
#         rf_pi2time=[smooth_x2[i] for i in range(len(smooth_x2)) if smooth_x2[i]<rf_pitime and smooth_y2[i]<.5][-1]
#         #rf_pi2time=rf_pitime/2
#         #omega=omega_0*np.exp(-.07**2./2.)*laguerre(nbar,0.,.07**2.)

#         #rf_pitime = (np.pi/omega)
        
#         rf_pitime = U(rf_pitime, 'us')
#         rf_pi2time = U(rf_pi2time, 'us')

#         # Save pi time in the parameters' vault
#         sc = cxn.scriptscanner 
#         sc.set_parameter('RabiFlopping', 'duration', rf_pitime)
#         sc.set_parameter('LightShift', 'PiTimeDuration', rf_pitime)
#         sc.set_parameter('LightShift', 'PiOverTwoTimeDuration', rf_pi2time)
        
#         #turn off linetriggering
#         p_cxn=cxn.pulser
#         global line_trigger_was_on
#         if line_trigger_was_on: 
#             line_trigger_was_on = False
#         else: 
#             p_cxn.line_trigger_state(False)
        
#         # Try to add the new value into logger database 
#         #try: 
#             #sc.add_parameter_to_logger('piTime', rf_pitime)
#             #print 'Logged values so far: ', sc.get_logged_parameter_values('piTime')

#         #except ValueError: 
#             ## Clear logger (?)
#             #return

# class Calibrations_PiFullSequence(LightShiftGate_TTL):

#     scannable_params = {'RabiFlopping.duration': [(4., 12, .5, 'us'), 'rabi'],}

#     checked_params = ['RabiFlopping.duration']
    
#     fixed_params = {'RabiFlopping.line_selection': 'S-1/2D-1/2',
#                     'RabiFlopping.order': 0,
#                     'StatePreparation.sideband_cooling_enable': True,
#                     'StatePreparation.optical_pumping_enable': True,
#                     'SidebandCooling.line_selection': 'S-1/2D-5/2',
#                     'SidebandCooling.order': -1,
#                     'SidebandCooling.selection_sideband': 'axial_frequency',
#                     'LightShift.gate1_amplitude':U(-63,'dBm'),
#                     'LightShift.gate2_amplitude':U(-63,'dBm'),
#                     'LightShift.power_offset': U(0,'dBm'),
#                     'LightShift.UseCustomPiTimes': False,
#                     }

#     @classmethod
#     def run_finally(cls, cxn, parameters_dict, data, x):
#         super(Calibrations_PiFullSequence, cls).run_finally(cxn, parameters_dict, data, x)
#         try:
#             all_data = data.sum(1)
#         except ValueError:
#             print "error with the data"
#             return

#         ds = dataset(x, all_data)
#         fitWrap = FitWrapper(ds, 0)
#         fitWrap.setModel('Gaussian')

#         # Force guess of initial parameters
#         for p in fitWrap.getParameters():
#             fitWrap.getManualValue(p) 

#         # Fit
#         fitWrap.doFit()

#         for i, p in enumerate(fitWrap.getParameters()):
#             print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

#         pitime = fitWrap.getFittedValue('mean')
#         pitime = U(pitime, 'us')
#         print 'pitime   ', pitime

#         # Save duration in the parameters' vault
#         sc = cxn.scriptscanner
#         sc.set_parameter('RabiFlopping', 'duration', pitime)         
            
            
# class Calibrations_PiOverTwoTime(LightShiftGate_TTL):

#     scannable_params = {'LightShift.PiOverTwoTimeDuration': [(2.5, 6., .3, 'us'), 'rabi'],}
    
#     checked_params = ['LightShift.PiOverTwoTimeDuration']
    
#     fixed_params = {'RabiFlopping.line_selection': 'S-1/2D-1/2',
#                     'RabiFlopping.order': 0,
#                     'StatePreparation.sideband_cooling_enable': True,
#                     'StatePreparation.optical_pumping_enable': True,
#                     'SidebandCooling.line_selection': 'S-1/2D-5/2',
#                     'SidebandCooling.order': -1,
#                     'SidebandCooling.selection_sideband': 'axial_frequency',
#                     'LightShift.gate1_amplitude':U(-63,'dBm'),
#                     'LightShift.gate2_amplitude':U(-63,'dBm'),
#                     'LightShift.power_offset': U(0,'dBm'),
#                     'LightShift.UseCustomPiTimes': True,
#                     }

#     @classmethod
#     def run_finally(cls, cxn, parameters_dict, data, x):
#         super(Calibrations_PiOverTwoTime, cls).run_finally(cxn, parameters_dict, data, x)
#         try:
#             all_data = data.sum(1)
#         except ValueError:
#             print "error with the data"
#             return

#         ds = dataset(x, all_data)
#         fitWrap = FitWrapper(ds, 0)
#         fitWrap.setModel('Gaussian')

#         # Force guess of initial parameters
#         for p in fitWrap.getParameters():
#             fitWrap.getManualValue(p) 

#         # Fit
#         fitWrap.doFit()

#         for i, p in enumerate(fitWrap.getParameters()):
#             print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

#         pi2time = fitWrap.getFittedValue('mean')
#         pi2time = U(pi2time, 'us')
#         print 'pi2time   ', pi2time

#         # Save gate_2 amplitude in the parameters' vault
#         sc = cxn.scriptscanner
#         sc.set_parameter('LightShift', 'PiOverTwoTimeDuration', pi2time)