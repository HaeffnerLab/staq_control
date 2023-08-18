from twisted.internet.defer import inlineCallbacks
from PyQt4 import QtGui
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_qt4agg import FigureCanvasQTAgg as FigureCanvas
import pickle
from numpy import linalg as LA


class Multipole_plot(QtGui.QWidget):
    def __init__(self, reactor, parent=None):
        super(Multipole_plot, self).__init__(parent)
        self.reactor = reactor
        self.setupLayout()
        self.connect()
        data_out = pickle.load( open( "MultipoleMatrix.p", "rb" ) )
        self.multipole_expansions = data_out['mat']
        self.name_dic =data_out['name_dic']
        
    
    def setupLayout(self):
        #setup the layout and make all the widgets
        self.setWindowTitle('Multipole calculation')
        #create a horizontal layout
        hbox = QtGui.QHBoxLayout()
        vbox = QtGui.QVBoxLayout()
        
        #buttons for submitting
        self.submit = QtGui.QPushButton('Calc ')


        self.textedit = QtGui.QTextEdit()
        self.textedit.setReadOnly(True)
        #add all the button to the layout
        self.lbl = QtGui.QLabel()
        self.lbl.setText(" RF voltage (amp)")
        self.lineedit = QtGui.QLineEdit()
        self.lineedit.setText('100')

        vbox.addWidget(self.submit)
        vbox.addWidget(self.lbl)
        vbox.addWidget(self.lineedit)
        hbox.addLayout(vbox)
        hbox.addWidget(self.textedit)
        

        #Canvas and Toolbar
        self.figure = plt.figure(figsize=(7.5,5))    
        self.canvas = FigureCanvas(self.figure)     
        hbox.addWidget(self.canvas)
        self.setLayout(hbox)
        
    @inlineCallbacks
    def connect(self):
        #make an asynchronous connection to LabRAD
        from labrad.wrappers import connectAsync
        from labrad.errors import Error
        self.Error = Error
        cxn = yield connectAsync()
        self.dac = cxn.dac_server
        self.registry = cxn.registry
        self.submit.pressed.connect(self.on_submit)
        
    
    @inlineCallbacks
    def on_submit(self):
        '''
        when the submit button is pressed, submit the value to the registry
        '''
        Vdac = yield self.dac.get_analog_voltages()
        Vcalc = np.zeros(len(Vdac))
        self.textedit.setText('')
        for i  in range(len(Vdac)):
            Vcalc[self.name_dic[Vdac[i][0]]]=Vdac[i][1]
            text =Vdac[i][0] +  ':   {:2.3f} Volt'.format(Vdac[i][1]) 
            self.textedit.append(text)
        
        # ploting on the canvas
        plt.cla()

        self.multipule_names = ['c', 
                  'Ez', '-Ex', '-Ey', 
                  r'$U2 = z^2-(x^2+y^2)/2$', 'U5 = -6zx', 'U4 = -6yz', r'$U1 = 6(x^2-y^2)$', 'U3= 12xy' ]
        self.mulipole_projection =  np.dot(self.multipole_expansions,Vcalc)
        y_pos =range(len(self.mulipole_projection ))
        ax = self.figure.add_subplot(111)
        plt.bar(y_pos,self.mulipole_projection)
        plt.grid(which ='both')
    #     plt.ylim(-1,1)
        plt.xticks(y_pos, self.multipule_names)
        plt.title('dc decomposition')
        ax.tick_params(axis="x", labelsize=8, labelrotation=-45)
                      
    
        self.canvas.draw()
        self.calc_eigen_freq()

  

        
    def calc_eigen_freq(self):
        pi2= 2.0*np.pi
        q = 1.6021764e-19
        M = 1.67262158e-27 * 40
        Vrf = float(self.lineedit.text() )
        Omega_rf = pi2*45e6 #in Hz
        R=  140e-6
        # psuedo potential voltage
        uRF=q*Vrf**2/(M*Omega_rf**2*R**4)

        # adding a factor 10**6 to convert to v/m^2 units
        u2,u5,u4,u1,u3 = self.mulipole_projection[-5:]*10**6

        print u2,u5,u4,u1,u3
        uMat=0.5*np.array([
        [ 2*(6*u1-u2)+uRF,   12*u3,         -6*u5],
        [       12*u3,   -2*(6*u1+u2)+uRF,  -6*u4],
        [       -6*u5,       -6*u4,         4*u2]
        ])
        eigs,vectors = LA.eig(uMat)
        for eig, v  in zip(eigs,vectors):
            trap_f = np.sqrt(q/M*eig)/pi2*10**-6
            
            self.textedit.append(' ')
            self.textedit.append(' Frequency  {:3.3f} MHz'.format(trap_f))
            self.textedit.append(' ({:1.3f},{:1.3f},{:1.3f}) '.format(v[0],v[1],v[2]))
            self.textedit.append(' ')
            # print trap_f


    def closeEvent(self, x):
        #stop the reactor when closing the widget
        self.reactor.stop()

if __name__=="__main__":
    #join Qt and twisted event loops
    a = QtGui.QApplication( [] )
    import qt4reactor
    qt4reactor.install()
    from twisted.internet import reactor
    widget = Multipole_plot(reactor)
    widget.show()
    reactor.run()