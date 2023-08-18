from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from subsequences.EmptySequence import EmptySequence 
#from pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np
import time


class LightShiftGate_TTL(pulse_sequence):

    fixed_params = {
        'StateReadout.readout_mode': "pmt_states",
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
        'LightShift.duration': [(0.0, 0.5, 0.02, 'ms'), 'starkshift'],
        'LightShift.gate2_detuning':[(5, 100, 10, 'kHz'), 'starkshift'],
        'LightShift.gate1_amplitude':[(-30, -14, 1, 'dBm'), 'ramsey'],
        'LightShift.gate2_amplitude':[(-30, -14, 1, 'dBm'), 'ramsey'],
        'LightShift.power_offset':[(-10, 2, 1, 'dBm'), 'ramsey'],
        'LightShift.gate2_echoPhase':[(0, 360, 15, 'deg'), 'ramsey']
        }

    show_params= [
        'LightShift.duration',
        'LightShift.gate1',
        'LightShift.gate1_amplitude',
        'LightShift.gate2_amplitude',
        'LightShift.gate2_detuning',
        #'LightShift.CenterNoiseFrequency',
        'LightShift.FMdepth',
        #'LightShift.gate3_amplitude',
        'LightShift.order',
        'LightShift.PiTimeDuration',
        'LightShift.PiOverTwoTimeDuration',
        'LightShift.selection_sideband',
        'LightShift.fixedTime',
        'LightShift.UseCustomPiTimes',
        'LightShift.power_offset',
        'LightShift.addRandomPhase',
        'LightShift.modFreq',

        'RabiFlopping.line_selection',
        'RabiFlopping.selection_sideband',
        'RabiFlopping.order',
        'RabiFlopping.rabi_amplitude_729',
        'RabiFlopping.duration',

        'Ramsey.echo_enable',
        'Ramsey.second_pulse_phase',
        'LineTrigger.frequency'
        ]


    @classmethod
    def run_initial(cls,cxn, parameters_dict):

        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(True)
        # sc=cxn.scriptscanner
        # sc.set_parameter('LightShift','gate1', 'gate1')
        # sc.set_parameter('LightShift','gate2', 'gate2')
        # act_dur=sc.get_parameter('LightShift', 'duration')
        # act_dur=act_dur['us']
        # detuning=sc.get_parameter('LightShift', 'gate2_detuning')
        # pred_dur=2000./detuning['kHz']
        # if act_dur<pred_dur*.9:
        #     sc.set_parameter('LightShift', 'duration', U(pred_dur,'us'))
        ######### set marconi freq
        # getting the params
        ls = parameters_dict.LightShift

        #if ls.gate1 == "gate1":
            # creating marconi instances
        global marconi 
        global marconi_2
        marconi = cxn.marconi_2024 #gate 1
        marconi_2 = cxn.marconi_2024_g2 #gate 2
                                
        gate_freq = ls.gate_frequency
        detuning = ls.mutual_detuning+ls.gate2_detuning+1.0*parameters_dict.TrapFrequencies[ls.selection_sideband]*ls.order
        f = gate_freq + detuning

        a1=ls.gate1_amplitude     
        a2=ls.gate2_amplitude

        # changing the frequency of the marconi's
        marconi.amplitude(a1)
        marconi.frequency(gate_freq)
        marconi.mod(False)
        marconi_2.amplitude(a2)
        marconi_2.frequency(f)
        
        fm_devn=ls.FMdepth*abs(ls.gate2_detuning['kHz'])/100.
        
        marconi_2.mod(fm_devn)

        global is_first_exp
        is_first_exp=True

        time.sleep(0.5) # just make sure everything is programmed before starting the sequence
        # else:
        #     Exception("Set LightShift.gate1 to gate1 ;)")

    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.EmptySequence import EmptySequence
        from subsequences.StateReadout import StateReadout
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.LightShiftTTL import LightShiftTTL
        
        frequency_advance_duration = U(6, 'us')
        
        # calculate the 729 params
        rf = self.parameters.RabiFlopping  
        r = self.parameters.Ramsey   
        sr=self.parameters.StateReadout
        lt=self.parameters.LineTrigger
        # calculating the 729 freq from the Rabi flop params
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)
        
        ls = self.parameters.LightShift

        # Pi and Pi/2 definition 
        piDuration = ls.PiTimeDuration if ls.UseCustomPiTimes else rf.duration
        piOverTwoDuration = ls.PiOverTwoTimeDuration if ls.UseCustomPiTimes else rf.duration*0.5

        # Can fix time to be exactly the desired gate time.
        if ls.fixedTime:
            timeShift = U((1/ls.gate2_detuning['kHz'])*1.e3,'us') 
            print timeShift
        else:
            timeShift=.5*ls.duration

        if r.echo_enable:
            total_time = (timeShift + rf.duration+U(6,'us')) #6us is gate between ramsey pulse
            total_time = total_time['s']

            detuning = ls.gate2_detuning['Hz']

            #extraPhase = U(np.rad2deg(-total_time*np.abs(detuning)*2.*np.pi)%360., 'deg')
            extraPhase = ls.gate2_echoPhase
            #print extraPhase,total_time

        else:
            extraPhase = U(0,'deg')   
        
        global is_first_exp
        if is_first_exp:
            global marconi 
            global marconi_2
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
            is_first_exp=False
            time.sleep(0.5)

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
        
        print 'gatelen', timeShift
        if ls.duration>0:
            self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
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
            self.addSequence(LightShiftTTL,{'LightShift.duration':  timeShift,
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

        # print 'KLHGIOERHOGHEIOHGUKERGUKHERGHERUIGFYFUIEGFU:AWBUGVWEF'
        # print self.end
        # print self.start

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
        global is_first_exp
        is_first_exp = True
        

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        #turn off marconis
        global marconi 
        global marconi_2
        marconi.mod(False)
        #marconi_2.mod(U(10.0,'Hz'))
        marconi_2.mod(False)
        
        #turn off linetrigger
        p_cxn=cxn.pulser
        p_cxn.line_trigger_state(False)
        
        time.sleep(0.5)