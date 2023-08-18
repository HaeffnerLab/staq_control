//------------------------------------------------------------------------
// flashloader.cpp
//
// A very simple SPI flash loader for supporting Opal Kelly FPGA modules.
// It works by loading a bitfile to the FPGA that contains logic to erase
// and program the attached SPI flash.  The program takes a single
// argument which is the name of a binary file to load to flash.
//
// If this is a valid Xilinx configuration file, the FPGA will boot to
// the SPI flash and load that config file.  The FPGA is smart enough to
// look for the starting bit pattern in the configuration file, so we
// don't have to modify it at all.
//
// This source is provided without guarantee.  You are free to incorporate
// it into your product.  You are also free to include the pre-built 
// bitfile in your product.
//------------------------------------------------------------------------
// Copyright (c) 2005-2011 Opal Kelly Incorporated
// $Rev: 1050 $ $Date: 2011-10-18 23:05:22 -0700 (Tue, 18 Oct 2011) $
//------------------------------------------------------------------------

#include <stdio.h>
#include <iostream>
#include <fstream>

#include "okFrontPanelDLL.h"

#if defined(_WIN32)
	#include "windows.h"
	#define stricmp _stricmp
	#define sscanf sscanf_s
#elif defined(__linux__) || defined(__APPLE__)
	#include <unistd.h>
	#define Sleep(ms)    usleep(ms*1000)
#endif


#define BITFILE_NAME           "flashloader.bit"
#define BUFFER_SIZE            (16*1024)
#define MAX_TRANSFER_SIZE      1024
#define FLASH_PAGE_SIZE        256
#define FLASH_SECTOR_SIZE      (65536)



bool
InitializeFPGA(okCFrontPanel *xem)
{
	if (okCFrontPanel::NoError != xem->OpenBySerial()) {
		return(false);
	}

	// Get some general information about the XEM.
	std::string str;
	printf("Device firmware version: %d.%d\n",
			xem->GetDeviceMajorVersion(),
			xem->GetDeviceMinorVersion());
	str = xem->GetSerialNumber();
	printf("Device serial number: %s\n", str.c_str());
	str = xem->GetDeviceID();
	printf("Device device ID: %s\n", str.c_str());

	// Download the configuration file.
	if (okCFrontPanel::NoError != xem->ConfigureFPGA(std::string(BITFILE_NAME))) {
		printf("FPGA configuration failed.\n");
		return(false);
	}

	// Check for FrontPanel support in the FPGA configuration.
	if (false == xem->IsFrontPanelEnabled()) {
		printf("FrontPanel support is not enabled.\n");
		return(false);
	}

	return(true);
}



void
EraseSectors(okCFrontPanel *xem, int address, int sectors)
{
	int i, sector, lastSector;

	xem->SetWireInValue(0x00, address, 0xffff);    // Send starting address
	xem->SetWireInValue(0x01, sectors, 0xffff);    // Send the number of sectors to erase
	xem->UpdateWireIns();
	xem->UpdateTriggerOuts();                      // Makes sure that there are no pending triggers back
	xem->ActivateTriggerIn(0x40, 3);               // Trigger the beginning of the sector erase routine

	printf("Status: ");fflush(stdout);
	sector = lastSector = i = 0;
	do {
		Sleep(200);
		xem->UpdateTriggerOuts();
		if (xem->IsTriggered(0x60, 0x0001)) {
			printf("\nErased %d sectors starting at address 0x%04X.\n", (sectors+1), address);
			break;
		}

		xem->UpdateWireOuts();
		sector = xem->GetWireOutValue(0x20);
		printf(" %d", sector);
		fflush(stdout);
		if (lastSector != sector) {
			i = 0;
			lastSector = sector;
		}
		i++;
		if (i > 50) {
			printf("\n ** Timeout in EraseSectors -- Erasure failed.\n");
			break;
		}
	} while (1);
}



bool
WriteBitfile(okCFrontPanel *xem, char *filename)
{
	std::ifstream bit_in;
	unsigned char buf[BUFFER_SIZE];
	int i, j, k;
	long lN;

	bit_in.open(filename, std::ios::binary);
	if (false == bit_in.is_open()) {
		printf("Error: Bitfile could not be opened.\n");
		return(false);
	}

	bit_in.seekg(0, std::ios::end);
	lN = (long)bit_in.tellg();
	bit_in.seekg(0, std::ios::beg);

	// Find the sync word first.  We'll include the two [0xff, 0xff] pad bytes, but trim the rest.
	bit_in.read((char *)buf, BUFFER_SIZE);
	for (i=0; i<BUFFER_SIZE; i++) {
		if ((buf[i+0] == 0xAA) && (buf[i+1] == 0x99) & (buf[i+2] == 0x55) && (buf[i+3] == 0x66)) {
			bit_in.seekg(i-2, std::ios::beg);
			break;
		}
	}
	if (BUFFER_SIZE == i) {
		printf("Error: Sync word not found.\n");
		return(false);
	}

	//
	// Clear out the sectors required for the new bitfile size.
	// FPGA code takes N-1 where N is the number of sectors to erase.
	// So passing "0" will erase 1 sector.
	//
	i = lN / FLASH_SECTOR_SIZE;
	printf("File size: %d kB  --  Erasing %d sectors.\n", (int)lN/1024, i+1);
	EraseSectors(xem, 0x0000, i);


	printf("Downloading bitfile (%d bytes).\n", (int)lN);
	lN = lN / MAX_TRANSFER_SIZE + 1;
	j = 0;
	for(i=0; i<lN; i++) {
		bit_in.read((char *)buf, MAX_TRANSFER_SIZE);

		// Write
		xem->WriteToPipeIn(0x80, MAX_TRANSFER_SIZE, buf);
		xem->SetWireInValue(0x00, j, 0xffff);	// Send starting address
		xem->SetWireInValue(0x01, (MAX_TRANSFER_SIZE/FLASH_PAGE_SIZE)-1, 0xffff);		// Send the number of pages to program
		xem->UpdateWireIns();							// Update Wire Ins
		xem->UpdateTriggerOuts();						// Makes sure that there are no pending triggers back
		xem->ActivateTriggerIn(0x40, 5);				// Trigger the beginning of the sector erase routine
		j += MAX_TRANSFER_SIZE/FLASH_PAGE_SIZE;

		k = 0;
		do {
			xem->UpdateTriggerOuts();
			if (xem->IsTriggered(0x60, 0x0001))
				break;

			k++;
			if (k > 50) {
				printf("\n ** Timeout in WriteBitfile -- Programming failed.\n");
				return(false);
			}
		} while (1);
	}
	printf("Programmed.\n");
	return(true);
}



void hdlReset(okCFrontPanel *xem)
{
	printf("Reset \n");
	// Assert then deassert RESET.
	xem->SetWireInValue(0x00, 0x0001, 0xffff);
	xem->UpdateWireIns();
	Sleep(1);
	xem->SetWireInValue(0x00, 0x0000, 0xffff);
	xem->UpdateWireIns();
	Sleep(10);
}



static void
printUsage(char *progname)
{
	printf("Usage: %s bitfile\n", progname);
	printf("   bitfile - Bitfile to write to configuration flash.\n");
}



int
main(int argc, char *argv[])
{
	okCFrontPanel *xem;
	char dll_date[32], dll_time[32];


	printf("---- Opal Kelly ---- SPI Flash Programmer ----\n");
	if (FALSE == okFrontPanelDLL_LoadLib(NULL)) {
		printf("FrontPanel DLL could not be loaded.\n");
		return(-1);
	}
	okFrontPanelDLL_GetVersion(dll_date, dll_time);
	printf("FrontPanel DLL loaded.  Built: %s  %s\n", dll_date, dll_time);

	if (argc != 2) {
		printUsage(argv[0]);
		return(-1);
	}

	// Initialize the FPGA with our configuration bitfile.
	xem = new okCFrontPanel;
	
	if (false == InitializeFPGA(xem)) {
		printf("FPGA could not be initialized.\n");
		return(-1);
	}

	printf("\n*******************************\n");
	WriteBitfile(xem, argv[1]);
	printf("*******************************\n\n");
	return(0);
}


