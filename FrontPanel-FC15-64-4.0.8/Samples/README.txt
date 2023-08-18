Opal Kelly Samples README
=========================
  1. General
  2. Simulation
  3. Pre-built Sample Bitfiles
  4. Building Sample Bitfiles Using Xilinx ISE



1. GENERAL
==========
Samples here are provided as a starting point.  They aren't intended as
full-blown applications with error-checking and so on.

To build the C/C++ samples, Visual Studio projects (Windows) and Makefiles
(Linux and Mac OS X) have been provided.  These generally reference the 
native compilers.  For Windows applications that require wxWidgets, you will
need to download and build wxWidgets (http://www.wxwidgets.org).  You 
will also need to set a system environment variable to wherever you installed
the base tree for wxWidgets, e.g.:
   WXWIDGETS = c:\wxWidgets-2.8.11

The Visual Studio projects also reference different locations for the
libraries depending on architecture:
   32-bit builds: $(WXWIDGETS)\lib\vc_lib-x86
   64-bit builds: $(WXWIDGETS)\lib\vc_lib-x64

You will need to rename the default (vc_lib) directory to the appropriate
name above for the Visual Studio project to find the wxWidgets files.

Samples that have an executable will also require that you copy the 
DLL (or .so or .a for Linux/Mac, respectively) to the executable directory.
This can be found in the API directory where you installed FrontPanel.


The table below lists each of the samples included with FrontPanel. 
Depending on the specific capabilities highlighted, they include different
sources.  The included sources are listed below for each sample.

Sample          Collateral Included
---------------------------------------------------------------------------
First           XFP   Simulation   Verilog    VHDL
Counters        XFP                Verilog    VHDL
Controls        XFP                Verilog
PipeTest                           Verilog    VHDL   C++
DES                   Simulation   Verilog    VHDL   C++/Python/Java/Ruby
RAMTester                          Verilog           C++
FlashLoader                                          C++
DeviceChange                                         C++/wxWidgets

   + XFP - FrontPanel Application XML (XFP) provided
   + Simulation - Behavioral simulation is provided
   + Verilog - FPGA Verilog description is provided
   + VHDL - FPGA VHDL description is provided
   + C++ - C++ application using the FrontPanel DLL is included
     (Python, Java, Ruby, etc. may also be provided)
   + C++/wxWidgets - C++ application that uses wxWidgets GUI library




2. SIMULATION
=============
The following samples have associated simulation versions:

   + First (Verilog and VHDL)
   + DES   (Verilog)

Simulation versions are setup very similar to an actual FPGA-targetted 
project, but might differ in a specific detail or two.  In particular:

   + Simulation projects have the additional "*_tf.v" file which 
     contains the test fixture and attaches the FPGA pinout to the 
     host simulation.  The host simulation represents everything from the
     FPGA host interface pins back to the PC application code.
     
   + Simulation projects have the additional "okHostCalls.v" file which 
     contains Verilog or HDL models for the functions in the FrontPanel API.
   
   + Simulation projects include a Modelsim "do file" for executing the 
     simulation compiler and performing the test bench setup.




3. PRE-BUILT SAMPLE BITFILES
============================
Opal Kelly provides pre-built sample bitfiles for quick-start at the
following URL:

   http://www.opalkelly.com/download/

Each bundle contains bitfiles specific to a particular Opal Kelly 
module and is based on the most recent minor release and is dated.




4. BUILDING SAMPLES BITFILES USING XILINX ISE
=============================================
This will briefly guide you through the setup of a Xilinx
Project Navigator project and help you build this sample on your own.
The same process can be extended to any of the included samples as well
as your own projects.

This file is written for the Counters project, but with appropriate changes,
it will extend easily to the others.

If you are new to ISE Project Navigator, you should review the Xilinx 
documentation on that software.  At least some familiarity with ISE is
assumed here.


Step 1: Create a new Project
----------------------------
Within Project Navigator, create a new project.  This will also create
a new directory to contain the project.  You will be copying files into
this new location.

Be sure to select the correct FPGA device for your particular board:
   XEM3001v2      => xc3s400-4pq208
   XEM3010-1500   => xc3s1500-4fg320
   XEM3010-1000   => xc3s1000-4fg320
   XEM3005-1200   => xc3s1200e-4ft256
   XEM3050        => xc3s4000-5fg676
   XEM5010        => xc5vlx50-1ff676
   XEM6001        => XC6SLX16-2FTG256
   XEM6006        => XC6SLX16-2FTG256
   XEM6010-LX45   => xc6slx45-2fgg484
   XEM6010-LX150  => xc6slx150-2fgg484
   XEM6110-LX45   => xc6slx45-2fgg484
   XEM6110-LX150  => xc6slx150-2fgg484


Step 2: Copy source files to Project
------------------------------------
Copy the files from the sample directory to your new Project directory.
For the Counters (XEM3010-Verilog) sample, these are:
   + Counters.v     - Counters Verilog source.
   + xem3010.ucf    - Constraints file for the XEM3010 board.


Step 3: Copy Opal Kelly FrontPanel HDL files
--------------------------------------------
From the FrontPanel installation directory, copy the HDL module files.
Be sure to use the files from the correct board model as some of the 
items are board-specific.  The README.txt file indicates which version
of Xilinx ISE was used to produce the NGC files.  Note that these files
are forward-compatible with newer ISE versions.
   + okLibrary.v    - Verilog library file
   + *.ngc          - Pre-compiled FrontPanel HDL modules
   
   
Step 4: Add sources to your Project
-----------------------------------
Within Project Navigator, select "Add Sources..." from the "Project" menu.
Add the following files to your project: (Note that you have already copied
these files to your project directory in the previous steps.  They are now
being added to your Project.)  You do NOT need to add the NGC files to your
project.
   + Counters.v
   + okLibrary.v
   + xem3010.ucf
   
   
Step 5: Generate Programming File
---------------------------------
Within Project Navigator, select your toplevel source (Counters.v in this
case) from the "Sources" list.  Then double-click on
"Generate Programming File" to have ISE build a programming file that you
can then download to your board using FrontPanel.

NOTE: For the XEM6110, it is critical that you configure BITGEN to 
      float unused pins.  If this is not done, the FPGA/PC communication
      will not work correctly.
