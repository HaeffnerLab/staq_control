Linux Installation
------------------
These installation instructions are valid for FedoraCore 5.  They may work
with or without slight modifications under other Linux distributions.

The Linux installation requires the addition of one file to the directory:

   60-opalkelly.rules ----->  /etc/udev/rules.d/

This file includes a generic udev rule to set the permissions on all
attached Opal Kelly USB devices to allow user access.  Once this file is
in place, you will need to reload the rules by either rebooting or using
the following command:

   /sbin/udevadm control --reload_rules

With these files in place, the Linux device system should automatically
provide write permissions to XEM devices attached to the USB.


Notes
-----
The Firmware Update Wizard is not available in the Linux version of
FrontPanel.


Python API
----------
__init__.py
__version__.py
_ok.so
ok.py

By placing these four files into a directory and starting Python from that
directory, you can "import ok" and have access to the Python API.  From 
there, you can run commands like:

   import ok
   xem = ok.FrontPanel()
   xem.OpenBySerial("")
   xem.LoadDefaultPLLConfiguration()
   xem.ConfigureFPGA('counters.bit')
   


Java API (Linux)
--------
okjFrontPanel.dll   (Windows)
libokjFrontPanel.so (Linux)
okjFrontPanel.jar   (Common)

libokjFrontPanel.so needs to be copied to the java.library.path.  On SuSE 9.2,
	you can copy it to /usr/lib/jvm/jre/lib/i386
	
okjFrontPanel.jar should be added to your CLASSPATH.  It can either be 
	uncompressed or referred to directly on the javac/java command lines as below.
	
To build and run DESTester.java:
	javac -classpath okjFrontPanel.jar DESTester.java
	java -classpath .:okjFrontPanel.jar DESTester e inputfile outputfile
	
