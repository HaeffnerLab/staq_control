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


def calcVolt(phi):
    # coeff are found using polyfit from finding phi's when varying voltages and fitting volt vs phi
    coef=np.array([-1.41297727e-15,  1.92001383e-12, -1.12977500e-09,  3.79069620e-07,-7.86001940e-05,  1.56037980e-02,  6.62680574e-03])
    func=np.poly1d(coef)
    return func(phi)

class Agilent_33220A(LabradServer):
    name = 'Agilent_33220A'
    instr = None
    
    def initServer(self):    

        try:
            rm = visa.ResourceManager()
            self.dev = rm.open_resource(rm.list_resources()[-1])
            print "Successfully connected" 
            #print "Device is", self.dev.query('*IDN?') Doesnt work and hangs comm...

        except:
            print "Could not connect"
        
        #initialize off
        self.dev.write('OUTPut OFF')
        self.dev.output=False
        # setting to DC and the amplitude units to Vpp
        self.dev.write('FUNCtion DC')
        self.dev.write('VOLTage:UNIT VPP')

    def setOutput(self,os):
        if os:
            self.dev.write('OUTPut ON')
        else:
            self.dev.write('OUTPut OFF')

    def setAmplitude(self,f):
        a=calcVolt(f['deg'])
        msg = 'VOLTage:OFFSet '+str(a)
        self.dev.write(msg)

    @setting(0, 'Output',  os = ['b'], returns = ['b'])
    def output(self, c,  os=None):
        ''' get or set the output state'''
        if os is not None:
            yield self.setOutput(os)
        
        self.dev.output = bool(int(self.dev.query('OUTPut?')))
        returnValue(self.dev.output)

    @setting(11, 'Amplitude', a=['v[deg]'], returns=['v[V]'])
    def amplitude(self, c, a=None):
        """Get or set the CW amplitude."""
        if a is not None:
            yield self.setAmplitude(a)
        self.dev.amplitude = U(float(self.dev.query('VOLTage:OFFSet?')),'V')
        returnValue(self.dev.amplitude)

    
    


        
        
        
__server__ = Agilent_33220A()
        
if __name__ == '__main__':
    from labrad import util
    util.runServer(__server__)    