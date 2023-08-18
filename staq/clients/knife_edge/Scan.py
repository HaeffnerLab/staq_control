from PyQt4 import QtGui, QtCore
import numpy as np



class SacnLayout(QtGui.QWidget):
    def __init__(self, reactor, parent=None, axis_name = 'axis 0'):

        super(SacnLayout, self).__init__(parent)
        self.reactor = reactor
        self.axis_name = axis_name
        self.setupLayout()
        self.connect()

    def connect(self):
        import labrad 
        print " connecting to labrad"
        cxn = labrad.connect()
        print " connected to labrad"
        cxn.disconnect()    
        
    
    def setupLayout(self):
        hbox = QtGui.QHBoxLayout()

        self.checkEngine =QtGui.QCheckBox( self.axis_name) 

        self.LblStep = QtGui.QLabel('step')
        self.EngineStepSize =QtGui.QLineEdit()
        self.EngineStepSize.setValidator(QtGui.QDoubleValidator())
        self.EngineStepSize.setText(str(0.5))
        
        self.LblMin = QtGui.QLabel('from ')
        self.EngineMin = QtGui.QLineEdit()
        self.EngineMin.setValidator(QtGui.QDoubleValidator())
        self.EngineMin.setText(str(0))

        self.LblMax = QtGui.QLabel(' mm ')
        self.EngineMax = QtGui.QLineEdit()
        self.EngineMax.setValidator(QtGui.QDoubleValidator())
        self.EngineMax.setText(str(1))

        hbox.addWidget(self.checkEngine)
        hbox.addWidget(self.LblMin)
        hbox.addWidget(self.EngineMin)
        hbox.addWidget(self.LblStep)
        hbox.addWidget(self.EngineStepSize)
        hbox.addWidget(self.EngineMax)
        hbox.addWidget(self.LblMax)

        self.setLayout(hbox)
        self.EngineMin.editingFinished.connect(self.editMin)


    def editMin(self ):
        Xmin = float(self.EngineMin.text())
        Xmax = float(self.EngineMax.text())
        step = float(self.EngineStepSize.text())
        if Xmin > Xmax:
            self.EngineMin.setText(str(Xmax-step))
        # print Xmin , Xmax  , step


      



if __name__=="__main__":
    #join Qt and twisted event loops
    a = QtGui.QApplication( [] )
    import qt4reactor
    qt4reactor.install()

    from twisted.internet import reactor
    # widget = AxisDisplay(reactor)
    widget = SacnLayout(reactor)
    widget.show()
    reactor.run()
