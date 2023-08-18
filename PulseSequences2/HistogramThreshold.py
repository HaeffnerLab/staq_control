import numpy as np
import os
import sys
import labrad
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
from common.client_config import client_info as cl
from RabiFlopping import RabiFlopping
from subsequences.EmptySequence import EmptySequence
from CalibAllLines import Calibrations_CalibAllLines
import scipy.signal as sig
from scipy.stats import poisson

global firstRun 
firstRun = True

def pmtCountsFromExperiment(exp_name,cxn):
    # Retrieve data from data vault
    
    dv = cxn.data_vault 
    dv.cd(['Experiments'])
    date = max(dv.dir()[0])
    
    dv.cd([date, exp_name])
    time = max(dv.dir()[0])
  
    dv.cd([time])
    dv.open(2)
    pmt_ctns = dv.get()

    pmt_ctns = np.transpose(pmt_ctns)[1]
    return [int(i) for i in pmt_ctns]


class GetHist(pulse_sequence):

    scannable_params = {'RabiFlopping.duration': [(500., 500., 1., 'us'), 'current'],}

    fixed_params = {'RabiFlopping.order': 0,
                    'StatePreparation.sideband_cooling_enable': False,
                    'StatePreparation.optical_pumping_enable': False, 
                    'StateReadout.repeat_each_measurement': 500.,
                    'RabiFlopping.line_selection': 'S-1/2D-1/2',}
    
    show_params= ['RabiFlopping.rabi_amplitude_729']
    checked_params = ['RabiFlopping.duration']
    
    def sequence(self):
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
        from StatePreparation import StatePreparation
        from subsequences.RabiExcitation import RabiExcitation

        # building the sequence
        self.end = U(10., 'us')
        self.addSequence(TurnOffAll)
        self.addSequence(StatePreparation)
        
        global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
        if len(dict(global_sd_cxn.sd_tracker_global.get_line_center_global())[cl.client_name]) != 0:                        
            # calculate the scan params
            rf = self.parameters.RabiFlopping 
            freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
            
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                             'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                             'Excitation_729.rabi_excitation_duration':  rf.duration })
        self.addSequence(StateReadout) 

class Calibrations_SetHistThreshold(pulse_sequence):

    sequence = [GetHist]
    
    @classmethod
    def run_finally(cls, cxn, parameters_dict, all_data, x):
  
        data = pmtCountsFromExperiment('GetHist',cxn)
        # Create bins and histogram

        #previously this, now counts are much lower :/ maybe 397 power
        #aa=int(max(data)/5)

        aa=int(max(data)/2.5)
        heights,bins=np.histogram(data,bins=aa)
        #set threshold to ignore short bins
        
        #previously this, now counts are much lower :/ maybe 397 power
        #count_threshold=max(heights)/10
        
        count_threshold=max(heights)/20
        idx = np.where((heights!=0) & (heights>count_threshold))[0]
        a,b=np.split(heights[idx],np.where(np.diff(idx)!=1)[0]+1),np.split(bins[idx],np.where(np.diff(idx)!=1)[0]+1)
        shift=(bins[1]-bins[0])/2.
        # Pick out peaks to assign poissonians 
        lamd,stds,scales=[],[],[]
        for i in range(len(a)):
            lamd.append(np.mean(b[i]))
            x_plot = np.arange(0, max(bins) + 1)
            scales.append(max(a[i])/max(poisson.pmf(x_plot, lamd[i])))
            std_r=np.std([xi for xi in x_plot if (scales[i]*poisson.pmf(xi, lamd[i])>1 and xi>lamd[i])])
            std_l=np.std([xi for xi in x_plot if (scales[i]*poisson.pmf(xi, lamd[i])>1 and xi<lamd[i])])
            stds.append(2*max([std_r,std_l]))
            
        #ignore minor peaks    
        iz=[]
        for i in range(len(lamd)):
            if max(scales[i]*poisson.pmf(x_plot, lamd[i]))>10:
                iz.append(i)
                
        lamd,stds,scales=[lamd[i] for i in iz],[stds[i] for i in iz],[scales[i] for i in iz]

        #get thresholds
        tline=[]
        for i in range(len(lamd)):
            if i>0 and stds[i-1]>0:
                tline.append((lamd[i]-1.5*stds[i]+lamd[i-1]+1.5*stds[i-1])/2)
            elif i>0:
                tline.append((lamd[i]-1.5*stds[i]+lamd[i-1])/2)
            else:
                tline.append((lamd[i]-1.5*stds[i])/2)
        
        # don't add threshold to the left of the dark peak
        tline=[ti for ti in tline if ti>10]
        
        #Check if there is full separation between Poisson Dists
        nonzero=[]
        for i in range(len(lamd)):
            nonzero=np.append(nonzero,np.where(scales[i]*poisson.pmf(x_plot, lamd[i])>1)[0])
        if not len(np.unique(nonzero))==len(nonzero):
            raise ValueError('Histogram Peak Overlap!') #397 or count threshold issue

        #group data into sections
        if len(lamd)!=1:
            sections=np.array(-1)
            sections=np.append(sections,tline)
            sections=np.append(sections,100000)
        #if only a single section
        else:
            sections=np.array([-1,100000])
            #check if dark or bright peak, should be dark, but if unlucky maybe Rabi duration leads to pi pulse
            if min(data)*.8>10:
                tline= [min(data)*.8]
            else:
                tline= [max(data)*1.2]
        err=-1
        for i in range(1,len(sections)):
            xs=bins[np.where((bins>sections[i-1])&(bins<sections[i])&(bins<max(bins)))]
            #sometimes dark peak is too low
            try:
                theory_sect=scales[i-1]*poisson.pmf([int(xx+shift) for xx in xs], lamd[i-1])

                data_sect=heights[np.where((bins>sections[i-1])&(bins<sections[i])&(bins<max(bins)))]
                err+=sum((data_sect-theory_sect)**2)
            except:
                err=err

        red_err=err/len(lamd)
        print 'Reduced Error', red_err
        #Check if full data matches the distributions predicted above
        #condition is less strict if there are no lines
        global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
        if red_err>5000 and len(dict(global_sd_cxn.sd_tracker_global.get_line_center_global())[cl.client_name]) != 0:
            raise ValueError('Histogram is NOT Poissonian, check 397 or redo Doppler Parameters!')

        print 'threshold list', tline
        
        sc = cxn.scriptscanner
        sc.set_parameter('StateReadout', 'threshold_list', str(tline)[1:-1])      
        
        global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
        if len(dict(global_sd_cxn.sd_tracker_global.get_line_center_global())[cl.client_name]) == 0:
            
            #Run CalibAllLines then SetThresholdMulti
            settings = [('CalibLine2', ('Excitation729.frequency729', -100.0, 100.0, 10.0, 'kHz')), 
            ('CalibLine1', ('Excitation729.frequency729', -100.0, 100.0, 10.0, 'kHz'))]
            settings2 = [('GetHist', ('RabiFlopping.duration', 100., 100., 1., 'us'))]
            
            sc.new_sequence('Calibrations_CalibAllLines', settings)
            sc.new_sequence('Calibrations_SetHistThreshold',settings2)

# class Calibrations_HistogramThreshold(RabiFlopping):

#     scannable_params = {'RabiFlopping.duration': [(100., 100., 2, 'us'), 'rabi'],}

#     fixed_params = {
#                     'RabiFlopping.order': 0,
#                     'StatePreparation.sideband_cooling_enable': False,
#                     'StatePreparation.optical_pumping_enable': False,
#                     }

#     show_params= ['RabiFlopping.rabi_amplitude_729']

#     checked_params = ['RabiFlopping.duration']

#     @classmethod
#     def run_initial(cls, cxn, parameters_dict):

#         # Check if there are lines saved in the drift tracker 
#         global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
#         if len(dict(global_sd_cxn.sd_tracker_global.get_line_center_global())[cl.client_name]) == 0:

#             #Run Run SetThresholdSingle then CalibAllLines

#             sc = cxn.scriptscanner
#             sc.new_sequence('SetThresholdSingle',[])
#             sc.new_sequence('Calibrations_CalibAllLines',[])

#             ## Retrieve last position of lines 
#             #val_1 = parameters_dict.CalibrateLines.line_1_old_value 
#             #val_2 = parameters_dict.CalibrateLines.line_2_old_value 
#             #line_1 = parameters_dict.DriftTracker.line_selection_1
#             #line_2 = parameters_dict.DriftTracker.line_selection_2

#             ## Save last line position in drift tracker 
#             #submission = [(line_1, val_1), (line_2, val_2)]
#             #global_sd_cxn.sd_tracker_global.set_measurements(submission, cl.client_name) 

#             # Run another Calibrations_HistogramThreshold
#             settings = [('Calibrations_HistogramThreshold', ('RabiFlopping.duration', 98.0, 100.0, 2.0, 'us'))] 
#             sc.new_sequence('Calibrations_HistogramThreshold', settings)

#             # Kill this sequence 
#             ID, name = sc.get_running()[0]
#             sc.stop_sequence(ID)

#         global_sd_cxn.disconnect()

#         global firstRun
#         if firstRun:
#             print('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa very first run!!!')
#             firstRun = False

#             # Run another Calibrations_HistogramThreshold
#             sc = cxn.scriptscanner
#             settings = [('Calibrations_HistogramThreshold', ('RabiFlopping.duration', 98.0, 100.0, 2.0, 'us'))] 
#             sc.new_sequence('Calibrations_HistogramThreshold', settings)

#         else:
#             print('aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa running else here')
#             # Retrieve data from data vault
#             data = pmtCountsFromExperiment('Calibrations_HistogramThreshold',cxn)
#             # Create bins and histogram
#             aa=int(max(data)/5)
#             heights,bins=np.histogram(data,bins=aa)
#             #set threshold to ignore short bins
#             count_threshold=max(heights)/10
#             idx = np.where((heights!=0) & (heights>count_threshold))[0]
#             a,b=np.split(heights[idx],np.where(np.diff(idx)!=1)[0]+1),np.split(bins[idx],np.where(np.diff(idx)!=1)[0]+1)
#             shift=(bins[1]-bins[0])/2.
#             # Pick out peaks to assign poissonians 
#             lamd,stds,scales=[],[],[]
#             for i in range(len(a)):
#                 lamd.append(np.mean(b[i]))
#                 x_plot = np.arange(0, max(bins) + 1)
#                 scales.append(max(a[i])/max(poisson.pmf(x_plot, lamd[i])))
#                 stds.append(np.std(scales[i]*poisson.pmf(x_plot, lamd[i])))

#             #ignore minor peaks    
#             iz=[]
#             for i in range(len(lamd)):
#                 if max(scales[i]*poisson.pmf(x_plot, lamd[i]))>10:
#                     iz.append(i)

#             lamd,stds,scales=[lamd[i] for i in iz],[stds[i] for i in iz],[scales[i] for i in iz]

#             #get thresholds
#             tline=[]
#             for i in range(len(lamd)):
#                 if i>0:
#                     tline.append((lamd[i]-stds[i]+lamd[i-1]+stds[i-1])/2)
#                 else:
#                     tline.append(lamd[i]-stds[i])

#             # don't add threshold to the left of the dark peak
#             tline=[ti for ti in tline if ti>10]

#             #Check if there is full separation between Poisson Dists
#             nonzero=[]
#             for i in range(len(lamd)):
#                 nonzero=np.append(nonzero,np.where(scales[i]*poisson.pmf(x_plot, lamd[i])>1)[0])
#             if not len(np.unique(nonzero))==len(nonzero):
#                 raise ValueError('Histogram Peak Overlap!') #397 or count threshold issue

#             #group data into sections
#             if len(lamd)!=1:
#                 sections=np.array(-1)
#                 sections=np.append(sections,tline)
#                 sections=np.append(sections,100000)
#             #if only a single section
#             else:
#                 sections=np.array([-1,100000])
#                 #check if dark or bright peak, should be dark, but if unlucky maybe Rabi duration leads to pi pulse
#                 if min(data)*.8>10:
#                     tline= [min(data)*.8]
#                 else:
#                     tline= [max(data)*1.2]
#             err=-1
#             for i in range(1,len(sections)):
#                 xs=bins[np.where((bins>sections[i-1])&(bins<sections[i])&(bins<max(bins)))]
#                 theory_sect=scales[i-1]*poisson.pmf([int(xx+shift) for xx in xs], lamd[i-1])

#                 data_sect=heights[np.where((bins>sections[i-1])&(bins<sections[i])&(bins<max(bins)))]
#                 err+=sum(abs(data_sect-theory_sect))

#             red_err=err/len(lamd)
#             print 'Reduced Error', red_err
#             #Check if full data matches the distributions predicted above
#             if red_err>200:
#                 raise ValueError('Histogram is NOT Poissonian, check 397 or redo Doppler Parameters!')

#             print 'threshold list', tline
            
#             # update threshold list in parameter vault 
#             sc = cxn.scriptscanner
#             sc.set_parameter('StateReadout', 'threshold_list', str(tline)[1:-1])        

#             # reset first run parameter
#             firstRun = True

#             # Kill this sequence 
#             sc = cxn.scriptscanner
#             ID, name = sc.get_running()[0]
#             sc.stop_sequence(ID)

#     @classmethod
#     def run_finally(cls, cxn, parameters_dict, all_data, x):

#         global firstRun
#         if firstRun: 
#             firstRun = False


# class SingleIon(pulse_sequence):

#     scannable_params = {'Heating.background_heating_time':  [(0., 0., 1., 'us'), 'current']}

#     fixed_params = {'StatePreparation.sideband_cooling_enable': False,
#                     'StatePreparation.optical_pumping_enable': False }
    
#     checked_params = ['Heating.background_heating_time']
    
#     def sequence(self):
#         from subsequences.StateReadout import StateReadout
#         from subsequences.TurnOffAll import TurnOffAll
#         from StatePreparation import StatePreparation

#         # building the sequence
#         self.end = U(10., 'us')
#         self.addSequence(TurnOffAll)
#         self.addSequence(StatePreparation)
#         self.addSequence(StateReadout)


# class SetThresholdSingle(pulse_sequence):

#     sequence = [SingleIon]
    
#     @classmethod
#     def run_finally(cls, cxn, parameters_dict, all_data, x):
#         pmt_ctns = pmtCountsFromExperiment('SingleIon',cxn)
# #         dv = cxn.data_vault
# #         dv.cd(['','Experiments'])
# #         date = max(dv.dir()[0])

# #         dv.cd([date, 'SingleIon'])
# #         time = max(dv.dir()[0])
# #         dv.cd([time])
# #         dv.open(2)
# #         pmt_ctns = dv.get()
# #         pmt_ctns = np.transpose(pmt_ctns)[1]

# #         pmt_ctns = [int(i) for i in pmt_ctns]
#         sc = cxn.scriptscanner
#         sc.set_parameter('StateReadout', 'threshold_list', min(pmt_ctns)*.8) 
#         print  'threshold', min(pmt_ctns)*.8

# class MultiIon(RabiFlopping):
#     scannable_params = {'RabiFlopping.duration': [(100., 100., 1., 'us'), 'rabi'],}

#     fixed_params = {
#                     'RabiFlopping.order': 0,
#                     'StatePreparation.sideband_cooling_enable': False,
#                     'StatePreparation.optical_pumping_enable': False,
#                     'StateReadout.repeat_each_measurement': 500.,
#                     }

#     show_params= ['RabiFlopping.rabi_amplitude_729']
          
    
#class SetHistThresholdMulti(pulse_sequence):

            
        
# class SetHistThreshold(pulse_sequence):

#     sequence = [SetHistThresholdMulti]
    
#     @classmethod
#     def run_initial(cls, cxn, parameters_dict):

#         # Check if there are lines saved in the drift tracker 
#         global_sd_cxn = labrad.connect(cl.global_address, password = cl.global_password, tls_mode='off')
#         if len(dict(global_sd_cxn.sd_tracker_global.get_line_center_global())[cl.client_name]) == 0:

#             #Run Run SetThresholdSingle then CalibAllLines

#             sc = cxn.scriptscanner
#             settings = [('GetHist', ('RabiFlopping.duration', 100., 100., 1., 'us'))]
#             sc.new_sequence('SetHistThreshold',settings)
#             settings = [('CalibLine2', ('Excitation729.frequency729', -100.0, 100.0, 10.0, 'kHz')), 
#                         ('CalibLine1', ('Excitation729.frequency729', -100.0, 100.0, 10.0, 'kHz'))]
#             sc.new_sequence('Calibrations_CalibAllLines', settings)