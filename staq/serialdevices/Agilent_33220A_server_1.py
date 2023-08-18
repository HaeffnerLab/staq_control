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

#SERVERNAME = 'Agilent_33220A'
#SIGNALID = 190234 ## this needs to change


class Agilent_33220A(LabradServer):
    name = 'Agilent_33220A'
    instr = None
    
    def initServer(self):
        
        
        

        try:
            rm = visa.ResourceManager()
            self.dev = rm.open_resource(rm.list_resources()[0])
            print "Successfully connected" 
            print "Device is", self.dev.query('*IDN?')

        except:
            print "Could not connect"
        
        #initialize off
        self.dev.write('OUTPut OFF')
        self.dev.output = False
        self.dev.write('FUNCtion Square')
        self.dev.frequency=U(float(self.dev.query('FREQuency?'))*10**-6,'MHz') 
        # setting the amplitude units to dBm
        self.dev.write('VOLTage:UNIT DBM')
        # self.lock = DeferredLock()
        self.set_TTL()

    def setOutput(self,os):
        if os:
            self.dev.write('OUTPut ON')
        else:
            self.dev.write('OUTPut OFF')

    def setFrequency(self,f):
        msg = 'FREQuency '+str(f['Hz'])
        self.dev.write(msg)

    def setAmplitude(self,f):
        msg = 'VOLTage '+str(f['dBm'])
        self.dev.write(msg)
    
    def set_TTL(self):
        """setting the voltage to be TTL"""
        self.dev.write('VOLTage:UNIT VPP')
        self.dev.write('VOLTage 2.5')
        self.dev.write('VOLTage:OFFSet 1.25')


    @setting(0, 'output',  os = ['b'], returns = ['b'])
    def output_state(self, c,  os=None):
        ''' get or set the output state'''
        if os is not None:
            yield self.setOutput(os)
        
        self.dev.output = bool(int(self.dev.query('OUTPut?')))
        returnValue(self.dev.output)

    @setting(10, 'Frequency', f=['v[MHz]'], returns=['v[MHz]'])
    def frequency(self, c, f=None):
        """Get or set the CW frequency."""
        if f is not None:
            yield self.setFrequency(f)

        self.dev.frequency=U(float(self.dev.query('FREQuency?'))*10**-6,'MHz')   
        returnValue(self.dev.frequency)

    @setting(11, 'Amplitude', a=['v[dBm]'], returns=['v[dBm]'])
    def amplitude(self, c, a=None):
        """Get or set the CW amplitude."""
        if a is not None:
            yield self.setAmplitude(a)
        self.dev.amplitude = U(float(self.dev.query('Voltage?')),'dBm')
        returnValue(self.dev.amplitude)

    
    


        
        
        
__server__ = Agilent_33220A()
        
if __name__ == '__main__':
    from labrad import util
    util.runServer(__server__)    