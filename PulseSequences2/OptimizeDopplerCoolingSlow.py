from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
from common.client_config import client_info as cl
import labrad


class Optimize397(pulse_sequence):

    scannable_params = {
        'StateReadout.state_readout_amplitude_397':  [(-20., -10., 1., 'dBm'), 'radial1'],
        'StateReadout.state_readout_frequency_397':  [(190., 220., 1., 'MHz'), 'radial2'],
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
        global cnts
        global flag
        global after_initial
        flag=True
        after_initial=False
        cnts=[]
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
      pass

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass
        
class Optimize397Freq(Optimize397): 

    scannable_params = {
        'StateReadout.state_readout_frequency_397':  [(190., 225., 1., 'MHz'), 'radial1'],
              }
   
    fixed_params = {
            'StateReadout.state_readout_amplitude_397': U(-20,'dBm'),
            'DopplerCooling.doppler_cooling_repump_additional':U(0,'us'),
            'StateReadout.readout_mode':'total_pmt_counts',     
          }

    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x): 
        data = data.sum(1)
        global flag
        global after_initial
        if not after_initial:
          after_initial= True
        if len(data)>1:
          flag=data[-1]>=data[-2]*.9 and flag

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x): 
      global flag
      if flag:
        raise Exception('Did not scan frequency far enough')
      else:
        i=0
        while data[i]-data[0]<(max(data)-data[0])*.5: 
            i+=1
        result=U(x[i],'MHz')
        print 'Doppler Freq:',result
        p_cxn = labrad.connect()
        sc = p_cxn.scriptscanner 
        sc.set_parameter('DopplerCooling', 'doppler_cooling_frequency_397', result)
        sc.set_parameter('StateReadout', 'state_readout_frequency_397', result)
        p_cxn.disconnect()

        
class Optimize397Power(Optimize397): 

    scannable_params = {
        'StateReadout.state_readout_amplitude_397':  [(-22., -10., 1., 'dBm'), 'radial1']} 
              
   
    fixed_params = {
            'StateReadout.state_readout_amplitude_397': U(-20,'dBm'),
            'DopplerCooling.doppler_cooling_repump_additional':U(0,'us'),
            'StateReadout.readout_mode':'total_pmt_counts',     
          }

    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x): 
        print 'CHANGE MODE to DIFF'
        cxn.normalpmtflow.set_mode('Differential')
        global cnts
        cnts=cnts+[cxn.normalpmtflow.get_next_counts(['DIFF',100,True])]
        print 'CHANGE MODE TO NORM'
        cxn.normalpmtflow.set_mode('Normal')
        
        global flag
        global after_initial
        if not after_initial:
          after_initial= True
        if len(cnts)>1:
          flag=cnts[-1]>=cnts[-2]*.9 and flag

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x): 
        global flag
        if flag:
          raise Exception('Did not scan power far enough')
        else:
          i=0
          while cnts[i]<max(cnts)*.33: 
              i+=1
          pow_dop=U(x[i-1],'dBm')
          pow_read=U(x[cnts.index(max(cnts))],'dBm')
          print 'Doppler Amp:',pow_dop
          print 'Readout Amp:',pow_read
          p_cxn = labrad.connect()
          sc = p_cxn.scriptscanner 
          sc.set_parameter('DopplerCooling', 'doppler_cooling_amplitude_397', pow_dop)
          sc.set_parameter('StateReadout', 'state_readout_amplitude_397', pow_read)
          p_cxn.disconnect()   

class OptimizeDopplerCooling(pulse_sequence):
    sequence = [Optimize397Freq, Optimize397Power]