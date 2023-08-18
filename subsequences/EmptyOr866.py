from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit

class EmptyOr866(pulse_sequence):
  
    def sequence(self):
        
        duration=self.parameters.EmptySequence.empty_sequence_duration
        
        if self.parameters.Heating.On866:
        	op = self.parameters.OpticalPumping
        	opc = self.parameters.OpticalPumpingContinuous
        	self.addDDS('866dp', self.start, duration, op.optical_pumping_frequency_866, op.optical_pumping_amplitude_866)

        
        self.end = self.start + duration
