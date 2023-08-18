#!/bin/bash

# Install script for Linux distributions
# This is a basic installer that merely copies the include files and
# libraries to the system-wide directories.

# Copy the udev rules file and reload all rules
cp ./60-opalkelly.rules /etc/udev/rules.d
/sbin/udevcontrol reload_rules


# Copy the API libraries and include files
cp ./API/libokFrontPanel.so /usr/local/lib/
cp ./API/okFrontPanelDLL.h /usr/local/include/

