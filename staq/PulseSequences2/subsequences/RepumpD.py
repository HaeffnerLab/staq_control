from common.devel.bum.sequences.pulse_sequence import pulse_sequence

class RepumpD(pulse_sequence):
   
  
    def sequence(self):
        p = self.parameters.RepumpD_5_2
        st = self.parameters.StateReadout 

        self.end = self.start + p.repump_d_duration
        self.addDDS('854dp', self.start, p.repump_d_duration, p.repump_d_frequency_854, p.repump_d_amplitude_854)
        self.addDDS ('866dp',self.start, p.repump_d_duration, st.state_readout_frequency_866, st.state_readout_amplitude_866)