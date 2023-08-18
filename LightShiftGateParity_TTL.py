from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from subsequences.EmptySequence import EmptySequence 
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time

class LightShiftGateParity_TTL(pulse_sequence):

    fixed_params = {'StateReadout.readout_mode': "pmt_parity",
        'RabiFlopping.line_selection': 'S-1/2D-1/2',
        'RabiFlopping.order': 0,
        'StatePreparation.sideband_cooling_enable': True,
        'StatePreparation.optical_pumping_enable': True,
        'SidebandCooling.line_selection': 'S-1/2D-5/2',
        'SidebandCooling.order': -1,
        'SidebandCooling.selection_sideband': 'axial_frequency',
        'LightShift.gate1':'gate1',
        'LightShift.gate2':'gate2',
        }

    scannable_params = {
      
        'Ramsey.second_pulse_phase': [(0, 360., 15, 'deg') ,'ramsey'],
        'LightShift.PiTimeDuration': [(4.0, 6.0, 0.1, 'us') ,'ramsey'],
        'LightShift.PiOverTwoTimeDuration': [(2.0,3.0,0.1, 'us') ,'ramsey'],
        }

    show_params= [

                  'LightShift.duration',
                  'LightShift.gate1',
                  'LightShift.gate1_amplitude',
                  'LightShift.gate2_amplitude',
                  'LightShift.FMdepth',
                  'LightShift.mutual_detuning',
                  'LightShift.gate2_detuning',
                  'LightShift.order',
                  'LightShift.selection_sideband',
                  'LightShift.power_offset',
                  'LightShift.addRandomPhase',
                  'LightShift.modFreq',

                  'LightShift.PiTimeDuration',
                  'LightShift.PiOverTwoTimeDuration',
                  'LightShift.UseCustomPiTimes',

                  'RabiFlopping.line_selection',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',

                  'Ramsey.echo_enable',
                  'LineTrigger.frequency',
                                                      
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable']
    
    @classmethod
    def run_initial(cls, cxn, parameters_dict):

        #turn on linetriggering
        p_cxn = cxn.pulser
        p_cxn.line_trigger_state(True)

        #pass
        # getting the params
        ls = parameters_dict.LightShift
        rf = parameters_dict.RabiFlopping
        r = parameters_dict.Ramsey  
                                            
        if ls.gate1 == "gate1":
          # creating an marconi instance
          global marconi 
          global marconi_2
          marconi = cxn.marconi_2024 #gate 1
          marconi_2 = cxn.marconi_2024_g2 #gate 2
          #marconi_3 = cxn.marconi_2024_g3 #gate 3
                                    
          gate_freq=ls.gate_frequency
          detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*parameters_dict.TrapFrequencies[ls.selection_sideband]*ls.order
          f=gate_freq+ detuning
                                    
          a1=ls.gate1_amplitude + ls.power_offset     
          a2=ls.gate2_amplitude + ls.power_offset
          a3=ls.gate3_amplitude

          if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
          else:
            timeShift=.5*ls.duration 

          if r.echo_enable:
            total_time = (timeShift + rf.duration)
            total_time = total_time['s']

            detuning = ls.gate2_detuning['Hz']

            extraPhase = U(np.rad2deg(-total_time*np.abs(detuning)*2.*np.pi)%360.,'deg')
            print extraPhase,total_time

          else:
            extraPhase = U(0,'deg')    
                                                      
          # changing the frequency of the marconi's
          marconi.amplitude(a1)
          marconi.frequency(gate_freq)
          marconi.mod(False)
          marconi_2.amplitude(a2)
          marconi_2.frequency(f)
        
          fm_devn=ls.FMdepth*abs(ls.gate2_detuning['kHz'])/100.
        
          marconi_2.mod(fm_devn)
                                    
#           print "Gate 1 run initial " , gate_freq, "at ", a1
#           print "Gate 2 run initial " , f, "at ", a2
#           print "Gate 3 run initial " , f, "at ", a3, "phase", extraPhase
                                              
          time.sleep(0.5) # just make sure everything is programmed before starting the sequence'''                                            
    
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftTTL import LightShiftTTL
        
        frequency_advance_duration = U(6, 'us')
        
        ## calculate the 729 params
        rf = self.parameters.RabiFlopping
        r = self.parameters.Ramsey   
        # calculating the 729 freq from the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)

        ls = self.parameters.LightShift
        sr=self.parameters.StateReadout
        lt=self.parameters.LineTrigger

        # Pi and Pi/2 definition 
        piDuration = ls.PiTimeDuration if ls.UseCustomPiTimes else rf.duration
        piOverTwoDuration = ls.PiOverTwoTimeDuration if ls.UseCustomPiTimes else rf.duration*0.5

        ## Can fix time to be exactly the desired gate time.
        if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz']),'ms')
            print timeShift
        else:
            timeShift=.5*ls.duration 

        # building the sequence


        if ls.addRandomPhase: 
            Tmod = (1./ls.modFreq['kHz'])*1.e3 #in us
            N = sr.repeat_each_measurement
            # Texp = self.end - self.start
            # Texp = Texp['us']*1e-3 # msecs

            Tstateprep=13260.0# us
            Texp=2.*piOverTwoDuration['us']+piDuration['us']+2.*timeShift['us']+Tstateprep
            
            Ttrig=1/(lt.frequency['Hz'])*1.e6 #in us
            Ttrig_mult=Ttrig
            j=1
            while Ttrig_mult<Texp and j<1e3:
                Ttrig_mult=j*Ttrig
                j+=1

            i, Textra = 1, -1
            while Textra < 0 and i < 1e6:
                Textra=i*Tmod/(N-1)-Ttrig_mult
                i+=1
                
            if Textra < 0:
                raise Exception("Random wait time is incorrect, increase i")
                
            Textra = U(Textra,'us')
            self.addSequence(EmptySequence, {'EmptySequence.empty_sequence_duration': Textra})
            print 'i,j:', i,j
            print 'KLHGIOERHOGHEIOHGUKERGUKHERGHERUIGFYFUIEGFU:AWBUGVWEF, T extra', Textra



        self.addSequence(StatePreparation)     

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  piOverTwoDuration,
                                         'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                         'Excitation_729.changeDDS': True 
                                          })       

        self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'),
                                     'LightShift.second_gate': True,
                                     'LightShift.second_gate2': False, 
                                      }) 

        if r.echo_enable:
            self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                           'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                           'Excitation_729.rabi_excitation_duration':  piDuration,
                                           'Excitation_729.rabi_excitation_phase': U(0, 'deg'),
                                           'Excitation_729.changeDDS': False,  
                                            })

        self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
                                     'LightShift.gate1_phase': U(0,'deg'),
                                     'LightShift.gate2_phase': U(0,'deg'),
                                     'LightShift.second_gate': True,
                                     'LightShift.second_gate2': False,
                                      })

        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  piOverTwoDuration,
                                         'Excitation_729.rabi_excitation_phase':  U(0, 'deg'),
                                         'Excitation_729.changeDDS': False,
                                          })
        
        ## Parity check pi/2 
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  piOverTwoDuration,
                                         'Excitation_729.rabi_excitation_phase': self.parameters.Ramsey.second_pulse_phase,
                                         'Excitation_729.changeDDS': False, 
                                          }) 

        self.addSequence(StateReadout)
        
        # if ls.addRandomPhase: 
        #     Tmod = 1. / ls.modFreq['kHz']
        #     N = sr.repeat_each_measurement
        #     Texp = self.end - self.start
        #     Texp = Texp['us']*1e-3 # msecs
            
        #     i, Textra = 1, -1
        #     while Textra < 0 and i < 1e6:
        #         Textra=i*Tmod/(N+1)-Texp
        #         i+=1
                
        #     if Textra < 0:
        #         raise Exception("Random wait time is incorrect, increase i")
                
        #     Textra = U(Textra,'ms')
        #     self.addSequence(EmptySequence, {'EmptySequence.empty_sequence_duration': Textra})
        #     print 'KLHGIOERHOGHEIOHGUKERGUKHERGHERUIGFYFUIEGFU:AWBUGVWEF, T extra', Textra

    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        #print "Running in loop Rabi_floping"
      pass
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        global marconi 
        global marconi_2
        marconi.mod(False)
        marconi_2.mod(False)
        
        #turn off linetrigger
        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(False)

        

#if __name__=='__main__':
#    #pv = TreeDict.fromdict({'DopplerCooling.duration':U(5, 'us')})
    #ex = Sequence(pv)
    #psw = pulse_sequence_wrapper('example.xml', pv)
#    print 'executing a scan gap'
#    Ramsey.execute_external(('Ramsey.ramsey_time', 0, 10.0, 0.1, 'ms'))