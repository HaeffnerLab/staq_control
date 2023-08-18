from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit

  
class RabiExcitation(pulse_sequence):
    '''
    Runs a 729 excitation with the Excitation_729 params
    channel_729
    
    rabi_excitation_amp
    rabi_excitation_duration
    rabi_excitation_frequency
    rabi_excitation_phase
    '''
    

    def sequence(self):
        
        ampl_off = WithUnit(-63.0, 'dBm')
        frequency_advance_duration = WithUnit(6, 'us')

        e = self.parameters.Excitation_729
        
        freq_729 = e.rabi_excitation_frequency
        duration_729 = e.rabi_excitation_duration
        phase_729 = e.rabi_excitation_phase
        amp_729 = e.rabi_excitation_amplitude
        channel_729 = e.channel_729
        changeDDS = e.changeDDS
         
        start = self.start 
        print('RABICHECK'+str(duration_729))
        #first advance the frequency but keep amplitude low 
        if changeDDS:       
            self.addDDS(channel_729, self.start, frequency_advance_duration, freq_729, ampl_off)
            start = self.start+frequency_advance_duration
        self.addDDS(channel_729, start, duration_729, freq_729, amp_729, phase_729)
        self.end = start + duration_729
                    

            
            
            
