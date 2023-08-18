import labrad
import time
import numpy as np
import sys

# connect to local labrad
cxn = labrad.connect()
keysight = cxn.keysight_e3648a
cxn.pulser.switch_manual('PI', False)
keysight.power(False)
cxn.disconnect()
time.sleep(0.5)