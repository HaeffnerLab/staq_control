from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

#class RabiFloppingMulti(pulse_sequence):
#    is_multi = True
#    sequences = [RabiFlopping, Spectrum]

class RabiFlopping(pulse_sequence):
    scannable_params = {
        'RabiFlopping.duration':  [(0., 300., .5, 'us'), 'rabi'],
        # 'OpticalPumpingContinuous.optical_pumping_continuous_duration':  [(0., 50., 3, 'ms'), 'rabi'],
        # 'OpticalPumping.optical_pumping_amplitude_729':  [(-12., -5., 0.5, 'dBm'), 'rabi'],
        'OpticalPumping.optical_pumping_amplitude_854':  [(-12., -5., 0.5, 'dBm'), 'rabi'],
        'SidebandCooling.stark_shift':  [(-20., 20., 0.5, 'kHz'), 'rabi'],
        'SidebandCooling.sideband_cooling_amplitude_854':  [(-30., -5., 0.5, 'dBm'), 'rabi'],
        'SidebandCooling.sideband_cooling_amplitude_729':  [(-30., -5., 0.5, 'dBm'), 'rabi'],
        #'Heating.postscan_wait_time':  [(0., 1., .01, 's'), 'rabi'],
        
              }

    show_params= ['Excitation_729.channel_729',
                  'RabiFlopping.line_selection',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'Heating.On866',
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable'
                  ]
    
    #fixed_params = {'StateReadout.ReadoutMode':'camera'}
    checked_params = ['RabiFlopping.duration'] 


    def sequence(self):
        from StatePreparation import StatePreparation
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
        from subsequences.EmptyOr866 import EmptyOr866
        
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
        self.addSequence(StatePreparation)
        #self.addSequence(RabiExcitation)     
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration })
        
        #self.addSequence(EmptyOr866,  { "EmptySequence.empty_sequence_duration" : self.parameters.Heating.postscan_wait_time})
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
        
        
        
