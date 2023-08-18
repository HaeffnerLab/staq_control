# Fitter class for Gaussians

from model import Model, ParameterInfo
import numpy as np

class parity(Model):

    def __init__(self):
        self.parameters = {
            'contrast':ParameterInfo('contrast', 0, lambda x,y: 0.5, vary=True),
            'phi0': ParameterInfo('phi0', 1, lambda x,y: 0, vary=True),
            'offset': ParameterInfo('offset', 2, lambda x,y: 0, vary=True),
            }

    def model(self, x, p):
        contrast = p[0]
        phi0 = p[1]
        offset = p[2]
        return contrast*np.sin(2*np.deg2rad(x)-phi0) + offset
