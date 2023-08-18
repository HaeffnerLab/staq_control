REM First Simulation Batch File
REM $Rev$ $Date$

REM Edit path for settings32/64, depending on architecture
call %XILINX%\..\settings64.bat

fuse -intstyle ise ^
     -incremental ^
     -lib unisims ^
     -lib unimacro ^
     -lib xilinxcorelib ^
     -lib frontpanel ^
     -o first_isim.exe ^
     -prj first_isim.prj ^
     work.FIRST_TEST
first_isim.exe -gui -tclbatch first_isim.tcl -wdb first_isim.wdb