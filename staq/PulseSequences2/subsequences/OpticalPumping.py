from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit

class OpticalPumping(pulse_sequence):
    
    '''
    Optical pumping unig a frequency selective transition  
    '''

    def sequence(self):
        op = self.parameters.OpticalPumping
        opc = self.parameters.OpticalPumpingContinuous
         
        channel_729 = self.parameters.StatePreparation.channel_729
        # choose the carrier frequency
        freq_729 = self.calc_freq(op.line_selection)

        repump_dur_854 = opc.optical_pumping_continuous_duration + opc.optical_pumping_continuous_repump_additional
        repump_dur_866 = opc.optical_pumping_continuous_duration + 2 * opc.optical_pumping_continuous_repump_additional
        self.end = self.start + repump_dur_866
        
        self.addDDS(channel_729, self.start, opc.optical_pumping_continuous_duration, freq_729, op.optical_pumping_amplitude_729)
        self.addDDS('854dp', self.start, repump_dur_854, op.optical_pumping_frequency_854, op.optical_pumping_amplitude_854)
        self.addDDS('866dp', self.start, repump_dur_866, op.optical_pumping_frequency_866, op.optical_pumping_amplitude_866)