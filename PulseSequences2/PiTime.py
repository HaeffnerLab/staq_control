import numpy as np
import os
import sys
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
from common.client_config import client_info as cl
from RabiFlopping import RabiFlopping
from Spectrum import Spectrum

# for fitting
sys.path.append('../../../../RealSimpleGrapher/analysis')
from fitting import FitWrapper
from fit_rabi import Rabi
from model import Model 
#print (os.getcwd())
#os.chdir('../../../../RealSimpleGrapher/analysis')
#print (os.getcwd())

#files = [f for f in os.listdir('.') if os.path.isfile(f)]
#for f in files:
#	print (f)


class dataset:
    def __init__(self, x, y):
        N = len(x)
        self.data = np.zeros((N,2))
        self.data[:,0] = x
        self.data[:,1] = y


class AxialMode(Spectrum):

    scannable_params = {'Spectrum.sideband_detuning' :[(-10, 10, 1, 'kHz'), 'spectrum', True]}

    fixed_params = {
                    'Display.relative_frequencies': True,
                    'StatePreparation.sideband_cooling_enable': False,
                    'StateReadout.readout_mode': "pmt_excitation",}

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
		
		# Force guess of initial parameters
        for p in fitWrap.getParameters():
            fitWrap.getManualValue(p) 

        # Fit
    	fitWrap.doFit()
    	for i, p in enumerate(fitWrap.getParameters()):
            print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

        center = fitWrap.getFittedValue('center')
        rf_pitime = U(center, 'MHz')

        # Save pi time in the parameters' vault
        import labrad
        p_cxn = labrad.connect()
        sc = p_cxn.scriptscanner 
        sc.set_parameter('TrapFrequencies', 'axial_frequency', center)
        p_cxn.disconnect()



class PiTime(RabiFlopping):

    scannable_params = {'RabiFlopping.duration': [(0., 50., 2, 'us'), 'rabi'],}

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
    	fitWrap.setModel('Rabi')
		
		# Force guess of initial parameters
        for p in fitWrap.getParameters():
            fitWrap.getManualValue(p) 

        # Fit
    	fitWrap.doFit()
    	for i, p in enumerate(fitWrap.getParameters()):
            print '{}\t{}'.format(p, fitWrap.getFittedValue(p))

        rf_pitime = (np.pi/omega)
        rf_pitime = U(rf_pitime, 'us')

        # Save pi time in the parameters' vault
        import labrad
        #duration = parameters_dict.rabi.duration
        #submission = [(duration, rf_pitime)]
        p_cxn = labrad.connect()
        sc = p_cxn.scriptscanner 
        sc.set_parameter('RabiFlopping', 'duration', rf_pitime)
        p_cxn.disconnect()



class Calibrations(pulse_sequence):
    is_composite = True

    #fixed_params = {
    #                'Display.relative_frequencies': False,
    #                # 'StatePreparation.sideband_cooling_enable': False,
    #                'StateReadout.readout_mode': "pmt_excitation"}
                    
    sequence = [AxialMode, PiTime] 

    show_params= ['DriftTracker.line_selection_1',
                'DriftTracker.line_selection_2',
                'CalibrateLines.amplitude729_line1',
                'CalibrateLines.amplitude729_line2',
                'CalibrateLines.channel_729',
                'CalibrateLines.duration729'
                  ]