from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time

class StarkShift_TTL(pulse_sequence):
    
    #name = 'Ramsey'

    scannable_params = {'LightShift.duration': [(0.000, 0.004, 0.0002, 'ms') ,'starkshift']}
    checked_params = ['LightShift.duration']

    fixed_params = {
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        #'StatePreparation.sideband_cooling_enable': False,
        'StatePreparation.optical_pumping_enable': True,
        }

    show_params= ['LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.gate2_amplitude',
                  'LightShift.mutual_detuning',
                  'LightShift.power_offset',


                  'RamseyScanPhase.scanphase',
                  'RamseyScanGap.detuning',

                  'Ramsey.dynamic_decoupling_enable',
                  'Ramsey.dd_repetitions',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                                                      
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable']

        
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        cxn.pulser.switch_auto('gate1')
        cxn.pulser.switch_auto('gate2')
        sc=cxn.scriptscanner
        sc.set_parameter('RabiFlopping','order', 0)
        ######### set marconi freq
        #pass
        # getting the params
        ls = parameters_dict.LightShift

        gate_freq=ls.gate_frequency
        detuning = ls.mutual_detuning
        f=gate_freq+ detuning
                                    
        a=ls.gate1_amplitude+ls.power_offset
        # sc.set_parameter('LightShift', 'power_offset',  U(0.0,'dBm'))
                                            
        if ls.gate1 == "gate1":
          # creating an marconi instance
          marconi = cxn.marconi_2024                      
                                                      
          # changing the amplitude and frequency of the marconi
          marconi.frequency(f)
          marconi.amplitude(a)
                                    
          print "Gate1: run initial " , f, "at ", a
                                              
          time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''

        elif ls.gate1 == "gate2":
          # creating an marconi instance
          marconi = cxn.marconi_2024_g2
                                                      
          # changing the amplitude and frequency of the marconi
          marconi.frequency(f)
          marconi.amplitude(a)
                                    
          print "Gate2: run initial " , f, "at ", a

        else:
          # creating an marconi instance
          marconi = cxn.marconi_2024_g3
                                                      
          # changing the amplitude and frequency of the marconi
          marconi.frequency(f)
          marconi.amplitude(a)
                                    
          print "Gate3: run initial " , f, "at ", a
                                              
          time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''
                    
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.StateReadout import StateReadout
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftTTL import LightShiftTTL
        
        
        rf = self.parameters.RabiFlopping   
        r = self.parameters.Ramsey
        l = self.parameters.LightShift 
        # calculating the 729 freq form the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        timeShift=l.duration

        # building the sequence
        self.addSequence(StatePreparation) 

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  .5*rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': True,
                                          })     

        if r.dynamic_decoupling_enable==False or r.dd_repetitions == 0:
          if timeShift>0:
            self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                         'LightShift.second_gate': False,
                                         'LightShift.gate1_phase': U(0, 'deg'),
                                         #'LightShift.changeDDS': True,
                                             }) 
        else:
          pulse_len=(0.5)*timeShift/(r.dd_repetitions)
          
          for i in range(int(r.dd_repetitions)):  
            if timeShift>0:
              self.addSequence(LightShiftTTL,{'LightShift.duration':  pulse_len,
                                           'LightShift.second_gate': False,
                                           'LightShift.gate1_phase': U(0, 'deg'),
                                           #'LightShift.changeDDS': (i==0),
                                               }) 

            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                            }) 
            if timeShift>0:
              self.addSequence(LightShiftTTL,{'LightShift.duration':  pulse_len,
                                           'LightShift.second_gate': False,
                                           'LightShift.gate1_phase': U(0, 'deg'),
                                           #'LightShift.changeDDS': False,
                                               }) 
            
        
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  .5*rf.duration,
                                         'Excitation_729.rabi_excitation_phase': r.second_pulse_phase, 
                                         'Excitation_729.changeDDS': False,
                                          }) 

        self.addSequence(StateReadout)

        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        #print "Running in loop Rabi_floping"
        pass
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass

class StarkShift_scan_phase_TTL(StarkShift_TTL):
    
    scannable_params = {
         
       'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey']               
        #'RamseyScanGap.ramsey_duration': [(0, 1.0, 0.5, 'ms') ,'ramsey']
      }

    @classmethod
    def run_finally(cls,cxn, parameter_dict, data, data_x):
      data=data.sum(1)
      fit_params=cls.sin_fit(data_x,data, return_all_params = True)
      return 2*fit_params[0]

class StarkShiftScanPhase_TTL(pulse_sequence):
    
    scannable_params = {'LightShift.duration': [(0.0001, 1.0, 0.5, 'ms') ,'starkshift'],}

    sequence = StarkShift_scan_phase_TTL

class Stark2Beam_TTL(pulse_sequence):


  sequence = [(StarkShift_TTL, {'LightShift.gate1':"gate1",'LightShift.gate1_amplitude':U(1.0,'dBm')}), (StarkShift_TTL, {'LightShift.gate1':"gate2",'LightShift.gate1_amplitude':U(2.0,'dBm')})]
  # sequence = [(StarkShift_TTL, {'LightShift.gate1':"gate1",'LightShift.gate1_amplitude':U(1.0,'dBm'),'LightShift.power_offset':U(0.0,'dBm')}), (StarkShift_TTL, {'LightShift.gate1':"gate2",'LightShift.gate1_amplitude':U(2.0,'dBm'),'LightShift.power_offset':U(0.0,'dBm')})]
  
  @classmethod
  def run_initial(cls, cxn, parameters_dict):
      super(Stark2Beam_TTL, cls).run_initial(cxn, parameters_dict)
      sc=cxn.scriptscanner
      # sc.set_parameter('LightShift', 'power_offset',  U(0.0,'dBm'))
      #sc.set_parameter('LightShift', 'gate2_amplitude', U(2.0,'dBm'))
      #sc.set_parameter('LightShift', 'gate1_amplitude', U(1.0,'dBm'))