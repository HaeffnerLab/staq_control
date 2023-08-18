'''
### BEGIN NODE INFO
[info]
name = Agilent_33220A
version = 1.0
description =
instancename = Agilent_33220A

[startup]
cmdline = %PYTHON% %FILE%
timeout = 20

[shutdown]
message = 987654321
timeout = 20
### END NODE INFO
'''

#instancename = Agilent_33220A

from labrad.server import LabradServer, setting, inlineCallbacks
from twisted.internet.defer import DeferredLock, Deferred
from twisted.internet.defer import inlineCallbacks, returnValue
from labrad.units import WithUnit as U

import visa
import select
import numpy as np
import struct
from warnings import warn
import time

import collections
import os
import os.path
import sys
import time
from time import sleep

from labrad import types as T
from labrad.errors import Error

from twisted.internet import reactor, threads

from twisted.internet.task import deferLater
from serial import Serial
from serial.serialutil import SerialException
import serial.tools.list_ports

#SERVERNAME = 'Keysight_E3648A'
#SIGNALID = 190234 ## this needs to change


class Keysight_E3648A(LabradServer):
    name = 'Keysight_E3648A'
    instr = None
    
    def initServer(self):

        try:
            rm = visa.ResourceManager()
            #dev_path = '/dev/ttyUSB0'
            #self.dev=Serial(dev_path)
            self.dev= rm.open_resource('ASRL/dev/ttyUSB1::INSTR') #str(rm.list_resources()[0])
            print "Successfully connected" 

        except:
            print "Could not connect"

    def setPower(self,f):
        if f==True:
            msg =str('OUTPut ON')
        else:
            msg =str('OUTPut OFF')
        self.dev.write(msg)

    @setting(10, 'Power', p=['v'], returns=['v'])
    def power(self, c, p=None):
        """Set the oven on or off."""
        if p is not None:
            yield self.setPower(p)

        self.dev.power=p   
        returnValue(self.dev.power)

      
__server__ = Keysight_E3648A()
        
if __name__ == '__main__':
    from labrad import util
    util.runServer(__server__)    