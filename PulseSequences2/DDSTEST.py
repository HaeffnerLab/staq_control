from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

#class RabiFloppingMulti(pulse_sequence):
#    is_multi = True
#    sequences = [RabiFlopping, Spectrum]

class DDSTEST(pulse_sequence):
    scannable_params = {
        'RabiFlopping.duration':  [(0., 50., 3, 'us'), 'rabi'],
        'EmptySequence.empty_sequence_duration': [(0., 50., 3, 'us'), 'rabi'],


              }

    show_params= ['Excitation_729.channel_729',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  'EmptySequence.empty_sequence_duration'
                  ]
    
    #fixed_params = {'StateReadout.ReadoutMode':'camera'}



    def sequence(self):
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
        
        ## calculate the scan params
        rf = self.parameters.RabiFlopping 
        
        #freq_729=self.calc_freq(rf.line_selection)
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        print " Rabi flopping script"
        print "Rabi flopping 729 freq is {}".format(freq_729)
        #print "Rabi flopping duration is {}".format(rf.duration)
        # building the sequence
        self.end = U(10., 'us')
        #self.addSequence(TurnOffAll)
        self.addSequence(TurnOffAll)
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': U(220.,'MHz'),
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  self.parameters.EmptySequence.empty_sequence_duration,
                                         'Excitation_729.channel_729':'gate1' })

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration })
        
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

        #np.save('temp_PMT', data)
        #print "saved ion data"
        
        
        
