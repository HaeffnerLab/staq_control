from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit

class EmptySequence(pulse_sequence):
  
    def sequence(self):
        
        duration=self.parameters.EmptySequence.empty_sequence_duration
        self.end = self.start + duration
