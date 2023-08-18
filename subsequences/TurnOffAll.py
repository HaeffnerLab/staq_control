from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit

class TurnOffAll(pulse_sequence):
    
    def sequence(self):
        dur = WithUnit(50, 'us')
        for channel in ['729dp','397dp','854dp','866dp']:
            self.addDDS(channel, self.start, dur, WithUnit(0, 'MHz'), WithUnit(-63., 'dBm') )
        
        self.end = self.start + dur