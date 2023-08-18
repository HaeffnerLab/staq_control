from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import numpy as np

class Excitation729(pulse_sequence):
    scannable_params = {
        'DopplerCooling.doppler_cooling_frequency_397':  [(180., 210., .5, 'MHz'), 'calib_doppler'],
        'DopplerCooling.doppler_cooling_amplitude_397':  [(-30., -15., .5, 'dBm'), 'other'],
        'DopplerCooling.doppler_cooling_frequency_866':  [(60., 90., .5, 'MHz'), 'calib_doppler'],
        'DopplerCooling.doppler_cooling_amplitude_866':  [(-20., -6., .5, 'dBm'), 'other'],
        'SidebandCooling.sideband_cooling_amplitude_854': [(-30.,-10., 1., 'dBm'), 'scan_854'],
        'RaboFlopping.duration':  [(0., 200., 10., 'us'), 'rabi'],
        'RabiFlopping.frequency729': [(-50., 50., 5., 'kHz'), 'spectrum',True],
              }

    show_params= [
                  'RabiFlopping.line_selection',
                  'RabiFlopping.rabi_amplitude_729',
                  'RabiFlopping.duration',
                  'RabiFlopping.selection_sideband',
                  'RabiFlopping.order',
                  'RabiFlopping.channel_729',
                  'RabiFlopping.stark_shift_729',
                  'EmptySequence.empty_sequence_duration',
                  ]


    def sequence(self):

      from subsequences.StatePreparation import StatePreparation
      from subsequences.EmptySequence import EmptySequence
      from subsequences.RabiExcitation import RabiExcitation
      from subsequences.StateReadout import StateReadout

      es = self.parameters.EmptySequence
      rf = self.parameters.RabiFlopping
  
      ## calculate the scan params
      if rf.frequency_selection == "auto":
        freq_729_pos = self.calc_freq(rf.line_selection, rf.selection_sideband, rf.order)
        freq_729 = freq_729_pos + rf.stark_shift_729 + rf.frequency729
        print "FREQUENCY 729 = {}".format(freq_729)
      elif rf.frequency_selection == "manual":
        freq_729 = rf.frequency729
      else:
        raise Exception ('Incorrect frequency selection type {0}'.format(e.frequency_selection))

      ## build the sequence
      self.addSequence(StatePreparation)
      self.addSequence(EmptySequence)
      self.addSequence(RabiExcitation,{  'Excitation_729.frequency729': freq_729,
                                         'Excitation_729.rabi_change_DDS': True})
      self.addSequence(EmptySequence,{'EmptySequence.empty_sequence_duration':es.empty_sequence_duration_readout})
      self.addSequence(StateReadout)  
        
    @classmethod
    def run_initial(cls,cxn, parameters_dict):

      rf = parameters_dict.RabiFlopping

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

      shift = U(0.,'MHz')
      if parameters_dict.Display.relative_frequencies:
        # shift by sideband only (spectrum "0" will be carrier frequency)
        shift += 1.0 * self.parameters.TrapFrequencies[sideband]*order
      else:
        #shift by sideband + carrier (spectrum "0" will be AO center frequency)
        shift += parameters_dict.Carriers[carrier_translation[e.line_selection]]
        shift += 1.0*self.parameters.TrapFrequencies[sideband]*order

      pv = cxn.parametervault
      pv.set_parameter('Display','shift',shift)

    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        pass

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
      pass
        