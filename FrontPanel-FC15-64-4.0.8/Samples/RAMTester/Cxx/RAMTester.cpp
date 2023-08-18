//------------------------------------------------------------------------
// RAMTester.cpp
//
//
//
// Copyright (c) 2004-2009 Opal Kelly Incorporated
// $Rev: 994 $ $Date: 2011-09-28 21:50:29 -0700 (Wed, 28 Sep 2011) $
//------------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "okFrontPanelDLL.h"


#define CONFIGURATION_FILE         "ramtest.bit"
#define READBUF_SIZE               (8*1024*1024)	// 8 MB read buffer size
#define WRITE_SIZE                 (8*1024*1024)
#define READ_SIZE                  (8*1024*1024)    // <= READBUF_SIZE
#define NUM_TESTS                  10
#define MIN(x,y)                   ( (x<y) ? (x) : (y) )

unsigned char *g_buf, *g_rbuf;
int g_nMems, g_nMemSize;


// From mt_random.cpp
void mt_init();
unsigned long mt_random();


void
writeSDRAM(okCFrontPanel *dev, int mem)
{
	int i;

	// Generate some random data
	printf("   Generating random data...\n");
	for (i=0; i<g_nMemSize; i++){
		g_buf[i] = mt_random() % 256;
	}

	// Reset FIFOs
	dev->SetWireInValue(0x00, 0x0004);
	dev->UpdateWireIns();
	dev->SetWireInValue(0x00, 0x0000);
	dev->UpdateWireIns();

	// Enable SDRAM write memory transfers
	dev->SetWireInValue(0x00, 0x0002);
	dev->UpdateWireIns();
	printf("   Writing to memory(%d)...\n", mem);

	for (i=0; i<g_nMemSize/WRITE_SIZE; i++){ 
		dev->WriteToPipeIn(0x80+mem, WRITE_SIZE, &g_buf[WRITE_SIZE*i]);
	}

	dev->UpdateWireOuts();
}


bool
testSDRAM(okCFrontPanel *dev, int mem)
{
	int i, j, k, read;
	bool passed;


	// Reset FIFOs
	dev->SetWireInValue(0x00, 0x0004);
	dev->UpdateWireIns();
	dev->SetWireInValue(0x00, 0x0000);
	dev->UpdateWireIns();

	// Enable SDRAM read memory transfers
	dev->SetWireInValue(0x00, 0x0001);
	dev->UpdateWireIns();
	printf("   Reading from memory(%d)...\n", mem);

	passed = true;
	for (i=0; i<g_nMemSize; ) { 
		read = MIN(READ_SIZE, g_nMemSize-i);
		dev->ReadFromPipeOut(0xA0+mem, read, g_rbuf);
		for (j=0; j<read; j++) {
			if (g_buf[i + j] != g_rbuf[j]) {
				for (k=0; k<8; k++)
					printf("[%d] = 0x%02X / 0x%02X // 0x%02X\n",
					       i+j+k,
						   g_buf[i+j+k],
						   g_rbuf[j+k],
						   g_buf[i+j+k] ^ g_rbuf[j+k]);
				passed = false;
				break;
			}
		}
		if (false == passed)
			break;
		i += read;
	}

	return(passed);
}


okCFrontPanel *
initializeFPGA()
{
	okCFrontPanel *dev;

	// Open the first XEM - try all board types.
	dev = new okCFrontPanel;
	if (okCFrontPanel::NoError != dev->OpenBySerial()) {
		delete dev;
		printf("Device could not be opened.  Is one connected?\n");
		return(NULL);
	}
	
	printf("Found a device: %s\n", dev->GetBoardModelString(dev->GetBoardModel()).c_str());
	
	// Set memory configuration
	switch (dev->GetBoardModel()) {
		case okCFrontPanel::brdXEM3005:
		case okCFrontPanel::brdXEM3010:
			g_nMemSize = 32*1024*1024;
			g_nMems = 1;
			break;
		case okCFrontPanel::brdXEM3050:
			g_nMemSize = 32*1024*1024;
			g_nMems = 2;
			break;
		case okCFrontPanel::brdXEM5010:
		case okCFrontPanel::brdXEM5010LX110:
			g_nMemSize = 128*1024*1024;
			g_nMems = 2;
			break;
		case okCFrontPanel::brdXEM6006LX9:
		case okCFrontPanel::brdXEM6006LX16:
		case okCFrontPanel::brdXEM6006LX25:
		case okCFrontPanel::brdXEM6010LX45:
		case okCFrontPanel::brdXEM6010LX150:
		case okCFrontPanel::brdXEM6110LX45:
		case okCFrontPanel::brdXEM6110LX150:
			g_nMemSize = 128*1024*1024;
			g_nMems = 1;
			break;
		default:
			printf("Unsupported device.\n");
			delete dev;
			return(NULL);
	}

	// Configure the PLL appropriately
	dev->LoadDefaultPLLConfiguration();

	// Get some general information about the XEM.
	printf("Device firmware version: %d.%d\n", dev->GetDeviceMajorVersion(), dev->GetDeviceMinorVersion());
	printf("Device serial number: %s\n", dev->GetSerialNumber().c_str());
	printf("Device ID string: %s\n", dev->GetDeviceID().c_str());

	// Download the configuration file.
	if (okCFrontPanel::NoError != dev->ConfigureFPGA(CONFIGURATION_FILE)) {
		printf("FPGA configuration failed.\n");
		delete dev;
		return(NULL);
	}

	// Check for FrontPanel support in the FPGA configuration.
	if (false == dev->IsFrontPanelEnabled()) {
		printf("FrontPanel support is not enabled.\n");
		delete dev;
		return(NULL);
	}

	printf("FrontPanel support is enabled.\n");

	return(dev);
}


static void
printUsage(char *progname)
{
	printf("Usage: %s\n", progname);
}


int
main(int argc, char *argv[])
{
	char dll_date[32], dll_time[32];

	printf("---- Opal Kelly ---- RAMTester Application v1.0 ----\n");
	if (FALSE == okFrontPanelDLL_LoadLib(NULL)) {
		printf("FrontPanel DLL could not be loaded.\n");
		return(-1);
	}
	okFrontPanelDLL_GetVersion(dll_date, dll_time);
	printf("FrontPanel DLL loaded.  Built: %s  %s\n", dll_date, dll_time);


	if (argc > 1) {
		printUsage(argv[0]);
		return(-1);
	}

	// Initialize the FPGA with our configuration bitfile.
	okCFrontPanel *dev = initializeFPGA();
	if (NULL == dev) {
		printf("FPGA could not be initialized.\n");
		return(-1);
	}

	// Initialize random number generator.
	srand( (unsigned int) time(NULL) );
	mt_init();

	// Allocate some buffer memory.
	g_buf = new unsigned char[g_nMemSize];
	g_rbuf = new unsigned char[READBUF_SIZE];

	// Now perform the memory test.
	int pass=0, fail=0, i, j;
	for (i=0; i<NUM_TESTS; i++) {
		for (j=0; j<g_nMems; j++) {
			writeSDRAM(dev, j);
			if (true == testSDRAM(dev, j))
				pass++;
			else
				fail++;
		}

		printf("Passed: %d  Failed: %d\n", pass, fail);
	}

	// Free allocated storage.
	delete [] g_buf;
	delete [] g_rbuf;

	return(0);
}
