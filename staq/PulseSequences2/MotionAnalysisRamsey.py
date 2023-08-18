from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
import time
from treedict import TreeDict
import numpy as np



class MotionAnalysisRamsey(pulse_sequence):
    
                          
    scannable_params = {   'Motion_Analysis.ramsey_duration': [(0, 10.0, 0.5, 'ms') ,'ramsey']}
 

    show_params= ['Motion_Analysis.pulse_width_397',
                  'Motion_Analysis.amplitude_397',
                  'Motion_Analysis.sideband_selection',
                  'Motion_Analysis.detuning',


                  

                  'RabiFlopping.duration',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',


                 
                 
                ]

    fixed_params = {'Display.relative_frequencies': True

                    }
    
    @classmethod
    def run_initial(cls, cxn, parameters_dict):
        
        ######### motion analysis
        # creating an agilent instance
        agi = cxn.agilent_33220a
        # getting the params
        ma = parameters_dict.Motion_Analysis

        detuning = ma.detuning
        # calc frequcy shift
        mode = ma.sideband_selection

        trap_frequency = parameters_dict['TrapFrequencies.' + mode]
                
        # run with detuning
        f = parameters_dict['TrapFrequencies.' + mode]
        f = f + detuning
        # changing the frequency of the Agilent
        agi.frequency(f)
        print "run initial " , agi.frequency()
        
        time.sleep(0.5) # just make sure everything is programmed before starting the sequence
    
    @classmethod
    def run_in_loop(cls, cxn, parameters_dict, data_so_far,data_x):
        pass
       


    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        pass
        # cxn.pulser.switch_manual('397mod', False)
        

        
    def sequence(self):        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.OpticalPumping import OpticalPumping
        from subsequences.MotionalAnalysis import MotionalAnalysis
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
        from subsequences.RabiExcitation import RabiExcitation
        
        # additional optical pumping duratrion 
        duration_op= self.parameters.SidebandCooling.sideband_cooling_optical_pumping_duration

        ## calculate the final diagnosis params
        rf = self.parameters.RabiFlopping 
        #freq_729=self.calc_freq(rf.line_selection)
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)


        self.end = U(10., 'us')
        self.addSequence(TurnOffAll)
        self.addSequence(StatePreparation)
        # 397 excitation 
        self.addSequence(MotionalAnalysis)
        # small optical pumping after the motion excitation
        self.addSequence(OpticalPumping, {'OpticalPumpingContinuous.optical_pumping_continuous_duration':duration_op/2.0 })

        # wait for desired time
        self.addSequence(EmptySequence,  { 'EmptySequence.empty_sequence_duration' : self.parameters.Motion_Analysis.ramsey_duration})

        # 397 excitation 
        self.addSequence(MotionalAnalysis)
        # small optical pumping after the motion excitation
        self.addSequence(OpticalPumping, {'OpticalPumpingContinuous.optical_pumping_continuous_duration':duration_op/2.0 })



        # 729 excitation to transfer the motional DOF to the electronic DOF
        # running the excitation from the Rabi flopping 
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration })

        
        self.addSequence(StateReadout)





