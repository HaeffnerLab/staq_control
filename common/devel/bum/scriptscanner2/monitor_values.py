from labrad.server import LabradServer, setting, Signal
from labrad.units import WithUnit
from twisted.internet.defer import inlineCallbacks, DeferredList, returnValue, waitForDeferred
from signals import Signals
from configuration import config
import scan_methods
from scheduler import scheduler
import sys

class MonitorValues(LabradServer):

    name = 'MonitorValues'
    
    @inlineCallbacks
    def initServer(self):

		self.pi_time=[]
		self.rsb_time=[]
		self.power_854=[]
		self.axial_freq=[]

	@setting(0, "Add Pi", returns = '')
	def addPi(self,x):
		self.pi_time=self.pi_time+[x]
		return self.pi_time

	def addRsb(self,x):
		self.rsb_time=self.rsb_time+[x]
		return self.rsb_time

	def add854(self,x):
		self.power_854=self.power_854+[x]
		return self.power_854

	def addAxial(self,x):
		self.axial_freq=self.axial_freq+[x]
		return self.axial_freq

	def clear_param(self):
		self.pi_time=[]
		self.rsb_time=[]
		self.power_854=[]
		self.axial_freq=[]


    @inlineCallbacks
    def stopServer(self):
        try:
            yield self.clear_param()
        except AttributeError:
            #if values don't exist yet, i.e stopServer was called due to an Identification Error
            pass

if __name__ == "__main__":
    from labrad import util
    util.runServer(MonitorValues())

