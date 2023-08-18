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

#SERVERNAME = 'Marconi_2024_G2'
#SIGNALID = 190234 ## this needs to change


class Marconi_2024_G2(LabradServer):
    name = 'Marconi_2024_G2'
    instr = None
    
    def initServer(self):

        try:
            rm = visa.ResourceManager()
            dev_path = '/dev/ttyUSB2'#(rm.list_resources()[0])[4:16]
            self.dev=Serial(dev_path)
            print "Successfully connected" 

        except:
            print "Could not connect"

    def setFrequency(self,f):
        msg =str(':CFRQ:VALUE ')+str(f['Hz'])+str(';')
        self.dev.write(msg)

    def setAmplitude(self,f):
        msg = str(':RFLV:VALUE ')+str(f['dBm'])+str('DBM;')
        self.dev.write(msg)

    def setPhase(self,f):
        msg =str(':CFRQ:PHASE ')+str(f['deg'])+str(';')
        self.dev.write(msg)

    def setMod(self,f):
        if f:
            msg =str(':MODE FM;:FM:DEVN ')+str(f)+str('KHZ;INT;EXTDC;ON;')
            msg1 =str(':MOD:ON;')
        else:
            msg =str(':MOD:OFF;')
            msg1 =str(':FM:OFF;')
        self.dev.write(msg)
        self.dev.write(msg1)

    @setting(10, 'Frequency', f=['v[MHz]'], returns=['v[MHz]'])
    def frequency(self, c, f=None):
        """Get or set the CW frequency."""
        if f is not None:
            yield self.setFrequency(f)

        self.dev.frequency=f   
        returnValue(self.dev.frequency)

    @setting(11, 'Amplitude', a=['v[dBm]'], returns=['v[dBm]'])
    def amplitude(self, c, a=None):
        """Get or set the CW amplitude."""
        if a is not None:
            yield self.setAmplitude(a)
        self.dev.amplitude = a
        returnValue(self.dev.amplitude)


    @setting(12, 'Phase', p=['v[deg]'], returns=['v[deg]'])
    def phase(self, c, p=None):
        """Get or set the CW frequency."""
        if p is not None:
            yield self.setPhase(p)

        self.dev.phase=p   
        returnValue(self.dev.phase)

    @setting(13, 'Mod', p=['v'], returns=['v'])
    def mod(self, c, p=None):
        """Get or set the CW Modulation."""
        if p is not None:
            yield self.setMod(p)

        self.dev.mod=p   
        returnValue(self.dev.mod)

      
__server__ = Marconi_2024_G2()
        
if __name__ == '__main__':
    from labrad import util
    util.runServer(__server__)    