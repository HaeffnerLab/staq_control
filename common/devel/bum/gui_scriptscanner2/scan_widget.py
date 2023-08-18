import sys
from tree_view.Controllers import ParametersEditor
from PyQt4 import QtCore, QtGui, uic

class ScanItem(QtGui.QWidget):

    """ Item for parameter scanning """
    def __init__(self, p, sequence_name, parent):
        super(ScanItem, self).__init__(parent)
        self.parent = parent
        parameter, minim, maxim, steps, unit = p
        self.parameter = parameter
        self.makeLayout(p, sequence_name)
        self.connect_layout()

    def makeLayout(self, p, sequence_name):
        parameter, minim, maxim, steps, unit = p
        self.unit = unit
        layout = QtGui.QHBoxLayout()

        self.select = QtGui.QCheckBox()
        layout.addWidget(self.select)
        label = QtGui.QLabel(parameter.split(".")[-1])
        layout.addWidget(label)
        
        self.minim = QtGui.QDoubleSpinBox()
        self.maxim = QtGui.QDoubleSpinBox()
        self.steps = QtGui.QDoubleSpinBox()
        
        # adding resolution to the params
        self.minim.setDecimals(4)
        self.maxim.setDecimals(4)
        self.steps.setDecimals(4)
        
        self.minim.setRange(-1e6, 1e6)
        self.maxim.setRange(-1e6, 1e6)
        self.steps.setRange(-1e6, 1e6)
        
        self.minim.setValue(minim)
        self.maxim.setValue(maxim)
        self.steps.setValue(steps) 
    
        layout.addWidget(self.minim)
        layout.addWidget(self.maxim)
        layout.addWidget(self.steps)
        unitLabel = QtGui.QLabel(unit)
        layout.addWidget(unitLabel)
        layout.addWidget( QtGui.QLabel(sequence_name))
        self.setLayout(layout)

    def select_checkbox(self): # EP
        print 'select_checkbox ', self.parameter  
        self.select.blockSignals(True)
        self.select.setChecked(True)
        self.select.blockSignals(False)
        self.checkbox_changed()

    def connect_layout(self):
        self.select.stateChanged.connect(self.checkbox_changed)
    
    def checkbox_changed(self):
        selection = self.select.isChecked()
        if selection: # this parameter is selected to scan
            self.parent.set_scan_parameter(self.parameter)
        else:
            self.parent.set_scan_none()

    def uncheck_no_signal(self):
        """
        We need to block signals from the checkbox
        so that when we uncheck a box it does not
        set the scan parameter to None via the
        connection to checkbox_changed()
        """
        print 'uncheck_no_signal!!'
        self.select.blockSignals(True)
        self.select.setChecked(False)
        self.select.blockSignals(False)

    def get_scan_settings(self):
        """
        Get the scan settings (min, max, steps, unit)
        from this ScanItem
        """
        mn = self.minim.value()
        mx = self.maxim.value()
        #steps = int(self.steps.value())
        steps = float(self.steps.value())
        return (mn, mx, steps, self.unit)

    def set_parameter_values(self, values): 
        # values: (min, max, steps)
        minim, maxim, steps = values
        print minim, maxim, steps 
        self.minim.setValue(minim)
        self.maxim.setValue(maxim)
        self.steps.setValue(steps) 


class sequence_widget(QtGui.QWidget):
    def __init__(self, params, checked, seq, single_seq = True):
        super(sequence_widget, self).__init__()
        self.parameters = {}
        self.scan_parameter = None
        self.sequence_name = seq # name of the sequence this sequence widget refers to
        self.makeLayout(params, checked, single_seq)

    def makeLayout(self, params, checked, single_seq = True):
        layout = QtGui.QVBoxLayout()
        # layout.setSizeConstraint(1)
        self.setLayout(layout)
        
        scroll = QtGui.QScrollArea(self)
        layout.addWidget(scroll)
        scroll.setWidgetResizable(True)
        scroll.setMaximumHeight(250)
        # scroll.setVerticalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOn)
        scrollContent = QtGui.QWidget(scroll)
        
        scrollLayout = QtGui.QVBoxLayout(scrollContent)
        scrollContent.setLayout(scrollLayout)
        for par, x, sequence_name in params:
            minim, maxim, steps, unit = x
            p = (par, minim, maxim, steps, unit)
            self.parameters[par] = ScanItem(p, sequence_name, self)
            layout.addWidget(self.parameters[par])
            scrollLayout.addWidget(self.parameters[par])
        scroll.setWidget(scrollContent)
        

        for check in checked:
            print 'checked', sequence_name, check
            if check[0] in self.parameters: 
                print 'calling select checkbox for ', check[0]
                self.parameters[check[0]].select_checkbox()
        
#         layout = QtGui.QVBoxLayout()      
#         for par, x, sequence_name in params:
#             minim, maxim, steps, unit = x
#             p = (par, minim, maxim, steps, unit)
#             self.parameters[par] = ScanItem(p, sequence_name, self)
#             layout.addWidget(self.parameters[par])
#         self.setLayout(layout)

    def set_scan_parameter(self, parameter):
        """
        Set the scan parameter and uncheck
        all of the other options in the GUI
        """
        self.scan_parameter = parameter
        for par in self.parameters.keys():
            if par != parameter:
                self.parameters[par].uncheck_no_signal()

    def set_scan_none(self):
        self.scan_parameter = None

    def get_scan_parameter(self):
        return self.scan_parameter
    
    def get_sequence_name(self):
        return self.sequence_name
    
    def get_scan_settings(self, scan):
        return self.parameters[scan].get_scan_settings()

    def set_scan_parameter_values(self, parameter, values):
        # values: (min, max, steps)
        self.parameters[parameter].set_parameter_values(values)



    
class multi_sequence_widget(QtGui.QWidget):
    def __init__(self, widgets):
        super(multi_sequence_widget, self).__init__()
        layout = QtGui.QVBoxLayout()
        self.setLayout(layout)
        
        scroll = QtGui.QScrollArea(self)
        layout.addWidget(scroll)
        scroll.setWidgetResizable(True)
        scroll.setMinimumHeight(100)
        scroll.setMaximumHeight(250)
        # scroll.setVerticalScrollBarPolicy(QtCore.Qt.ScrollBarAlwaysOn)
        scrollContent = QtGui.QWidget(scroll)
        scrollLayout = QtGui.QVBoxLayout(scrollContent)
        scrollContent.setLayout(scrollLayout)
        self.widgets = widgets
        for widget in widgets:
            layout.addWidget(widget)
            scrollLayout.addWidget(widget)
        scroll.setWidget(scrollContent)
        
    def get_scan_parameter(self):
        return [(w.get_sequence_name(), w.get_scan_parameter()) for w in self.widgets]
    
    def get_scan_settings(self, sequence_name, scan_parameter):
        for w in self.widgets:
            if w.sequence_name == sequence_name:
                return w.get_scan_settings(scan_parameter)
        raise Exception('sequence name not found')

    def set_parameter_values(self, sequence_name, parameter, values):
        for w in self.widgets: 
            if w.sequence_name == sequence_name:
                return w.set_scan_parameter_values(parameter, values)
        raise Exception('Sequence name not found') 
        
    
class scan_box(QtGui.QStackedWidget):
    def __init__(self):
        super(scan_box, self).__init__()
        
class scan_widget(QtGui.QWidget):

    def __init__(self, reactor, parent):
        super(scan_widget, self).__init__()
        self.parent = parent
        self.scan_box = scan_box()
        self.reactor = reactor
        self.PreferredParameters = ParametersEditor(self.reactor)
        self.setupLayout()
        self.widgets = {} # dictionary of widgets to show
        self.preferreds = {}

    def setupLayout(self):
        layout = QtGui.QVBoxLayout()
        layout.addWidget(self.scan_box)
        layout.addWidget(self.PreferredParameters)
        self.setLayout(layout)
        
    def buildSequenceWidget(self, experiment, params, checked):
        '''
        params = [(par, ( min, max, steps, unit), sequence)]
        checked = [(par, sequence)]
        '''

        print experiment
        print checked

        sequences = list(set([p[2] for p in params])) # individual sequences
        sequences_dict = {}
        
        if len(sequences) == 1:
            seq = sequences[0]
            sequence_params = [x for x in params if x[2] == seq]
            sequence_checked = [x for x in checked if x[1] == seq]
            sequences_dict[seq] = sequence_widget(sequence_params, sequence_checked, seq, single_seq=True)
        
        else:
            for seq in sequences[::-1]:
                sequence_params = [x for x in params if x[2] == seq]
                sequence_checked = [x for x in checked if x[1] == seq]
                sequences_dict[seq] = sequence_widget(sequence_params, sequence_checked, seq, single_seq=False)
        
        multi = multi_sequence_widget(sequences_dict.values())
        
        #self.scan_box.addWidget(sw)
        #self.widgets[experiment] = sw
        self.scan_box.addWidget(multi)
        self.widgets[experiment] = multi
        self.widgets[experiment].setVisible(False)
        # self.show_none()

        self.preferreds[experiment] = [x[0].split('.') for x in params]

        #self.setCurrentWidget(sw)

    def set_preferred_parameters(self, experiment, params, global_params):       
        self.preferreds[experiment].extend([x.split('.') for x in params])
        self.preferreds[experiment].extend([x.split('.') for x in global_params])
        #self.preferreds[experiment].extend(['AO_calibration','delay_time'])

    def get_scan_settings(self, experiment):
        """
        Return the scan settings (parameter to scan, min, max, steps, unit)
        or None for the requested sequence
        """
        scan_parameter_list = self.widgets[experiment].get_scan_parameter() # [(seq name, scan parameter)]
        
        settings_list = []
        for sequence_name, scan_parameter in scan_parameter_list:
            if scan_parameter is None:
                settings_list.append((sequence_name, None))
            else:
                #mn, mx, steps, unit = self.widgets[experiment].parameters[scan_parameter].get_scan_settings()
                mn, mx, steps, unit = self.widgets[experiment].get_scan_settings(sequence_name, scan_parameter)
                settings_list.append(( sequence_name, (scan_parameter, mn, mx, float(steps), unit) ))
        return settings_list # settings_list = [(seq name, ( param,  min, max, steps, unit)]
        

    def select(self, experiment):
        '''
        Select experiment to show
        '''
        try:
            self.scan_box.setCurrentWidget(self.widgets[experiment])
            self.widgets[experiment].setVisible(True)
            self.PreferredParameters.show_only(self.preferreds[experiment])
        except KeyError: # no experiment selected
            self.show_none()


    def show_none(self):
        for exp in self.widgets.keys():
            self.widgets[exp].setVisible(False)


    def set_parameter_values(self, experiment, sequence_name, parameter, values):
        self.widgets[experiment].set_parameter_values(sequence_name, parameter, values)


if __name__ == "__main__":
    app = QtGui.QApplication(sys.argv)
    params = [(0, 6, 2, 'kHz'), ('p2', 0, 8, 2, 'us')]
    #icon = sequence_widget(params)
    icon = scan_widget(None, None)
    icon.buildSequenceWidget('exp', params)
    icon.show()
    app.exec_()
