
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit

  
class LightShiftTTLMod(pulse_sequence):
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

        l = self.parameters.LightShift

        freq_gate = l.gate_frequency
        duration_gate = l.duration
        phase_1 = l.gate1_phase
        amp_1 = l.gate1_amplitude
        channel_1 = l.gate1
        detuning_1=l.mutual_detuning
    
        phase_2 = l.gate2_phase
        amp_2 = l.gate2_amplitude
        channel_2 = l.gate2
        detuning_2=l.mutual_detuning+l.gate2_detuning+1.0*self.parameters.TrapFrequencies[l.selection_sideband]*l.order

        channel_3=l.gate3
        second_gate2_on=l.second_gate2
        
        print " Gate freq1: ",freq_gate+detuning_1 
        print " Gate freq2: ",freq_gate+detuning_2 
        start = self.start 

        # #first advance the frequency but keep amplitude low 
        # self.addDDS(channel_1, self.start, frequency_advance_duration, freq_gate + detuning_1, ampl_off)
        # if l.second_gate:
        #     self.addDDS(channel_2, self.start, frequency_advance_duration, freq_gate + detuning_2, ampl_off)
        
        delay = WithUnit(2.4, 'us')
        ramptime = WithUnit(1.6, 'us')

        if amp_1 != ampl_off:
            self.addTTL('ModON', self.start+ frequency_advance_duration, duration_gate-ramptime)
            self.addTTL(channel_1, self.start+ frequency_advance_duration+delay/2, duration_gate+delay+delay/2)

        if l.second_gate == True and amp_2 != ampl_off:
            self.addTTL(channel_2, self.start+ frequency_advance_duration+delay/2, duration_gate+delay+delay/2)

        # if l.second_gate:
        #     self.addDDS(channel_2, self.start + frequency_advance_duration, duration_gate, freq_gate + detuning_2, amp_2, phase_2)
        self.end = start + frequency_advance_duration*2 + duration_gate        
