# Fitter class for linear fits

from model import Model, ParameterInfo
import numpy as np

class Parabola(Model):

    def __init__(self):
        self.parameters = {
            'a':ParameterInfo('a', 0, self.guess_a),
            'b':ParameterInfo('b', 1, self.guess_b),
            'c':ParameterInfo('c', 2, self.guess_c),
            }

    def model(self, x, p):
        a = p[0]
        b = p[1]
        c = p[2]
        return a*(x-b)**2 + c

    def center_index(self, x, y): 
        if y[0] > min(y): 
            return np.argmin(y) 
        else: 
            return np.argmax(y)

    def guess_a(self, x, y):
        dx = x[self.center_index(x, y)] - x[0]
        dy = y[self.center_index(x, y)] - y[0]
        return dy/dx

    def guess_b(self, x, y):
        return x[self.center_index(x, y)]

    def guess_c(self, x, y):
        return y[self.center_index(x, y)]  
