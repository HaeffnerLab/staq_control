from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit
import numpy as np

def dBtoW(dB):
    return 10.**(dB/10.)

def WtodB(W):
    return 10.*np.log10(W)
  
class LightShiftRamp(pulse_sequence):
    '''
    Runs a 729 excitation with the Excitation_729 params
    channel_729
    
    rabi_excitation_amp
    rabi_excitation_duration
    rabi_excitation_frequency
    rabi_excitation_phase
    '''
    


    def sequence(self):
        
        frequency_advance_duration = WithUnit(6, 'us')

        l = self.parameters.LightShift

        rampTime = l.rampTime

        freq_gate = l.gate_frequency
        duration = l.duration
        phase_1 = l.gate1_phase
        maxAmp_1 = l.gate1_amplitude
        channel_1 = l.gate1
        detuning_1=l.mutual_detuning

        phase_2 = l.gate2_phase
        maxAmp_2 = l.gate2_amplitude
        channel_2 = l.gate2
        detuning_2=l.mutual_detuning+l.gate2_detuning+1.0*self.parameters.TrapFrequencies[l.selection_sideband]*l.order
        
        print " Gate freq1: ",freq_gate+detuning_1 
        print " Gate freq2: ",freq_gate+detuning_2 

        #Minimum time step is 50ns
        stepSize = WithUnit(0.2,'us')
        steps = rampTime['us']/stepSize['us']

        amp0 = WithUnit(-63,'dBm')

        # Even steps in power (mW) for a linear amplitude ramp
        ampStepSize_1 = (dBtoW(maxAmp_1['dBm'])-dBtoW(amp0['dBm']))/steps
        ampStepSize_2 = (dBtoW(maxAmp_2['dBm'])-dBtoW(amp0['dBm']))/steps

        if duration < 2.0*rampTime:
            print "error need shorter ramp"
         
        time = self.start
        # start dds channels at 0 power to advance frequency
        self.addDDS(channel_1, time, frequency_advance_duration, freq_gate + detuning_1, amp0)
        if l.second_gate:
            self.addDDS(channel_2, time, frequency_advance_duration, freq_gate + detuning_2, amp0)
        time = time + frequency_advance_duration


        amp_1 = amp0
        amp_2 = amp0
        
        #ramp up
        for step in np.arange(0,rampTime+stepSize,stepSize):
            self.addDDS(channel_1, time, stepSize, freq_gate + detuning_1, amp_1, phase_1)
            if l.second_gate:
                self.addDDS(channel_2, time, stepSize, freq_gate + detuning_2, amp_2, phase_2)
            time = time+stepSize
            amp_1 = WithUnit(WtodB(dBtoW(amp_1['dBm'])+ampStepSize_1),'dBm')
            amp_2 = WithUnit(WtodB(dBtoW(amp_2['dBm'])+ampStepSize_2),'dBm')

            if amp_1 > maxAmp_1:
                amp_1 = maxAmp_1
            if amp_2 > maxAmp_2:
                amp_2 = maxAmp_2    


        # hold steady
        self.addDDS(channel_1, time, duration-rampTime*2.0, freq_gate + detuning_1, amp_1, phase_1)
        if l.second_gate:
                self.addDDS(channel_2, time, duration-rampTime*2.0, freq_gate + detuning_2, amp_2, phase_2)
        time = time+duration-rampTime*2.0
        print "!!",time

        # ramp down
        for step in np.arange(0,rampTime+stepSize,stepSize):
            self.addDDS(channel_1, time, stepSize, freq_gate + detuning_1, amp_1, phase_1)
            if l.second_gate:
                self.addDDS(channel_2, time, stepSize, freq_gate + detuning_2, amp_2, phase_2)

            time = time+stepSize
            print time
            amp_1 = WithUnit(WtodB(dBtoW(amp_1['dBm'])-ampStepSize_1),'dBm')
            amp_2 = WithUnit(WtodB(dBtoW(amp_2['dBm'])-ampStepSize_2),'dBm')

            if amp_1 < amp0:
                amp_1 = amp0
            if amp_2 < amp0:
                amp_2 = amp0  

        self.end = self.start + duration + frequency_advance_duration
            
            
            
