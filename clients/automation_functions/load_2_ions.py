import labrad
from labrad.units import WithUnit
import time
import numpy as np
import sys
from timeit import default_timer as timer

# connect to local labrad
cxn = labrad.connect()
keysight = cxn.keysight_e3648a

cxn.pulser.switch_manual('PI', True)
keysight.power(True)
time.sleep(1.0)

threshold =35

counts = 0.0
start = timer()
end=start
while counts < threshold and (end-start)<60*20:  
    # get PMT counts
    counts = cxn.normalpmtflow.get_next_counts('ON', 1, True)
    
    end = timer()
    
    # switch off blue PI, if above threshold
    if counts >= threshold or (end-start)>=60*20:
        cxn.pulser.switch_manual('PI', False)
        keysight.power(False)
        #cxn.pulser.amplitude('397dp', WithUnit(-16.0,'dBm'))
        # cxn.pulser.frequency('397dp', WithUnit(163.0,'MHz'))
        print "Loaded an ion ..."
        cxn.disconnect()
        time.sleep(0.5)
        
