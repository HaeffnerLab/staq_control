# Fitter class for linear fits

from model import Model, ParameterInfo
import numpy as np

class LSGPower(Model):

    def __init__(self):
        self.parameters = {
            'frequency':ParameterInfo('frequency', 0, lambda x,y: 1),
            'constrast':ParameterInfo('constrast', 1, lambda x,y: .5),
            'x0':ParameterInfo('offset', 2, lambda x,y: -20),
            'offset':ParameterInfo('offset', 3, lambda x,y: 0.5,vary=False),
            'phase':ParameterInfo('phase', 4, self.guess_phase),
            'tau':ParameterInfo('tau', 5, lambda x,y: 100.),
            }

    def model(self, x, p):
        frequency = p[0]
        contrast = p[1]
        x0 = p[2]
        offset = p[3]
        phase = p[4]
        tau = p[5]
        return contrast * np.sin(frequency*1e-3*(x-x0)**2 + np.pi*phase/180.0) * np.exp(-(x-x0)/tau) + offset


    def guess_phase(self, x, y):
        if y[0] > 0.4:
            return 90
        return -90