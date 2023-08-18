from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time

class StarkShift(pulse_sequence):
    
    #name = 'Ramsey'

    scannable_params = {
                        
        'LightShift.duration': [(0, 1.0, 0.1, 'ms') ,'starkshift'],
        'RamseyScanGap.ramsey_duration': [(0, 1.0, 0.1, 'ms') ,'ramsey']
        }

    show_params= ['LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.mutual_detuning',

                  'RamseyScanGap.ramsey_duration',
                  'RamseyScanPhase.scanphase',
                  'RamseyScanGap.detuning',


                  'Ramsey.echo_enable',
                  'Ramsey.second_pulse_phase',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                                                      
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable']

        
    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        ######### motion analysis
        pass
        # getting the params
        '''ls = parameters_dict.LightShift
                                            
                                if ls.gate1 == "gate2":
                                    # creating an marconi instance
                                    marconi = cxn.marconi_2024
                                    
                                    gate_freq=ls.gate_frequency
                                    detuning = ls.mutual_detuning
                                    f=gate_freq+ detuning
                                    
                                    a=ls.gate1_amplitude
                                                      
                                    # changing the amplitude and frequency of the marconi
                                    marconi.frequency(f)
                                    marconi.amplitude(a)
                                    
                                    print "run initial " , f, "at ", a
                                              
                                    time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''
                    
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.StateReadout import StateReadout
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShift import LightShift
        
        
        rf = self.parameters.RabiFlopping   
        r = self.parameters.Ramsey
        l = self.parameters.LightShift 
        rsg = self.parameters.RamseyScanGap
        # calculating the 729 freq form the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        if self.parameters.Ramsey.echo_enable:  
          timeShift=l.duration*0.5
        else:
          timeShift=l.duration

        # building the sequence
        self.addSequence(StatePreparation)       
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+rsg.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  .5*rf.duration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': True,
                                          })     

        self.addSequence(LightShift,{'LightShift.duration':  timeShift,
                                     'LightShift.second_gate': False,
                                     'LightShift.gate1_phase': U(0, 'deg'),
                                     'LightShift.changeDDS': True,
                                         }) 

        self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : .5*rsg.ramsey_duration})

        if self.parameters.Ramsey.echo_enable:
          self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+rsg.detuning,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          })

          # self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : timeShift+.5*self.parameters.RamseyScanGap.ramsey_duration})
          
          self.addSequence(LightShift,{'LightShift.duration':  timeShift,
                                     'LightShift.second_gate': False,
                                     'LightShift.gate1_phase': U(0, 'deg'),
                                     'LightShift.changeDDS': False,
                                         }) 

          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : .5*rsg.ramsey_duration})
        
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729+rsg.detuning,
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

  

class StarkShift_scan_phase(StarkShift):
    
    scannable_params = {
         
       'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey']               
        #'RamseyScanGap.ramsey_duration': [(0, 1.0, 0.5, 'ms') ,'ramsey']
      }

    @classmethod
    def run_finally(cls,cxn, parameter_dict, data, data_x):
      data=data.sum(1)
      fit_params=cls.sin_fit(data_x,data, return_all_params = True)
      return 2*fit_params[0]

class StarkShiftScanPhase(pulse_sequence):
    
    scannable_params = {'LightShift.duration': [(0, 1.0, 0.5, 'ms') ,'starkshift'],}

    sequence = StarkShift_scan_phase