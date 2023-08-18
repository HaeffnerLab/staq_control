from model import Model, ParameterInfo
import numpy as np

class SinusoidSquared(Model):

    def __init__(self):
        self.parameters = {
            'contrast': ParameterInfo('contrast', 0, self.guess_contrast,vary=False),
            'freq': ParameterInfo('freq', 1, lambda x,y: 0.03, vary=True),
            'phi': ParameterInfo('phi', 2, lambda x,y: 0, vary=False),
            'offset': ParameterInfo('offset', 3, lambda x,y: 0, vary=False),
            't0': ParameterInfo('t0', 4, lambda x,y: 0., vary=True),
            }

    def model(self, t, p):
        contrast = p[0]
        freq = p[1]
        phi = p[2]
        offset = p[2]
        t0 = p[2]

        return offset + contrast*np.sin(2*np.pi*freq*(t-t0) + phi)**2

    def guess_contrast(self, x, y):
        '''
        Take the first time the flop goes above the average excitation of the whole scan
        to be pi/4
        '''
        
        if max(y)<.9:
            return max(y)
        else:
            return 1.