from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
from common.client_config import client_info as cl
import labrad

#global flag
#flag=True

class Optimize397(pulse_sequence):

    scannable_params = {
        'StateReadout.state_readout_amplitude_397':  [(-26., -10., 1., 'dBm'), '397power'],
        'StateReadout.state_readout_frequency_397':  [(190., 220., 1., 'MHz'), '397frequency'],
              }
   
    fixed_params = {
            #'StateReadout.pmt_readout_duration': U(1000,'ms'),
            #'StateReadout.repeat_each_measurement':1,
            'DopplerCooling.doppler_cooling_repump_additional':U(0,'us'),
            'StateReadout.readout_mode':'total_pmt_counts',            
          }

    def sequence(self):
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
        # building the sequence
        self.end = U(10., 'us')
        self.addSequence(TurnOffAll)
        global flag
        global after_initial
        if not after_initial:
          self.addSequence(StateReadout, {'StateReadout.state_readout_amplitude_866': U(-63,'dBm')})
        elif flag:
          self.addSequence(StateReadout)
             
    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        cxn.normalpmtflow.set_mode('Normal')
        global flag
        global after_initial
        flag=True
        after_initial=False
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
      pass

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass
        
class Optimize397Freq(Optimize397): 

    scannable_params = {
        'StateReadout.state_readout_frequency_397':  [(190., 225., 1., 'MHz'), '397frequency'],
              }
   
    fixed_params = {
            'StateReadout.state_readout_amplitude_397': U(-22,'dBm'),
            'DopplerCooling.doppler_cooling_repump_additional':U(0,'us'),
            'StateReadout.readout_mode':'total_pmt_counts',     
          }

    checked_params = ['StateReadout.state_readout_frequency_397']  

    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x): 
        data = data.sum(1)
        global flag
        global after_initial
        if not after_initial:
          after_initial= True
        if len(data)>1:
          flag=(data[-1]>=data[-2]*.9 and flag) 
#           #added this since sometimes counts drop by more than 10% early, but don't want to change the
#           #condition from .9 to .8 or .85 because worried about kicking out an ion
#           if not flag:
#                 flag= (max(data)-data[1])<10000

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x): 
      global flag
      if flag:
        raise Exception('Did not scan frequency far enough')
      else:
        #Calculate and store Doppler Cooling Frequency
        i=0
        while data[i]-data[0]<(max(data)-data[0])*.5: 
            i+=1
        result=U(x[i],'MHz')
        print 'Doppler Freq:',result
        sc = cxn.scriptscanner 
        sc.set_parameter('DopplerCooling', 'doppler_cooling_frequency_397', result)
        sc.set_parameter('StateReadout', 'state_readout_frequency_397', result)


class Scan397Power(Optimize397): 

    scannable_params = {
        'Heating.background_heating_time':  [(0., 0., 1., 'us'), 'current'],
              }

    checked_params = ['Heating.background_heating_time']

    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        global after_initial
        after_initial=True

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x): 
      return data.sum(1)[0]

class Optimize397PowerDifferential(pulse_sequence):

  sequence = [(Scan397Power, {'StateReadout.state_readout_amplitude_866': U(-63,'dBm')}), (Scan397Power, {})]

  @classmethod
  def run_finally(cls, cxn, parameter_dict, cnts, seq_name):
      global flag
      global max_diff
      differential=cnts[1]-cnts[0]
      if differential> max_diff:
        max_diff=differential
      else:
        flag=False 
      return differential


class Optimize397Power(pulse_sequence):

  scannable_params = {'StateReadout.state_readout_amplitude_397':  [(-26., -10., 1., 'dBm'), '397power']} 
  checked_params = ['StateReadout.state_readout_amplitude_397']

  sequence = Optimize397PowerDifferential

  @classmethod
  def run_initial(cls,cxn, parameters_dict): 
        global max_diff
        global flag
        max_diff=-1
        flag=True
        
  @classmethod
  def run_in_loop(cls,cxn, parameters_dict, data, x):
        if not flag:
            #Calculate and store Doppler Cooling and Readout Power
            i=0
            while data[i]<max(data)*.33: 
                i+=1
            pow_dop=U(x[i-1],'dBm')
            pow_read=U(x[data.index(max(data))],'dBm')
            print 'Doppler Amp:',pow_dop
            print 'Readout Amp:',pow_read

            sc = cxn.scriptscanner 
            sc.set_parameter('DopplerCooling', 'doppler_cooling_amplitude_397', pow_dop)
            sc.set_parameter('StateReadout', 'state_readout_amplitude_397', pow_read)

            # Kill this sequence 
            ID, name = sc.get_running()[-1]
            sc.stop_sequence(ID)

  @classmethod
  def run_finally(cls,cxn, parameters_dict, data, x): 
      global flag
      if flag:
        raise Exception('Did not scan power far enough')


class Calibrations_DopplerCooling(pulse_sequence):
    sequence = [Optimize397Freq, Optimize397Power]
    #global flag
    #sequence =[[Optimize397Freq,Optimize397Power] if flag else [Optimize397Power,Optimize397Freq] for x in [1]][0]