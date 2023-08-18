from common.devel.bum.sequences.pulse_sequence import pulse_sequence
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time

class LightShiftGate_TTL_Thermal(pulse_sequence):
    
    #name = 'Ramsey'

    fixed_params = {
                    'StateReadout.readout_mode': "pmt_states"}

    scannable_params = {
                        
        'LightShift.duration': [(0.000, 0.5, 0.02, 'ms') ,'starkshift'],
        'LightShift.gate2_detuning':[(5,100,10,'kHz'),'starkshift'],
        'LightShift.gate1_amplitude':[(-30,-14,1,'dBm'),'ramsey'],
        'LightShift.gate2_amplitude':[(-30,-14,1,'dBm'),'ramsey'],
        'LightShift.power_offset':[(-10,10,1,'dBm'),'ramsey'],
        'LightShift.gate2_echoPhase': [(0, 360, 15, 'deg') ,'ramsey']
        }

    show_params= [
                  'LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.gate2_amplitude',
                  'LightShift.gate2_detuning',
                  'LightShift.gate3_amplitude',
                  'LightShift.order',
                  'LightShift.PiTimeDuration',
                  'LightShift.PiOverTwoTimeDuration',
                  'LightShift.selection_sideband',
                  'LightShift.fixedTime',
                  'LightShift.UseCustomPiTimes',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',

                  'Ramsey.echo_enable',
                  'Ramsey.second_pulse_phase',




                                                      ]

    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        ######### set marconi freq
        #pass
        # getting the params
        ls = parameters_dict.LightShift

        if ls.gate1 == "gate1":

          #global agilent
          #agilent=cxn.agilent_33220a
          #agilent.amplitude(U(0, 'deg'))
          #agilent.output(True)

          # creating an marconi instance
          global marconi 
          global marconi_2
          marconi = cxn.marconi_2024 #gate 1
          marconi_2 = cxn.marconi_2024_g2 #gate 2
                                    
          gate_freq=ls.gate_frequency
          detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*parameters_dict.TrapFrequencies[ls.selection_sideband]*ls.order
          f=gate_freq+ detuning
          
          a1=ls.gate1_amplitude     
          a2=ls.gate2_amplitude

          #a3=ls.gate3_amplitude                            
          # changing the frequency of the marconi's
          marconi.amplitude(a1)
          marconi.frequency(gate_freq)
          marconi.mod(False)
          marconi_2.amplitude(a2)
          marconi_2.frequency(f)
          marconi_2.mod(False)

          global first_run
          first_run=True

          time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftTTLThermal import LightShiftTTLThermal
        
        frequency_advance_duration = U(6, 'us')
        
        # calculate the 729 params
        rf = self.parameters.RabiFlopping  
        r = self.parameters.Ramsey   
        # calculating the 729 freq from the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        
        ls = self.parameters.LightShift


        # Pi and Pi/2 definition 
        piDuration = ls.PiTimeDuration if ls.UseCustomPiTimes else rf.duration
        piOverTwoDuration = ls.PiOverTwoTimeDuration if ls.UseCustomPiTimes else rf.duration*0.5

        ## Can fix time to be exactly the desired gate time.
        if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
        else:
            timeShift=.5*ls.duration

        if r.echo_enable:
            total_time = (timeShift + rf.duration+U(6,'us')) #6us is gate between ramsey pulse
            total_time = total_time['s']

            detuning = ls.gate2_detuning['Hz']

            #extraPhase = U(np.rad2deg(-total_time*np.abs(detuning)*2.*np.pi)%360., 'deg')
            extraPhase = ls.gate2_echoPhase
            print extraPhase,total_time

        else:
            extraPhase = U(0,'deg')   
        
        global first_run
        
        if first_run:
          global marconi 
          global marconi_2
          #global agilent
          a1=ls.gate1_amplitude
          a2=ls.gate2_amplitude

          if (a1+ls.power_offset)['dBm']>13 or (a2+ls.power_offset)['dBm']>13:
             raise Exception("Power Set too High!")

          marconi.amplitude(a1+ls.power_offset)
          marconi_2.amplitude(a2+ls.power_offset)

          gate_freq=ls.gate_frequency
          detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*self.parameters.TrapFrequencies[ls.selection_sideband]*ls.order
          f=gate_freq+ detuning
          marconi_2.frequency(f)
          #agilent.amplitude(extraPhase)
          #print "Gate 1 Amp:" , a1, "AND Gate 2 phase after ramsey:", extraPhase
          first_run=False
          time.sleep(0.5)

        # building the sequence
        self.addSequence(StatePreparation)  

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  piOverTwoDuration,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                         'Excitation_729.changeDDS': True 
                                          })       
        
        print 'gatelen', timeShift
        if ls.duration>0:
          self.addSequence(LightShiftTTLThermal,{'LightShift.duration':  timeShift,
                                       'LightShift.second_gate': True,  
                                       'LightShift.gate1_phase': U(0,'deg'),
                                       'LightShift.gate2_phase': U(0,'deg'), 
                                       'LightShift.second_gate2': False,
                                        }) 

        if r.echo_enable:
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  piDuration,
                                           'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                           'Excitation_729.changeDDS': False,  
                                            })
        if ls.duration>0:
          self.addSequence(LightShiftTTLThermal,{'LightShift.duration':  timeShift,
                                       'LightShift.gate1_phase': U(0,'deg'),
                                       'LightShift.gate2_phase': U(0,'deg'),
                                       'LightShift.second_gate': True,
                                       'LightShift.second_gate2': False,
                                        })

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  piOverTwoDuration,
                                         'Excitation_729.rabi_excitation_phase':  r.second_pulse_phase,
                                         'Excitation_729.changeDDS': False,
                                          }) 

        self.addSequence(StateReadout)

        
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x): 
        #print "Running in loop Rabi_floping"
        ######### set marconi freq
        global first_run
        print 'flag:', first_run
        first_run=True
        

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      #pass
      marconi.mod(False)
      marconi_2.mod(False)
      #global agilent
      #agilent.output(False)
      time.sleep(0.5)
