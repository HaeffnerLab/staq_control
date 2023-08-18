# Generic fitter class

import numpy as np
from scipy import optimize
from fit_lorentzian import Lorentzian
from fit_gaussian import Gaussian
from fit_linear import Linear
from fit_parabola import Parabola
from fit_rabi import Rabi
from fit_bessel import Bessel
from fit_rotrabi import RotRabi
from fit_rotramsey import RotRamsey
from fit_sinusoid import Sinusoid
from fit_sinusoid2 import Sinusoid2
from fit_sinusoidsquared import SinusoidSquared
from fit_expdecay import ExponentialDecay
from fit_gaussdecay import GaussianDecay
from fit_ramsey import RamseyDecay
from fit_ramseybfield import RamseyBfield
from fit_LSGPower import LSGPower
from fit_parity import parity

class FitWrapper():

    models = ['Lorentzian', 'Gaussian', 'Rabi', 'RotRabi', 'RotRamsey', 'Linear', 
    'Parabola', 'Bessel', 'Sinusoid', 'Sinusoid2', 'ExponentialDecay', 'GaussianDecay', 
    'RamseyDecay','RamseyBfield','LSGPower','parity', 'SinusoidSquared']

    def __init__(self, dataset, index):
        self.dataset = dataset
        self.index = index

    def setModel(self, model):

        model_dict = {
            'Lorentzian': Lorentzian,
            'Gaussian': Gaussian,
            'Linear': Linear,
            'Parabola': Parabola,
            'Rabi': Rabi,
            'RotRabi': RotRabi,
            'RotRamsey': RotRamsey,
	        'Bessel': Bessel,
            'Sinusoid': Sinusoid,
            'Sinusoid2': Sinusoid2,
            'SinusoidSquared': SinusoidSquared,
            'ExponentialDecay': ExponentialDecay,
            'GaussianDecay': GaussianDecay,
            'RamseyDecay': RamseyDecay,
            'RamseyBfield': RamseyBfield,
            'LSGPower': LSGPower, 
            'parity' : parity
            }
        self.model = model_dict[model]()

    def getParameters(self):
        '''
        Returns a list of params
        sorted in order of index
        '''
        params = self.model.parameters.keys()
        return sorted(params, key=lambda p: self.model.parameters[p].index)

    def getVary(self, p):
        return self.model.parameters[p].vary

    def getManualValue(self, p):
        try:
            return self.model.parameters[p].manual_value
        except: # value doesn't exist. Use automatic guess
            x = self.dataset.data[:,0]
            y = self.dataset.data[:,self.index+1]
            guess = self.model.guess_param(p, x, y)
            self.model.parameters[p].manual_value = guess
            return guess
            
    def getFittedValue(self, p):
        try:
            return self.model.parameters[p].fit_value
        except: # no fitted value exists yet
            return None

    def setManualValue(self, p, value):
        self.model.parameters[p].manual_value = value
        
    def setVary(self, p, value):
        assert (value is True) or (value is False)
        self.model.parameters[p].vary = value

    def setBounds(self, p, bounds): # EP
         self.model.parameters[p].bounds = bounds        

    def doFit(self):
        
        x = self.dataset.data[:,0]
        y = self.dataset.data[:, self.index + 1]
        
        def residual(p):
            return y -  self.model.reduced_model(x, p)

        varied_positions = self.model.varied_positions()
        fixed_positions = self.model.fixed_positions()
        x0 = [self.model.param_from_index(k).manual_value for k in varied_positions]
        bounds = [self.model.param_from_index(k).bounds for k in varied_positions] # EP 
        bounds = np.transpose(bounds)

        #print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', x0

        result = optimize.least_squares(residual, x0, bounds=(bounds[0], bounds[1]))
        result = result.x

        #result = optimize.leastsq(residual, x0)
        #result = result[0]

        # after the fit, assign the fitted values to the parameters
        # For the fixed parameters, set the fit_value = manual_value
        # so that we don't have to deal with it in the GUI display
        for pos, fit_val in zip(varied_positions, result):
            param = self.model.param_from_index(pos)
            param.fit_value = fit_val

        for pos in fixed_positions:
            param = self.model.param_from_index(pos)
            param.fit_value = param.manual_value
    
    #Not Great Fix.... see FitWindowWidget onClick
    def doFit_ls(self):
        
        x = self.dataset.data[:,0]
        y = self.dataset.data[:, self.index + 1]
        
        def residual(p):
            return y -  self.model.reduced_model(x, p)

        varied_positions = self.model.varied_positions()
        fixed_positions = self.model.fixed_positions()
        x0 = [self.model.param_from_index(k).manual_value for k in varied_positions]
        bounds = [self.model.param_from_index(k).bounds for k in varied_positions] # EP 
        bounds = np.transpose(bounds)

        #print 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', x0

        #result = optimize.least_squares(residual, x0, bounds=(bounds[0], bounds[1]))
        #result = result.x

        result = optimize.leastsq(residual, x0)
        result = result[0]

        # after the fit, assign the fitted values to the parameters
        # For the fixed parameters, set the fit_value = manual_value
        # so that we don't have to deal with it in the GUI display
        for pos, fit_val in zip(varied_positions, result):
            param = self.model.param_from_index(pos)
            param.fit_value = fit_val

        for pos in fixed_positions:
            param = self.model.param_from_index(pos)
            param.fit_value = param.manual_value

    def evaluateFittedParameters(self,a=0,b=-1):
        '''
        Evaluate the model on a fine grid
        Return 2-d numpy array data where
        data[:,0] = fine_grid
        data[:,1] = model evaluated on fitted parameters
        '''
        x = self.dataset.data[:,0]
        if a==-1:
            xmin = 0
        else:
            xmin = x[a]
        #n = len(x)
        #N = 10*n
        N = 100000
        xmax = x[b]
        fine_grid = np.linspace(xmin, xmax, N)

        p0 = []
        for p in self.getParameters():
            p0.append(self.getFittedValue(p))
        y = self.model.model(fine_grid, p0)
        
        data = np.zeros((N, 2))
        data[:,0] = fine_grid
        data[:,1] = y
        return data

    def evaluateManualParameters(self):
        '''
        Evaluate the model on a fine grid
        Return 2-d numpy array data where
        data[:,0] = fine_grid
        data[:,1] = model evaluated on manual parameters
        '''

        x = self.dataset.data[:,0]
        n = len(x)
        #N = 10*n
        N=int(1e5)
        xmin = x[0]; xmax = x[-1]
        fine_grid = np.linspace(xmin, xmax, N)

        p0 = []
        for p in self.getParameters():
            p0.append(self.getManualValue(p))
        y = self.model.model(fine_grid, p0)
        
        data = np.zeros((N, 2))
        data[:,0] = fine_grid
        data[:,1] = y
        return data
