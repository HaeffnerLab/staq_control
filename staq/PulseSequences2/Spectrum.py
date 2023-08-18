#!scriptscanner

from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict

class Spectrum(pulse_sequence):
    
    
                            #(self, scan_param, minim, maxim, steps, unit)
    scannable_params = {
        #'Spectrum.carrier_detuning':  [(-50, 50, 100, 'kHz'), 'window']
        'Spectrum.carrier_detuning' : [(-150, 150, 10, 'kHz'),'spectrum',True],
        'Spectrum.sideband_detuning' :[(-50, 50, 100, 'kHz'),'spectrum',True]
              }

    show_params= ['Excitation_729.channel_729',
                  'Excitation_729.bichro',
                  'Spectrum.manual_amplitude_729',
                  'Spectrum.manual_excitation_time',
                  'Spectrum.line_selection',
                  'Spectrum.selection_sideband',
                  'Spectrum.order',
                  'Display.relative_frequencies',
                  'StatePreparation.channel_729',
                  'StatePreparation.optical_pumping_enable',
                  'StatePreparation.sideband_cooling_enable'
                  ]
   
    fixed_params = {
    # 'StatePreparation.aux_optical_pumping_enable': False,
#                     'StatePreparation.sideband_cooling_enable': False,
                    # 'StateReadout.readout_mode': 'pmt',
                    }
    
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
           
        ## calculate the scan params
        spc = self.parameters.Spectrum   
        
        if spc.order == 0.0: #spc.selection_sideband == "off":         
            freq_729 = self.calc_freq(spc.line_selection)
        else:
            print "running a sideban in spectrum"
            freq_729=self.calc_freq(spc.line_selection, spc.selection_sideband ,int(spc.order))

        freq_729=freq_729 + spc.carrier_detuning + spc.sideband_detuning
        
        amp=spc.manual_amplitude_729
        duration=spc.manual_excitation_time

        print "Spectrum scan ****************************************"
        print "spc.line_selection : " ,spc.line_selection
        print "spc.selection_sideband : " ,spc.selection_sideband   
        print "spc.order : " , int(spc.order)
        print "729 freq: {}".format(freq_729.inUnitsOf('MHz'))
        print "729 detuning: {}".format(freq_729-self.calc_freq(spc.line_selection))
        print "729 amp is {}".format(amp)
        print "729 duration is {}".format(duration)
                
        # building the sequence
        # needs a 10 micro sec for some reason
        self.end = U(10., 'us')
        self.addSequence(TurnOffAll)           
        self.addSequence(StatePreparation)      
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': amp,
                                         'Excitation_729.rabi_excitation_duration':  duration })
        self.addSequence(StateReadout)
        
    @classmethod
    def run_initial(cls,cxn, parameters_dict):

        print  'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'

        spectrum = parameters_dict.Spectrum
        ###### add shift for spectra purposes
        carrier_translation = {'S+1/2D-3/2':'c0',
                            'S-1/2D-5/2':'c1',
                            'S+1/2D-1/2':'c2',
                            'S-1/2D-3/2':'c3',
                            'S+1/2D+1/2':'c4',
                            'S-1/2D-1/2':'c5',
                            'S+1/2D+3/2':'c6',
                            'S-1/2D+1/2':'c7',
                            'S+1/2D+5/2':'c8',
                            'S-1/2D+3/2':'c9',
                               }

        trapfreq = parameters_dict.TrapFrequencies
        # sideband_frequencies = [trapfreq.radial_frequency_1, trapfreq.radial_frequency_2, trapfreq.axial_frequency, trapfreq.rf_drive_frequency]
        shift = U(0.,'MHz')
        
        if parameters_dict.Display.relative_frequencies:
            # shift by sideband only (spectrum "0" will be carrier frequency)
            shift += spectrum.order * trapfreq[spectrum.selection_sideband] 
            print shift

        else:
            #shift by sideband + carrier (spectrum "0" will be AO center frequency)
            shift += parameters_dict.Carriers[carrier_translation[spectrum.line_selection]]
            shift += spectrum.order * trapfreq[spectrum.selection_sideband] 

        # for order,sideband_frequency in zip([sb*spectrum.invert_sb for sb in spectrum.sideband_selection], sideband_frequencies):
        #         shift += order * sideband_frequency

        print 'shift is ', shift, '********************************************************************'
        
        pv = cxn.parametervault
        pv.set_parameter('Display', 'shift', shift)
    
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        pass


    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        pass

        
if __name__ == '__main__':
    import labrad
    cxn = labrad.connect()
    sc = cxn.scriptscanner
    #scan = [('ReferenceImage',   ('temp', 0, 1, 1, 'us'))]
    scan =[('Spectrum',   ('Spectrum.carrier_detuning', -150, 150, 10, 'kHz'))] 
    ident = sc.new_sequence('Spectrum', scan)
    sc.sequence_completed(ident)
    cxn.disconnect()