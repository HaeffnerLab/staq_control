These are the simulation testbenches and do-files for the XEM6110 RAMTester.
Note that all tests use the MIG-generated core which performs an IDELAY 
calibration at system startup.  This calibration cycle can take over 50 us
to complete before the core is ready to use and can extend simulation time
considerably.


Micron provides simulation models for their devices through their website
http://www.micron.com.  They are not included here due to distribution 
restrictions on the Micron license, but they are available for free from
Micron.  You must download the simulation models and place the files in
the MT47H32M16 folder before running these simulations.

The simulations here were designed and tested with Micron's version 5.70.


Simulation Time
---------------
These simulations test the DDR2 controller from the MIG.  This includes 
the setup calibration period that determines the IDELAY timing to best 
match the PCB routing.  Due to this part of the simulation, the runtimes
may be very long to get to simulate the actual test bench.  
100 us of simulation time may take as long as 20 minutes using
ModelSim XE/Starter.



test_migtb.do
-------------
This is a simple testbench that runs the MIG-generated test.  There is 
limited output from this test.


test_okhi.do
------------
This is a testbench that exercises our RAMTester from simulated host
interface inputs.  This will need to run for at least 100 us.


test_oktb.do
------------
This is a testbench that exercises the memory controller and our FIFOs,
but does so without the actual okHost installed.  This test should also
run for at least 100 us.
