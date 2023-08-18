class channelConfiguration(object):
    """
    Stores complete configuration for each of the channels
    """
    def __init__(self, channelNumber, ismanual, manualstate,  manualinversion, autoinversion):
        self.channelnumber = channelNumber
        self.ismanual = ismanual
        self.manualstate = manualstate
        self.manualinv = manualinversion
        self.autoinv = autoinversion
        
class ddsConfiguration(object):
    """
    Stores complete configuration of each DDS board
    """
    def __init__(self, address, allowedfreqrange, allowedamplrange, frequency, amplitude, **args):
        self.channelnumber = address
        self.allowedfreqrange = allowedfreqrange
        self.allowedamplrange = allowedamplrange
        self.frequency = frequency
        self.amplitude = amplitude
        self.t1 = 4000
        self.t2 = 4000
        self.time_step = 4
        self.lattice_parameter = [4000,4000,4]
        self.state = True
        self.boardfreqrange = args.get('boardfreqrange', (0.0, 2000.0))
        self.boardramprange = args.get('boardramprange', (0.000113687, 107.4505806))
        self.board_amp_ramp_range = args.get('board_amp_ramp_range', (0.00174623, 500.8896))
        self.boardamplrange = args.get('boardamplrange', (-63.0, 17.0))
        self.boardphaserange = args.get('boardphaserange', (0.0, 360.0))
        self.off_parameters = args.get('off_parameters', (0.0, -63.0))
        self.phase_coherent_model = args.get('phase_coherent_model', True)        
        self.remote = args.get('remote', False)
        self.name = None #will get assigned automatically

class remoteChannel(object):
    def __init__(self, ip, server, **args):
        self.ip = ip
        self.server = server
        self.reset = args.get('reset', 'reset_dds')
        self.program = args.get('program', 'program_dds')
        
class hardwareConfiguration(object):
    channelTotal = 32
    timeResolution = '40.0e-9' #seconds
    timeResolvedResolution = 10.0e-9
    maxSwitches = 1022
    resetstepDuration = 2 #duration of advanceDDS and resetDDS TTL pulses in units of timesteps
    collectionTimeRange = (0.010, 5.0) #range for normal pmt counting
    sequenceTimeRange = (0.0, 85.0) #range for duration of pulse sequence    
    isProgrammed = False
    sequenceType = None #none for not programmed, can be 'one' or 'infinite'
    collectionMode = 'Normal' #default PMT mode
    collectionTime = {'Normal':0.100,'Differential':0.100} #default counting rates
    okDeviceID = 'Pulser2'
    okDeviceFile = 'photon_2015_7_13.bit'#'pulser_2013_06_05.bit'#'# #'pulser_riken_2015_03_17.bit' #
    lineTriggerLimits = (0, 15000)#values in microseconds 
    secondPMT = False
    DAC = False
    
    #name: (channelNumber, ismanual, manualstate,  manualinversion, autoinversion)
    channelDict = { #1 to 15 are optica ttls
                   'PI':channelConfiguration(1, False, True, False, True),
                   # '375':channelConfiguration(2, False, True, False, True),
                   '866DP':channelConfiguration(12, False, True, True, False),
                   '397Mod':channelConfiguration(13, False, True, False, False),
                   # 'bluePI':channelConfiguration(2, True, False, True, False),
                   # 'camera':channelConfiguration(5, False, False, True, True),
                   # 'coil_dir':channelConfiguration(6, False, False, True, True),
                   #------------INTERNAL CHANNEgiLS----------------------------------------#
                   'Internal866':channelConfiguration(0, False, False, False, False),
                   'DiffCountTrigger':channelConfiguration(16, False, False, False, False),
                   'TimeResolvedCount':channelConfiguration(17, False, False, False, False),
                   'AdvanceDDS':channelConfiguration(18, False, False, False, False),
                   'ResetDDS':channelConfiguration(19, False, False, False, False),
                   'ReadoutCount':channelConfiguration(20, False, False, False, False),
                }
    #address, allowedfreqrange, allowedamplrange, frequency, amplitude, **args):
    ddsDict =   {
                '866dp':ddsConfiguration(        0,  (70.0,100.0),    (-63.0,-5.0),   80.0,   -63.0),
                '854dp':ddsConfiguration(        1,  (70.0,90.0),    (-63.0,-5.0),   80.0,   -63.0),
                '397dp':ddsConfiguration(        2,  (70.0,300.0),    (-63.0,-5.0),   220.0,   -63.0),
                '729dp':ddsConfiguration(        4,  (70.0,400.0),    (-63.0,-12.0),   220.0,   -63.0),
                'gate1':ddsConfiguration(        5,  (70.0,100.0),    (-63.0,-14.0),   80.0,   -63.0),
                # channel 5 has a dds but a the moment isn't in use
                 'gate2':ddsConfiguration(        3,  (70.0,100.0),    (-63.0,-14.0),   80.0,   -63.0),
                
                
                # '6':ddsConfiguration(        6,  (70.0,300.0),    (-63.0,-5.0),   206.0,   -63.0),
                # '7':ddsConfiguration(        7,  (70.0,300.0),    (-63.0,-5.0),   206.0,   -63.0),
                

#                 'global397':ddsConfiguration(    1,  (70.0,100.0),   (-63.0,-12.0),  90.0,   -33.0),
#                 'radial':ddsConfiguration(       2,  (90.0,130.0),   (-63.0,-12.0),   110.0,  -63.0),
# #                  'radial':ddsConfiguration(       2,  (74.0,74.0),   (-63.0,-5.0),   74.0,  -63.0),
#                 '854DP':ddsConfiguration(        3,  (70.0,90.0),    (-63.0,-4.0),   80.0,   -33.0),
#                 '729DP':ddsConfiguration(        4,  (150.0,250.0),  (-63.0,-5.0),   220.0,  -33.0),
                }
    remoteChannels = {
                    }


    # while True:
    #     pulser.switch_manual('422', False)
    #     t.sleep(0.2)
    #     pulser.switch_manual('422', True)

