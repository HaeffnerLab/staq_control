from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
import time

class point(pulse_sequence):
    
    
    scannable_params = {
        'MicromotionCalibration.point' : [(1., 1., 1., ''),'current'],
              }

    show_params= ['MicromotionCalibration.multipole_to_calibrate',
                    'MicromotionCalibration.carrier_time',
                    'MicromotionCalibration.sideband_time',
                    'RabiFlopping.rabi_amplitude_729',
                    'RabiFlopping.line_selection',
                    'RabiFlopping.sideband_selection',

                        ] 
                  
   
    def sequence(self):
        
        from StatePreparation import StatePreparation
        from subsequences.RabiExcitation import RabiExcitation
        from subsequences.StateReadout import StateReadout
        from subsequences.TurnOffAll import TurnOffAll
           
        ## calculate the scan params
        rf = self.parameters.RabiFlopping
        mc = self.parameters.MicromotionCalibration   
        # print(e.line_selection)
        # print(e.sideband_selection)
        freq_729=self.calc_freq(rf.line_selection , rf.selection_sideband , rf.order)

                
        # building the sequence
        # needs a 10 micro sec for some reason
        self.end = U(10., 'us')

        self.addSequence(TurnOffAll)           
        self.addSequence(StatePreparation)      
        self.addSequence(RabiExcitation,{'Excitation_729.rabi_excitation_frequency': freq_729,
                                         'Excitation_729.rabi_excitation_amplitude': rf.rabi_amplitude_729,
                                         'Excitation_729.rabi_excitation_duration':  rf.duration })
        self.addSequence(StateReadout)
 


class carrier(point):

    pass

class micromotion_sideband_1(point):

    pass

class micromotion_sideband_2(point):

    pass

class Scan3points(pulse_sequence):

    sequence = [(carrier, {'RabiFlopping.order':0,
                            'RabiFlopping.duration':'MicromotionCalibration.carrier_time'}), 
                (micromotion_sideband_1, {'RabiFlopping.order':1,
                            'RabiFlopping.duration':'MicromotionCalibration.sideband_time'}),
                (micromotion_sideband_2, {'RabiFlopping.order':2,
                            'RabiFlopping.duration':'MicromotionCalibration.sideband_time'}), ## picks the same time for 2nd order sideband
                ]
        
    @classmethod
    def run_in_loop(cls,cxn, parameters_dict, data, x):
        dac = cxn.dac_server
        multipoles_current = dac.get_multipole_values()
        multipoles_new = multipoles_current
        multipole_to_calibrate = parameters_dict.MicromotionCalibration.multipole_to_calibrate
        scan_value = parameters_dict.MicromotionCalibration.multipole_value

        for i in range(len(multipoles_current)):
            if multipoles_current[i][0] == multipole_to_calibrate:
                multipoles_new[i] = (multipole_to_calibrate, scan_value['Vmm'])

        if dac.get_multipole_values() != multipoles_new:
            dac.set_multipole_values(multipoles_new)
            print "new multipole values:"
            print dac.get_multipole_values()
            time.sleep(1)
        
    
    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        # print data
        carrier = data[0][0][0][0]
        sideband1 = data[1][0][0][0]
        sideband2 = data[2][0][0][0]
        return carrier, sideband1, sideband2    



class ScanMicromotion(pulse_sequence):

    scannable_params = {
        'MicromotionCalibration.multipole_value' : [(-.02, .02, .002, 'Vmm'),'spectrum'],
              }

    sequence = Scan3points

    @classmethod
    def run_initial(cls,cxn, parameters_dict):
        dac = cxn.dac_server
        global multipoles_initial
        multipoles_initial = dac.get_multipole_values() 

    @classmethod
    def run_finally(cls,cxn, parameters_dict, data, x):
        dac = cxn.dac_server
        dac.set_multipole_values(multipoles_initial)