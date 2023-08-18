from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from LightShiftGate_TTL import LightShiftGate_TTL
from LightShiftGateParity_TTL import LightShiftGateParity_TTL
from labrad.units import WithUnit as U
from Calibrations import Calibrations_LightShiftGate

import numpy as np
import labrad
import sys 

# for fitting
sys.path.append('../../../../RealSimpleGrapher/analysis')
from fitting import FitWrapper


global power_offset_calibration
power_offset_calibration = True

global power_offset_middle

global flag
flag=1

class dataset:
    def __init__(self, x, y):
        N = len(x)
        self.data = np.zeros((N,2))
        self.data[:,0] = x
        self.data[:,1] = y

def findPowerCrossingPoints(x, y):
    ind=np.where(np.diff(np.sign(y[2]-y[0])))[0]
    ind=ind[0]
    x_s=x[(ind-2):(ind+3)]
    y0=y[0][(ind-2):(ind+3)]
    y2=y[2][(ind-2):(ind+3)]

    data_SS = dataset(x_s, y0)
    data_DD = dataset(x_s, y2)

    ## SS
    fit_SS = FitWrapper(data_SS, 0)
    fit_SS.setModel('Linear')
    for p in fit_SS.getParameters():
        fit_SS.getManualValue(p)
    fit_SS.doFit()

    ## DD
    fit_DD = FitWrapper(data_DD, 0)
    fit_DD.setModel('Linear')
    for p in fit_DD.getParameters():
        fit_DD.getManualValue(p)
    fit_DD.doFit()

    # Print fitted values
    for p in enumerate(fit_SS.getParameters()):
        print '{}\t{}'.format(p, fit_SS.getFittedValue(p[1]))
    for p in enumerate(fit_DD.getParameters()):
        print '{}\t{}'.format(p, fit_DD.getFittedValue(p[1]))
    # Find the crossing point
    data_SS = fit_SS.evaluateFittedParameters()
    data_DD = fit_DD.evaluateFittedParameters()
    
    idx = np.argwhere(np.diff(np.sign(data_SS[:,1] - data_DD[:,1]))).flatten()
    
    try:
        #crossing = data_SS[:,0][idx]
        x_dat=data_SS[:,0]
        
        v1=abs((data_SS[:,1] - data_DD[:,1])[idx])
        v2=abs((data_SS[:,1] - data_DD[:,1])[idx+1])
        print 'aaaaaaaaaahfherognUBFRN'
        print v1,v2
        print(x_dat[idx+1]*v1)/(v1+v2), (x_dat[idx]*v2)/(v1+v2)
        
        crossing = (x_dat[idx+1]*v1+x_dat[idx]*v2)/(v1+v2)
        print crossing 
        return crossing
    except:
        raise Exception("No crossing points found!")
        return [-100]


class LightShiftGate_GateTimeCalibration(LightShiftGate_TTL):

    scannable_params = {'LightShift.duration': [(0.124, 0.147, 0.001, 'ms'), 'population']}
    checked_params = ['LightShift.duration']
    
    fixed_params = {
        'StateReadout.readout_mode': "pmt_states",
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        'StatePreparation.sideband_cooling_enable': True,
        'StatePreparation.optical_pumping_enable': True,
        'SidebandCooling.line_selection': 'S-1/2D-5/2',
        'SidebandCooling.order': -1,
        'SidebandCooling.selection_sideband': 'axial_frequency',
        #'LightShift.UseCustomPiTimes':True,
        'LightShift.gate1':'gate1',
        'LightShift.gate2':'gate2',
        'Ramsey.echo_enable':True,
        }

    @classmethod
    def run_in_loop(cls, cxn, parameters_dict, data, x):
        super(LightShiftGate_GateTimeCalibration, cls).run_in_loop(cxn, parameters_dict, data, x)        
#         if np.transpose(data)[0][-1]<.02:
#             raise Exception('Lost Ion!')    

    @classmethod
    def run_finally(cls, cxn, parameters_dict, data, x):
        super(LightShiftGate_GateTimeCalibration, cls).run_finally(cxn, parameters_dict, data, x)        
        
        sc=cxn.scriptscanner
        detuning=sc.get_parameter('LightShift', 'gate2_detuning')
        pred_dur=2./abs(detuning['kHz'])
        if max(x)>pred_dur:
            d = np.transpose(data)
            idx = d[1].tolist().index(d[1].min())
            gate_time = U(x[idx], 'ms')

            # Save duration in the parameters' vault
            sc = cxn.scriptscanner
            sc.set_parameter('LightShift', 'duration', gate_time)
#         global flag
#         global power_offset_middle
#         if  (flag-1)%4==0:
#             power_offset_middle=sc.get_parameter('LightShift', 'power_offset')['dBm']
#         # Create a new lightShiftGate_PowerCalibration experiment to evaluate finer offset
#         settings = [('LightShiftGate_OffsetOnly', ('LightShift.power_offset', power_offset_middle-1, power_offset_middle+1, .1, 'dBm'))]
#         sc.new_sequence('LightShiftGate_OffsetOnly', settings, 'Pause All Others')


class LightShiftGate_PowerCalibration(LightShiftGate_TTL):

    scannable_params = {
        'LightShift.gate2_amplitude':[(-3, 3, .5, 'dBm'), 'power'],
        'LightShift.power_offset':[(-4, 3, .5, 'dBm'), 'power'],
        }

    fixed_params = {
        'StateReadout.readout_mode': "pmt_states",
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        'StatePreparation.sideband_cooling_enable': True,
        'StatePreparation.optical_pumping_enable': True,
        'SidebandCooling.line_selection': 'S-1/2D-5/2',
        'SidebandCooling.order': -1,
        'SidebandCooling.selection_sideband': 'axial_frequency',
        #'LightShift.gate2_amplitude':U(1,'dBm'),
        #'LightShift.UseCustomPiTimes':True,
        'LightShift.gate1':'gate1',
        'LightShift.gate2':'gate2',
        'Ramsey.echo_enable':True,
        }

    checked_params = ['LightShift.power_offset']  

    @classmethod
    def run_finally(cls, cxn, parameters_dict, data, x):
        super(LightShiftGate_PowerCalibration, cls).run_finally(cxn, parameters_dict, data, x)

        global power_offset_calibration
        if power_offset_calibration:
            # Here the power offset is calibrated
            power_offset_calibration = False

            try:
                crossing = findPowerCrossingPoints(x, np.transpose(data))
                power_offset = U(crossing[0], 'dBm')
            except:
                power_offset_calibration = True
                raise Exception("No crossing points found!")
                return
            
            # Save power offset in the parameters' vault
            sc = cxn.scriptscanner
            sc.set_parameter('LightShift', 'power_offset', power_offset)

            # Create a new lightShiftGate_PowerCalibration experiment to evaluate gate2_amplitude
            settings = [('LightShiftGate_PowerCalibration', ('LightShift.gate2_amplitude', -3, 2, .5, 'dBm'))]
            sc.new_sequence('LightShiftGate_PowerCalibration', settings, 'Pause All Others')

        else:
            # Here gate_2 amplitude is calibrated
            power_offset_calibration = True
            sc = cxn.scriptscanner
            try:
                crossing = findPowerCrossingPoints(x, np.transpose(data))
                print 'aaaaa', crossing
                power = U(crossing[0], 'dBm')
                # Save gate_2 amplitude in the parameters' vault
                sc.set_parameter('LightShift', 'gate2_amplitude', power)
            except:
                # Create a new lightShiftGate_PowerCalibration experiment to evaluate gate2_amplitude
                #d=np.transpose(data)
                #middle=x[np.argwhere(min(abs(d[0]-d[2]))==abs(d[0]-d[2]))]
                #settings = [('LightShiftGate_PowerCalibration', ('LightShift.gate2_amplitude', middle-1, middle+1, .3, 'dBm'))]
                #sc.new_sequence('LightShiftGate_PowerCalibration', settings, 'Pause All Others')
                raise Exception("No crossing points found!")
                return

class LightShiftGate_OffsetOnly(LightShiftGate_TTL):

    scannable_params = {
        'LightShift.power_offset':[(-6., 1., 0.5, 'dBm'), 'power'],
        }

    fixed_params = {
        'StateReadout.readout_mode': "pmt_states",
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        'StatePreparation.sideband_cooling_enable': True,
        'StatePreparation.optical_pumping_enable': True,
        'SidebandCooling.line_selection': 'S-1/2D-5/2',
        'SidebandCooling.order': -1,
        'SidebandCooling.selection_sideband': 'axial_frequency',
        'LightShift.gate2_amplitude':U(2,'dBm'),
        'LightShift.gate1_amplitude':U(1,'dBm'),
        #'LightShift.UseCustomPiTimes':True,
        'LightShift.gate1':'gate1',
        'LightShift.gate2':'gate2',
        'Ramsey.echo_enable':True,
        }

    checked_params = ['LightShift.power_offset']

    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        super(LightShiftGate_OffsetOnly, cls).run_initial(cxn, parameters_dict)
      
        sc=cxn.scriptscanner
        sc.set_parameter('LightShift', 'gate2_amplitude', U(2.0,'dBm'))
        sc.set_parameter('LightShift', 'gate1_amplitude', U(1.0,'dBm'))  
        sc.set_parameter('LightShift', 'gate1', 'gate1')  

        act_dur=sc.get_parameter('LightShift', 'duration')
        act_dur=act_dur['us']
      
        # Restart the sequence if displacement pulse duration is shorter than 4. 
        # In that case, the predicted value of 2/detuning is set, than another sequence is automatically triggered. 
        if act_dur<4.:
            print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 1'
            detuning=sc.get_parameter('LightShift', 'gate2_detuning')
            pred_dur=2000./abs(detuning['kHz'])
            sc.set_parameter('LightShift', 'duration', U(pred_dur,'us'))
            print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 2'

            # Run another OffsetOnly
            settings = [('LightShiftGate_OffsetOnly', ('LightShift.power_offset', -10., -2, .5, 'dBm'))]
            sc.new_sequence('LightShiftGate_OffsetOnly', settings, 'First in Queue')
            print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 3'

            # Kill this sequence
            ID, name = sc.get_running()[-1]
            sc.stop_sequence(ID)
            print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 4'

    @classmethod
    def run_finally(cls, cxn, parameters_dict, data, x):
        print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa 5'
        super(LightShiftGate_OffsetOnly, cls).run_finally(cxn, parameters_dict, data, x)

#         try:
#             crossing = findPowerCrossingPoints(x, np.transpose(data))
#             power_offset = U(crossing[0], 'dBm')
#         except:
#             power_offset_calibration = True
#             raise Exception("No crossing points found!")
#             return

#         sc=cxn.scriptscanner
#         act_dur=sc.get_parameter('LightShift', 'duration')
#         act_dur=act_dur['us']
#         if act_dur<4:
#             detuning=sc.get_parameter('LightShift', 'gate2_detuning')
#             pred_dur=2000./abs(detuning['kHz'])
#             sc.set_parameter('LightShift', 'duration', U(pred_dur,'us'))
            
#             # Run another OffsetOnly
#             settings = [('LightShiftGate_OffsetOnly', ('LightShift.power_offset', -6., -2, .5, 'dBm'))]
#             sc.new_sequence('LightShiftGate_OffsetOnly', settings, 'First in Queue')

#         else:
            
        crossing = findPowerCrossingPoints(x, np.transpose(data))
        power_offset = U(crossing[0], 'dBm')
        if crossing[0]>-100:
            # Save power offset in the parameters' vault
            sc = cxn.scriptscanner
            sc.set_parameter('LightShift', 'power_offset', power_offset)
        
#     @classmethod
#     def run_finally(cls, cxn, parameters_dict, data, x):
#         super(LightShiftGate_OffsetOnly, cls).run_finally(cxn, parameters_dict, data, x)
#         sc = cxn.scriptscanner
#         global power_offset_calibration
#         if power_offset_calibration:
#             # Here the power offset is calibrated
#             power_offset_calibration = False

#             try:
#                 crossing = findPowerCrossingPoints(x, np.transpose(data))
#                 power_offset = crossing[0] #U(crossing[0], 'dBm')
#             except:
#                 power_offset_calibration = True
#                 raise Exception("No crossing points found!")
#                 return

#             # Create a new lightShiftGate_PowerCalibration experiment to evaluate finer offset
#             settings = [('LightShiftGate_OffsetOnly', ('LightShift.power_offset', -power_offset-.5, power_offset+.5, .1, 'dBm'))]
#             sc.new_sequence('LightShiftGate_OffsetOnly', settings, 'Pause All Others')

#         else:
#             # Here finer offset amplitude is calibrated
#             power_offset_calibration = True
#             try:
#                 crossing = findPowerCrossingPoints(x, np.transpose(data))
#                 print 'aaaaa', crossing
#                 power = U(crossing[0], 'dBm')
#                 # Save offset amplitude in the parameters' vault
#                 sc.set_parameter('LightShift', 'power_offset', power)
#             except:
#                 raise Exception("No crossing points found!")
#                 return
   
      
class LightShiftGateParity_Fit(LightShiftGateParity_TTL):
    
    scannable_params = {'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'parity']}
    checked_params = ['Ramsey.second_pulse_phase']
    
    fixed_params = {
        'StateReadout.readout_mode': "pmt_parity",
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        'StatePreparation.sideband_cooling_enable': True,
        'StatePreparation.optical_pumping_enable': True,
        'SidebandCooling.line_selection': 'S-1/2D-5/2',
        'SidebandCooling.order': -1,
        'SidebandCooling.selection_sideband': 'axial_frequency',
        #'LightShift.UseCustomPiTimes':True,
        'LightShift.gate1':'gate1',
        'LightShift.gate2':'gate2',
        'Ramsey.echo_enable':True,
        }
        
    @classmethod
    def run_finally(cls, cxn, parameters_dict, data, x):
        super(LightShiftGateParity_Fit, cls).run_finally(cxn, parameters_dict, data, x)
        
        d = np.transpose(data)
        data_parity = dataset(x, d[3])

        fit_parity = FitWrapper(data_parity, 0)
        fit_parity.setModel('parity')
        for p in fit_parity.getParameters():
            fit_parity.getManualValue(p)
        fit_parity.doFit()

        for p in enumerate(fit_parity.getParameters()):
            print '{}\t{}'.format(p, fit_parity.getFittedValue(p[1]))

        contrast = abs(fit_parity.getFittedValue('contrast'))
        print 'Light shift gate parity: fitted contrast is ', contrast
        #if contrast<.5:
        #    raise Exception("Contrast too low...")
        return contrast 


class LightShiftGatePopulation(LightShiftGate_TTL):

    scannable_params = {'EmptySequence.empty_sequence_duration': [(0.0, 0.0, 1.0, 'us'), 'fidelity']}    
    checked_params = ['EmptySequence.empty_sequence_duration']

    fixed_params = {
        'StateReadout.readout_mode': "pmt_states",
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        'StatePreparation.sideband_cooling_enable': True,
        'StatePreparation.optical_pumping_enable': True,
        'SidebandCooling.line_selection': 'S-1/2D-5/2',
        'SidebandCooling.order': -1,
        'SidebandCooling.selection_sideband': 'axial_frequency',
        'StateReadout.repeat_each_measurement': 1000,
        #'LightShift.UseCustomPiTimes':True,
        'LightShift.gate1':'gate1',
        'LightShift.gate2':'gate2',
        'Ramsey.echo_enable':True,
        }

    @classmethod
    def run_finally(cls, cxn, parameters_dict, data, x):
        super(LightShiftGatePopulation, cls).run_finally(cxn, parameters_dict, data, x)

        y=np.transpose(data)
        print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa population dd + ss is ', y[0]+y[2]
        return y[0] + y[2]
    

class Fidelity_Calibrations(pulse_sequence):

    sequence = [LightShiftGate_GateTimeCalibration, LightShiftGate_OffsetOnly]

class JustFidelity(pulse_sequence):
    
    sequence = [LightShiftGatePopulation,LightShiftGateParity_Fit]
    @classmethod
    def run_finally(cls, cxn, parameter_dict, cnts, seq_name):
        print .5*(cnts[-1] + cnts[-2])
        return .5*(cnts[-1] + cnts[-2])    
    
class Fidelity(pulse_sequence):
    
    #sequence = [LightShiftGate_OffsetOnly,LightShiftGate_GateTimeCalibration,LightShiftGate_PowerCalibration,LightShiftGatePopulation,LightShiftGateParity_Fit]
    #sequence = [Calibrations_LightShiftGate,LightShiftGate_OffsetOnly,LightShiftGate_GateTimeCalibration,LightShiftGate_OffsetOnly,LightShiftGatePopulation,LightShiftGateParity_Fit]
    #sequence = [Calibrations_LightShiftGate,LightShiftGate_OffsetOnly,LightShiftGate_GateTimeCalibration,LightShiftGate_PowerCalibration,LightShiftGatePopulation,LightShiftGateParity_Fit]
    #sequence = [LightShiftGate_GateTimeCalibration, LightShiftGate_OffsetOnly, LightShiftGatePopulation, LightShiftGateParity_Fit]
    sequence = [LightShiftGate_GateTimeCalibration, LightShiftGatePopulation, LightShiftGateParity_Fit, LightShiftGateParity_Fit, LightShiftGateParity_Fit]

    @classmethod
    def run_finally(cls, cxn, parameter_dict, cnts, seq_name):
        print .5*(cnts[1] + cnts[3])
        return .5*(cnts[1] + cnts[3])
    
    
class LightShiftGateFidelity(pulse_sequence):

    scannable_params = {'EmptySequence.empty_sequence_duration': [(0.0, 10.0, 1.0, 'us'), 'fidelity']} 
    checked_params = ['EmptySequence.empty_sequence_duration']

    sequence = Fidelity 
    
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
      sc=cxn.scriptscanner

      act_dur=sc.get_parameter('LightShift', 'duration')
      act_dur=act_dur['us']
      if act_dur<4:
        detuning=sc.get_parameter('LightShift', 'gate2_detuning')
        pred_dur=2000./detuning['kHz']
        sc.set_parameter('LightShift', 'duration', U(pred_dur,'us'))

      settings = [('LightShiftGate_OffsetOnly', ('LightShift.power_offset', -7, 0, 1, 'dBm'))]
      sc.new_sequence('LightShiftGate_OffsetOnly', settings,'Pause All Others')

    @classmethod
    def run_in_loop(cls, cxn, parameters_dict, data, x):
        global flag
        if flag%4==0:
            sc=cxn.scriptscanner
            settings = [('CalibLine2', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz')), 
            ('CalibLine1', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz'))]
            sc.new_sequence('Calibrations_CalibAllLines', settings, 'Pause All Others')
            sc.new_sequence('Calibrations_CalibAllLines', settings, 'Pause All Others')
            
            settings2 = [('CalibLine2', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz')), 
            ('CalibLine1', ('Excitation729.frequency729', -7.0, 7.0, 0.7, 'kHz')),
            ('Calibrations_AxialModeFrequency',('Spectrum.sideband_detuning',-7.0, 7.0, .5, 'kHz')),
            ('SBC_BestRepumperPower',('SidebandCooling.sideband_cooling_amplitude_854', -26.0, -17.0, 1, 'dBm')),
            ('Calibrations_PiTime',('RabiFlopping.duration', 4., 10.5, .5, 'us'))]
            sc.new_sequence('Calibrations_LightShiftGate', settings2, 'Pause All Others')
            
            settings = [('LightShiftGate_OffsetOnly', ('LightShift.power_offset', -7, -2, 1, 'dBm'))]
            sc.new_sequence('LightShiftGate_OffsetOnly', settings,'Pause All Others')

        flag+=1 

#Old fitting code       
# Fit the results and find the best power offset
#data_SS = dataset(x, y[0])
#data_DD = dataset(x, y[2])

#     ## SS
#     fit_SS = FitWrapper(data_SS, 0)
#     fit_SS.setModel('LSGPower')
#     for p in fit_SS.getParameters():
#         fit_SS.getManualValue(p)
#     fit_SS.setBounds('constrast', [0, 1])
#     fit_SS.setBounds('tau', [0, 100])
#     fit_SS.doFit()

#     ## DD
#     fit_DD = FitWrapper(data_DD, 0)
#     fit_DD.setModel('LSGPower')
#     for p in fit_DD.getParameters():
#         fit_DD.getManualValue(p)
#     fit_DD.setBounds('constrast', [0, 1])
#     fit_DD.setBounds('tau', [0, 100])
#     fit_DD.doFit()


#     # ind=np.where(y[0]>y[2])[0][0]
#     # if abs(y[0][ind]-y[2][ind])>abs(y[0][ind-1]-y[2][ind-1]):
#     #     ind=ind-1

#     ind=np.where(np.diff(np.sign(y[2]-y[0])))[0]
#     indmin=ind[np.where(abs(y[0][ind]-y[2][ind]) == min(abs(y[0][ind]-y[2][ind])))[0][0]]
#     if abs(y[0][indmin]-y[2][indmin])>abs(y[0][indmin+1]-y[2][indmin+1]):
#         indmin=indmin+1
#     indfirst=ind[0]   
#     if abs(y[0][indfirst]-y[2][indfirst])>abs(y[0][indfirst+1]-y[2][indfirst+1]):
#         indfirst=indfirst+1  
#     if abs(y[0][indfirst]-y[2][indfirst])>3*abs(y[0][indmin]-y[2][indmin]):
#         ind=indmin
#     else:
#         ind=indfirst
#     print 'aaaasfdfsdgergaa', x

#     mins=[i for i in range(len(x)) if abs(y[0][i]-y[2][i])<.05 and y[1][i]<.1 and i!=0]
#     print 'mins',mins
#     if len(mins)>0:
#         mins=min(mins)
#     else:
#         mins=len(x)+1
#     print 'mins', mins
#     ind=np.where(np.diff(np.sign(y[2]-y[0])))[0]
#     print 'ind', ind
#     indmin=ind[np.where(abs(y[0][ind]-y[2][ind])==min(abs(y[0][ind]-y[2][ind])))[0][0]]
#     if abs(y[0][indmin]-y[2][indmin])>abs(y[0][indmin+1]-y[2][indmin+1]):
#         indmin=indmin+1
#     indfirst=ind[0]   
#     if abs(y[0][indfirst]-y[2][indfirst])>abs(y[0][indfirst+1]-y[2][indfirst+1]):
#         indfirst=indfirst+1  
#     if (y[0][indfirst]-y[0][indfirst-1])+.05>(y[0][indfirst+1]-y[0][indfirst])>(y[0][indfirst]-y[0][indfirst-1])-.05 and (y[2][indfirst]-y[2][indfirst-1])+.05<(y[2][indfirst+1]-y[2][indfirst])<(y[2][indfirst]-y[2][indfirst-1])-.05:
#         ind=indmin
#     else:
#         ind=indfirst
#     print 'indfirst', indfirst
#     print 'indmin', indmin
#     if mins<ind:
#         ind=mins
#         if abs(y[0][ind]-y[2][ind])>abs(y[0][ind+1]-y[2][ind+1]):
#             ind=ind+1
#     print 'ind', ind


def findPowerCrossingPoints_notused(x, y):

    #pts with diffs between SS and DD below 5% and SD+DS pop below 10%, regardless of crossing
    #as sometimes ideal pt will be close to the ideal result without an actual crossing
    #reason for thresholds and not just selecting pt that is closest to ideal is to be less
    #sensitive to fluctuations (noise alone can change the ideal power selected that way
    #substantially)
    mins=[i for i in range(len(x)) if abs(y[0][i]-y[2][i])<.05 and y[1][i]<.1 and i!=0]
    if len(mins)>0:
        #first pt that meets this condition is selected as we want to use lower powers if possible
        mins=min(mins)
    else:
        #if no such mins meet the above conditions give nonsense  value
        mins=len(x)+1
    #find every point before crossing    
    ind=np.where(np.diff(np.sign(y[2]-y[0])))[0]
    #select point before first crossing
    indfirst=ind[0] 
    #if point after first crossing has lower diff between SS and DD, set this to be the middle pt in fit
    if abs(y[0][indfirst]-y[2][indfirst])>abs(y[0][indfirst+1]-y[2][indfirst+1]):
        indfirst=indfirst+1 
    #select point before crossing with smallest SS and DD diff
    indmin=ind[np.where(abs(y[0][ind]-y[2][ind])==min(abs(y[0][ind]-y[2][ind])))[0][0]]
    #if point after this crossing has smaller SS and DD diff, set this pt to be the middle for the linear fit
    if abs(y[0][indmin]-y[2][indmin])>abs(y[0][indmin+1]-y[2][indmin+1]):
        indmin=indmin+1
        
    firstok,indminok,minsok=False,False,False
    #check that for each option a linear fit will yield reliable fit w/ potential for crossing
    #this is done by making sure initial and final pts used in fit have correct sign of slope given
    #the location of the first SS and DD pts 
    #also check that the index can be a middle pt as the fit requires a pt to the left and right of it (linear fit needs 3 pts)
    if (indfirst<len(x)-1) and ((y[0][indfirst-1]>y[2][indfirst-1] and y[0][indfirst-1]>y[0][indfirst+1] and y[2][indfirst-1]<y[2][indfirst+1]) or (y[0][indfirst-1]<y[2][indfirst-1] and y[0][indfirst-1]<y[0][indfirst+1] and y[2][indfirst-1]>y[2][indfirst+1])):
        firstok=True
        print 'a'
    if (indmin<len(x)-1) and ((y[0][indmin-1]>y[2][indmin-1] and y[0][indmin-1]>y[0][indmin+1] and y[2][indmin-1]<y[2][indmin+1]) or (y[0][indmin-1]<y[2][indmin-1] and y[0][indmin-1]<y[0][indmin+1] and y[2][indmin-1]>y[2][indmin+1])):
        indminok=True 
        print 'b'
    if mins<len(x)-1 and ((y[0][mins-1]>y[2][mins-1] and y[0][mins-1]>y[0][mins+1] and y[2][mins-1]<y[2][mins+1]) or (y[0][mins-1]<y[2][mins-1] and y[0][mins-1]<y[0][mins+1] and y[2][mins-1]>y[2][mins+1])):
        minsok=True
        print 'c'
    #if condition to make reliable linear fits hold, pick the pt associated with the first crossing
    #as long as the pt associated with the min crossing is not 3 times closer to the ideal (50%/50% SS and DD)
    #this is motivated by the fact that in that case, the linear fit resulting from the min crossing be so much 
    #more reliable than the first
    if indminok and (abs(y[0][indfirst]-y[2][indfirst])+y[1][indfirst]>3*(abs(y[0][indmin]-y[2][indmin])+y[1][indmin])): 
        print 'set b'
        ind=indmin
    elif firstok:
        print 'set a'
        ind=indfirst
    #ignore pts associated with crossings all together if the pt with the min SS and DD diff allows for a decent
    #linear fit and comes before the crossing pt selected
    if (firstok or indminok) and (mins<ind and minsok):
        print 'set c'
        ind=mins
        #again check if pt to the right closer to the ideal (aka SS and DD are close but also SD+DS is small)
        if abs(y[0][ind]-y[2][ind])>abs(y[0][ind+1]-y[2][ind+1]):
            ind=ind+1
            
    idx=[]
    #check to see if either of these three types of pts meet the conditions
    #necessary for reliable linear fits and if so do the fit and find the crossing
    if firstok or indminok or minsok:
        if abs(x[0]-x[1])<.3 and ind>1 and ind<len(x)+3:    
            xl=x[(ind-2):(ind+3)]
            y0=y[0][(ind-2):(ind+3)]
            y2=y[2][(ind-2):(ind+3)]
        else:
            xl=x[(ind-1):(ind+2)]
            y0=y[0][(ind-1):(ind+2)]
            y2=y[2][(ind-1):(ind+2)]
        data_SS = dataset(xl, y0)
        data_DD = dataset(xl, y2)

        ## SS
        fit_SS = FitWrapper(data_SS, 0)
        fit_SS.setModel('Linear')
        for p in fit_SS.getParameters():
            fit_SS.getManualValue(p)
        fit_SS.doFit()

        ## DD
        fit_DD = FitWrapper(data_DD, 0)
        fit_DD.setModel('Linear')
        for p in fit_DD.getParameters():
            fit_DD.getManualValue(p)
        fit_DD.doFit()

        # Print fitted values
        for p in enumerate(fit_SS.getParameters()):
            print '{}\t{}'.format(p, fit_SS.getFittedValue(p[1]))
        for p in enumerate(fit_DD.getParameters()):
            print '{}\t{}'.format(p, fit_DD.getFittedValue(p[1]))
        # Find the crossing point
        data_SS = fit_SS.evaluateFittedParameters()
        data_DD = fit_DD.evaluateFittedParameters()

        # find index of sign change of diff between y[0] and y[2]
        idx = np.argwhere(np.diff(np.sign(data_SS[:,1] - data_DD[:,1]))).flatten()
    print 'INFO DUMP', idx, indfirst, indmin, mins
    #if a crossing is found, set that power as ideal gate/offset power
    #otherwise set either the min crossing pt or the first close to ideal pt (regardless of crossing)
    #as the ideal, depending on which is closest to the ideal
    if len(idx)!=0:
        # plug those indices into smoothed x
        crossing = data_SS[:,0][idx]
        print 'Crossing points found: ', crossing
    else:
        if mins>len(x) or abs(y[0][mins]-y[2][mins])+y[1][mins]>abs(y[0][indmin]-y[2][indmin])+y[1][indmin]:
            crossing=x[[indmin]] 
        else:
            crossing=x[[mins]] 
        print 'No crossing, using min', crossing
    return crossing