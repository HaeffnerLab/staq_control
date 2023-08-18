'''
### BEGIN NODE INFO
[info]
name = Thorlabs_power_meter
version = 1.0
description =
instancename = Thorlabs_power_meter

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

import pyvisa as visa
import select
import numpy as np
import struct
from warnings import warn
import time
from ThorlabsPM100 import ThorlabsPM100


# use the following module https://pypi.org/project/ThorlabsPM100/
# https://www.thorlabs.com/drawings/fb0cf20ad14783b6-82A33CF7-0D48-E216-DDAF9657A3D2459F/PM100A-Manual.pdf

#SERVERNAME = 'Thorlabs'
#SIGNALID = 290234 ## this needs to change


class Thorlabs_power_meter(LabradServer):
    name = 'Thorlabs power meter'
    instr = None
    
    def initServer(self):
                
        rm = visa.ResourceManager()
        print rm.list_resources()[0]
        try:
            address = rm.list_resources()[0]
            # you need timeout>1 to avoid any false reading and writing of parameters
            inst =  rm.open_resource( address, timeout=10) 
            self.dev = ThorlabsPM100(inst=inst)
            print "Successfully connected" 
            print "Device is", self.dev.system.sensor.idn

        except:
            print "Could not connect"
        
    
 

    def setWavelength(self,lam):
        self.dev.sense.correction.wavelength = lam['nm']


    def setMaxPower(self,Max_power):
        # this would adjust the range such that this maximum power is withing the range
        self.dev.sense.power.dc.range.upper = Max_power['W']
        

    @setting(10, 'getPower' , returns=['v'])
    def getPower(self,c):
        return self.dev.read  


    @setting(11, 'Wavelength', lam=['v[nm]'], returns=['v[nm]'])
    def wavelength(self, c, lam=None):
        """Get or set or set the working wavelength"""
        if lam is not None:
            yield self.setWavelength(lam)
        else: 
            self.dev.sense.correction.wavelength   

        returnValue(U(self.dev.sense.correction.wavelength,'nm'))

    @setting(12, 'Power Range', Max_power=['v[mW]'], returns=['v[mW]'])
    def PowerRange(self, c, Max_power=None):
        """Get or set or set the max power detectable"""
        if Max_power is not None:
            yield self.setMaxPower(Max_power)
        
        returnValue(U(self.dev.sense.power.dc.range.upper*1.0e3 ,'mW'))

    
    
               

        
__server__ = Thorlabs_power_meter()
        
if __name__ == '__main__':
    from labrad import util
    util.runServer(__server__)    