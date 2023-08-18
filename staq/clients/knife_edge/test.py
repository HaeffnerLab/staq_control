from PyQt4 import QtGui
import matplotlib
from matplotlib.figure import Figure
from twisted.internet.defer import inlineCallbacks , returnValue
from twisted.internet.threads import deferToThread
import time


class test(QtGui.QWidget):
    def __init__(self,  cxn = None, parent=None):
        QtGui.QWidget.__init__(self, parent)
        # Initialize
        # self.reactor = reactor
        self.cxn = cxn
        self.power = 0
        from common.clients.connection import connection

        self.cxn = connection()
        # connection()
        self.connect_labrad()
        
        # print " measuring power"
        # # self.getpoweretParams()
        # print self.powerHead.getpower()
    
   
     
    @inlineCallbacks
    # Attempt to connect ot the pulser server 
    def connect_labrad(self):
        self.cxn = yield self.cxn.connect()           
        print "connection established"
        self.context = yield self.cxn.context()
        print self.context
        
        returnValue( self )

    @inlineCallbacks
    # Attempt to connect ot the pulser server 
    def Get_server(self):
        self.powerHead = yield self.cxn.get_server('parametervault')
        returnValue( self )

        
    @inlineCallbacks
    # Attempt to connect ot the pulser server 
    def getParams(self):
        print "inside function"
        self.power = yield self.powerHead.get_collections () #getpower()

        returnValue( self.power  )
            
    


    def closeEvent(self, x):
        self.reactor.stop()  
    
if __name__=="__main__":
    a = QtGui.QApplication( [] )
    from common.clients import qt4reactor
    qt4reactor.install()
    from twisted.internet import reactor
    widget = test(reactor)
    widget.show()
    reactor.run()
