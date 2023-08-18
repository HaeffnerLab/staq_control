'''
### BEGIN NODE INFO
[info]
name = Newport SMC100
version = 1.0
description =
instancename = Newport SMC100

[startup]
cmdline = %PYTHON% %FILE%
timeout = 20

[shutdown]
message = 987654321
timeout = 20
### END NODE INFO
'''

#instancename = Newport SMC100

from labrad.server import LabradServer, setting, inlineCallbacks
from twisted.internet.defer import DeferredLock, Deferred
from twisted.internet.defer import inlineCallbacks, returnValue
from labrad.units import WithUnit as U

from serial.tools.list_ports import comports
# import pyvisa as visa
import select
import numpy as np
import struct
from warnings import warn
import time
from smc100 import smc100




#SERVERNAME = 'Newport SMC100'
#SIGNALID = 390234 ## this needs to change


class NewportSMC100(LabradServer):
    name = 'NewportSMC100'
    
    def initServer(self):
                
        serial_ports = [(x[0], x[1], dict(y.split('=', 1) for y in x[2].split(' ') if '=' in y)) for x in comports()]
        port0 =serial_ports[0][0]
        port1 =serial_ports[1][0]
        print" this is the horizontal port" , port0
        print" this is the vertical port" , port1
        self.mot=[]
        try:
            self.mot.append(smc100(COM=port0))
            print "Successfully connected to the horizontal motor "  
            print "Device is ", self.mot[0].send_rcv('01ID?')

            self.mot.append(smc100(COM=port1))
            print "Successfully connected vertical motor" 
            print "Device is ", self.mot[1].send_rcv('01ID?')

            print self.mot
        except:
            print "Could not connect"
        
    
    
    def setAbsPosition(self,pos , axis = 0):
        
        self.mot[axis].get_position(1)
        print " moving to abs location :, " , pos['mm']
        self.mot[axis].move_absolute(1, pos['mm'])
    
    def setRelativePos(self,pos, axis = 0):
        print " moving to abs location :, " , pos['mm'] + self.mot[axis].state.positions[0]
        self.mot[axis].move_relative(1, pos['mm'])

    def killMotor(self):
        self.mot[0].kill()
        self.mot[1].kill()

    @setting(10, 'Position', axis = 'i',  pos=['v[mm]'], returns=['v[mm]'])
    def position(self, c, axis = 0, pos=None):
        """Move relative and retrun the last location"""
        if pos is not None:
            yield self.setAbsPosition(pos, axis=axis)
        
        # return the last location
        self.mot[axis].get_position(1)
        print "this is the position",self.mot[axis].state.positions[0]
        returnValue(U(float(self.mot[axis].state.positions[0]),'mm')) 

    @setting(11, 'Move Relative', axis = 'i', pos=['v[mm]'], returns=['v[mm]'])
    def moverRelative(self, c,axis = 0, pos=None):
        """Move relative and retrun the last location"""
        if pos is not None:
            yield self.setRelativePos(pos, axis=axis)
        
        # return the last location
        self.mot[axis].get_position(1)
        returnValue(U(self.mot[axis].state.positions[0],'mm')) 

    @inlineCallbacks
    def stopServer(self):
        '''
        stop all the running sequence and exit
        '''
        yield None
        try:
            #cancel all scheduled sequences
            yield self.killMotor()
        except AttributeError:
            #if dictionary doesn't exist yet (i.e bad identification error), do nothing
            pass




                       

        
__server__ = NewportSMC100()
        
if __name__ == '__main__':
    from labrad import util
    util.runServer(__server__)    