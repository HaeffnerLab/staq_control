import numpy as np
from common.devel.bum.sequences.pulse_sequence import pulse_sequence
from labrad.units import WithUnit as U
from treedict import TreeDict
from Spectrum import Spectrum

class rsb(Spectrum):

	scannable_params = {'Spectrum.sideband_detuning' :[(-10, 10, 1, 'kHz'),'hr_rsb',True]}
	checked_params = ['Spectrum.sideband_detuning']

	@classmethod
	def run_finally(cls, cxn, parameter_dict, data, data_x):
		data = data.sum(1)
		# peak_guess =  cls.peak_guess(data_x, data)[0]
		# print "@@@@@@@@@@@@@@", peak_guess
		print data_x
		print data
		fit_params = cls.gaussian_fit(data_x, data, return_all_params = True)
		# print "red sideband"
		# print "############## fit params: ", fit_params
		# print "Amplitude: ", fit_params[1]
		return fit_params[1]

class bsb(Spectrum):

	scannable_params = {'Spectrum.sideband_detuning' :[(-10, 10, 1, 'kHz'),'hr_bsb',True]}
	checked_params = ['Spectrum.sideband_detuning']

	@classmethod
	def run_finally(cls, cxn, parameter_dict, data, data_x):
		data = data.sum(1)
		# peak_guess =  cls.peak_guess(data_x, data)[0]
		# print "@@@@@@@@@@@@@@", peak_guess
		print data_x
		print data
		fit_params = cls.gaussian_fit(data_x, data, return_all_params = True)
		# print "blue sideband"
		# print "############## fit params: ", fit_params
		# print "Amplitude: ", fit_params[1]
		return fit_params[1]

class Temperature(pulse_sequence):

	sequence = [(rsb, {'Spectrum.order':-1.0}), (bsb, {'Spectrum.order': 1.0})]

	@classmethod
	def run_finally(cls, cxn, parameter_dict, amp, seq_name):
		try:
			R = 1.0 * amp[0] / amp[1]
			print 'nbar:  ', 1.0*R/(1.0-1.0*R)
			return R / (1.0 - R)
		except:
			pass

class Heating_Rate(pulse_sequence):

	scannable_params = {'Heating.background_heating_time': [(0., 5000., 100., 'us'), 'nbar']}
	checked_params = ['Heating.background_heating_time']

	sequence = Temperature