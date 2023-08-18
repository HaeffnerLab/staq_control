from labrad.server import LabradServer, setting
from labrad.units import WithUnit
import numpy as np

class ParameterLogger(LabradServer):

    database = {}

    @setting(100, 'Get logged parameter names', returns = '*(s)')
    def getLoggedParameterNames(self, c):
        return self.database.keys() 


    @setting(101, 'Get logged parameter values', key = 's', returns = '?')
    def getLoggedParameterValues(self, c, key):
        return self.database[key]


    @setting(102, 'Clear logged parameter list', key = 's', returns = '')
    def clearLoggedParameterList(self, c, key):
        self.database[key] = []


    @setting(103, 'Add parameter to logger', key = 's', value= '?', returns = '')
    def addParameterToLogger(self, c, key, value):

        if self.isParameterValid(key, value): 
            if key not in self.database: 
                self.database[key] = []

            self.database[key].append(value)
            print 'Check *************************** ', key,': ', self.database[key]
        else:
            print 'Check *************************** ', key,': ', self.database[key]
            print 'value: ', value
            raise ValueError('Check lab conditions! The current fitted "' + key + '" deviates too much from previous values.')

    def isParameterValid(self, key, value):
        if key not in self.database:
            return True

        values = self.database[key]
        if len(values) <= 1:
            return True
        else:
            meanVal = np.mean(values)
            if value >= meanVal*.8 and value <= meanVal*1.2:
                return True
            else: 
                return False