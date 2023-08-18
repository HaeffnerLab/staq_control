from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

class Motional_Ramsey(pulse_sequence):
    
    #name = 'Ramsey'

    scannable_params = {
                        
        'RamseyScanGap.ramsey_duration': [(0, 1.0, 0.5, 'ms') ,'ramsey'],
        'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey']
        }

    show_params= ['Motional_Ramsey.simple',
                  'Motional_Ramsey.BSB_duration',
                  'Motional_Ramsey.BSB_laser',
                  'Motional_Ramsey.BSB_amp',

                  'RamseyScanGap.ramsey_duration',
                  'Ramsey.echo_enable',
                  
                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                                                      
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable']

    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.StateReadout import StateReadout
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        
        
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping   
        # calculating the 729 freq form the Rabi flop params
        freq_carr=self.calc_freq(rf.line_selection , rf.selection_sideband , 0)
        freq_BSB=self.calc_freq(rf.line_selection , rf.selection_sideband , 1)
        freq_RSB=self.calc_freq(rf.line_selection , rf.selection_sideband , -1)

        
        print "1234"
        print " freq 729 " , freq_carr
        print " Wait time ", self.parameters.RamseyScanGap.ramsey_duration
        
        # building the sequence
        self.addSequence(StatePreparation)

        if self.parameters.Motional_Ramsey.simple:
          self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Motional_Ramsey.BSB_laser,
                                             'Excitation_729.rabi_excitation_frequency': freq_BSB,
                                             'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                             'Excitation_729.rabi_excitation_duration':  .5*self.parameters.Motional_Ramsey.BSB_duration,
                                             'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                              })
          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : 0.5*self.parameters.RamseyScanGap.ramsey_duration})
          
          if self.parameters.Ramsey.echo_enable:
              self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Excitation_729.channel_729,
                                             'Excitation_729.rabi_excitation_frequency': freq_carr,
                                             'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                             'Excitation_729.rabi_excitation_duration':  rf.duration,
                                             'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                              })
              
              self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : 0.5*self.parameters.RamseyScanGap.ramsey_duration})
              
              self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Excitation_729.channel_729,
                                             'Excitation_729.rabi_excitation_frequency': freq_RSB,
                                             'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                             'Excitation_729.rabi_excitation_duration':  .5*self.parameters.Motional_Ramsey.BSB_duration,
                                             'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                              })
          else:
            self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : 0.5*self.parameters.RamseyScanGap.ramsey_duration})
          
            self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Motional_Ramsey.BSB_laser,
                                               'Excitation_729.rabi_excitation_frequency': freq_BSB,
                                               'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                               'Excitation_729.rabi_excitation_duration':  .5*self.parameters.Motional_Ramsey.BSB_duration,
                                               'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                                })
        else:       
          self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Excitation_729.channel_729,
                                           'Excitation_729.rabi_excitation_frequency': freq_carr,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  .5*rf.duration,
                                           'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                            })   

          self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Motional_Ramsey.BSB_laser,
                                           'Excitation_729.rabi_excitation_frequency': freq_BSB,
                                           'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                           'Excitation_729.rabi_excitation_duration':  self.parameters.Motional_Ramsey.BSB_duration,
                                           'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                            })

          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : 0.5*self.parameters.RamseyScanGap.ramsey_duration})

          if self.parameters.Ramsey.echo_enable:
            self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Motional_Ramsey.BSB_laser,
                                           'Excitation_729.rabi_excitation_frequency': freq_BSB,
                                           'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                           'Excitation_729.rabi_excitation_duration':  self.parameters.Motional_Ramsey.BSB_duration,
                                           'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                            })
            self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Excitation_729.channel_729,
                                           'Excitation_729.rabi_excitation_frequency': freq_carr,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  rf.duration,
                                           'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                            })
            self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Motional_Ramsey.BSB_laser,
                                           'Excitation_729.rabi_excitation_frequency': freq_BSB,
                                           'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                           'Excitation_729.rabi_excitation_duration':  self.parameters.Motional_Ramsey.BSB_duration,
                                           'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                            })   
          
          self.addSequence(EmptySequence,  { "EmptySequence.empty_sequence_duration" : 0.5*self.parameters.RamseyScanGap.ramsey_duration})

          self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Motional_Ramsey.BSB_laser,
                                           'Excitation_729.rabi_excitation_frequency': freq_BSB,
                                           'Excitation_729.rabi_excitation_amplitude': self.parameters.Motional_Ramsey.BSB_amp,
                                           'Excitation_729.rabi_excitation_duration':  self.parameters.Motional_Ramsey.BSB_duration,
                                           'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                            })
      
          self.addSequence(RabiExcitation,{'Excitation_729.channel_729': self.parameters.Excitation_729.channel_729,
                                           'Excitation_729.rabi_excitation_frequency': freq_carr,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  .5*rf.duration,
                                           'Excitation_729.rabi_excitation_phase': self.parameters.Ramsey.second_pulse_phase 
                                            }) 

        
        self.addSequence(StateReadout)
        
    @classmethod
    def run_initial(cls,cxn, parameters_dict):
      pass
        
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        #print "Running in loop Rabi_floping"
        pass
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass

        

#if __name__=='__main__':
#    #pv = TreeDict.fromdict({'DopplerCooling.duration':U(5, 'us')})
    #ex = Sequence(pv)
    #psw = pulse_sequence_wrapper('example.xml', pv)
#    print 'executing a scan gap'
#    Ramsey.execute_external(('Ramsey.ramsey_time', 0, 10.0, 0.1, 'ms'))