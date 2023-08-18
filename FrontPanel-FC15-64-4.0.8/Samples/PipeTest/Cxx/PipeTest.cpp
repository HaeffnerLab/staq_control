//------------------------------------------------------------------------
// PipeTest.CPP
//
// This is the C++ source file for the PipeTest Sample.
//
//
// Copyright (c) 2004-2010 Opal Kelly Incorporated
// $Rev: 1086 $ $Date: 2012-02-01 17:08:13 -0800 (Wed, 01 Feb 2012) $
//------------------------------------------------------------------------

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <time.h>
#include <string.h>
#if defined(__QNX__)
	#include <stdint.h>
	#include <sys/syspage.h>
	#include <sys/neutrino.h>
	#include <sys/types.h>
	#include <sys/usbdi.h>
#endif

#include "okFrontPanelDLL.h"

// From mt_random.cpp
void mt_init();
unsigned long mt_random();


#if defined(_WIN32)
	#define strncpy strncpy_s
	#define sscanf  sscanf_s
#elif defined(__linux__) || defined(__APPLE__)
#endif
#if defined(__QNX__)
	#define clock_t   uint64_t
    #define clock()   ClockCycles()
	#define NUM_CPS   ((SYSPAGE_ENTRY(qtime)->cycles_per_sec))
#else
	#define NUM_CPS   CLOCKS_PER_SEC
#endif

typedef unsigned long  UINT32;


#define MIN(a,b)   (((a)<(b)) ? (a) : (b))


bool     m_bCheck;
bool     m_bInjectError;
UINT32   m_u32BlockSize;
UINT32   m_u32SegmentSize;
UINT32   m_u32TransferSize;
UINT32   m_u32ThrottleIn;
UINT32   m_u32ThrottleOut;
clock_t  m_cStart;
clock_t  m_cStop;


void
startTimer()
{
	m_cStart = clock();
}



void
stopTimer()
{
	m_cStop = clock();
}



void
generateData(unsigned char *pucValid, UINT32 u32ByteCount, UINT32 u32Width)
{
	UINT32 i;
	UINT32 lfsrE, lfsrO, bit;
	bool bRandom = true;


	if (bRandom) {
		lfsrE = 0x04030201;
		lfsrO = 0x0D0C0B0A;
	} else {
		lfsrE = 0x00000001;
		lfsrO = 0x00000001;
	}

	// USB hosts are 16-bit.  PCIe hosts are 32-bit.
	if (32 == u32Width) {
		UINT32 *pu32Valid = (UINT32 *)pucValid;
		for (i=0; i<u32ByteCount/8; i++) {
			pu32Valid[i*2 + 0] = lfsrE;
			pu32Valid[i*2 + 1] = lfsrO;

			bit = ((lfsrE >> 31) ^ (lfsrE >> 21) ^ (lfsrE >> 1)) & 1;
			lfsrE = (bRandom) ? ((lfsrE << 1) | (bit)) : (lfsrE+1);
			bit = ((lfsrO >> 31) ^ (lfsrO >> 21) ^ (lfsrO >> 1)) & 1;
			lfsrO = (bRandom) ? ((lfsrO << 1) | (bit)) : (lfsrO+1);
		}
		// Inject errors (optional)
		if (m_bInjectError)
			pu32Valid[7] = ~pu32Valid[7];
	} else if (16 == u32Width) {
		for (i=0; i<u32ByteCount/2; i++) {
			pucValid[i*2 + 0] = (lfsrE >> 0) & 0xff;
			pucValid[i*2 + 1] = (lfsrE >> 8) & 0xff;

			bit = ((lfsrE >> 31) ^ (lfsrE >> 21) ^ (lfsrE >> 1)) & 1;
			lfsrE = (bRandom) ? ((lfsrE << 1) | (bit)) : (lfsrE+1);
		}

		// Inject errors (optional)
		if (m_bInjectError)
			pucValid[7] = ~pucValid[7];
	}
}



bool
checkData(unsigned char *pucBuffer, unsigned char *pucValid, UINT32 u32ByteCount)
{
	UINT32 i;
	UINT32 *pu32Buffer = (UINT32 *)pucBuffer;
	UINT32 *pu32Valid = (UINT32 *)pucValid;
	for (i=0; i<u32ByteCount/4; i++) {
		if (pu32Buffer[i] != pu32Valid[i]) {
			printf("[%ld]  %08lX  !=  %08lX\n", i, pu32Buffer[i], pu32Valid[i]);
			return(false);
		}
	}
	return(true);
}



void
reportRateResults(UINT32 u32Count)
{
	clock_t clkInterval = m_cStop - m_cStart;
	printf("Duration: %.3f seconds -- %.2f calls/s\n",
	       (double) clkInterval / NUM_CPS,
	       (double) (u32Count) * NUM_CPS / clkInterval);
}



void
reportBandwidthResults(UINT32 u32Count)
{
	clock_t clkInterval = (m_cStop - m_cStart)/u32Count;
	printf("Duration: %.3f seconds -- %.2f MB/s\n",
	       (double) clkInterval / NUM_CPS,
	       (double) (m_u32TransferSize/1024/1024) * NUM_CPS / clkInterval);
}



bool
Transfer(okCFrontPanel *dev, UINT32 u32Count, bool bWrite)
{
	unsigned char *pBuffer;
	unsigned char *pValid;
	UINT32  i;
	UINT32  u32SegmentSize, u32Remaining;


#if defined(__QNX__)
	pBuffer = (unsigned char *)usbd_alloc((size_t)m_u32SegmentSize);
	pValid = (unsigned char *)usbd_alloc((size_t)m_u32SegmentSize);
#else
	pBuffer = new unsigned char[m_u32SegmentSize];
	pValid = new unsigned char[m_u32SegmentSize];
#endif

	dev->SetWireInValue(0x02, m_u32ThrottleIn);     // Pipe In throttle
	dev->SetWireInValue(0x01, m_u32ThrottleOut);    // Pipe Out throttle
	dev->SetWireInValue(0x00, 1<<5 | 1<<4 | 1<<2);  // SET_THROTTLE=1 | MODE=LFSR | RESET=1
	dev->UpdateWireIns();
	dev->SetWireInValue(0x00, 0<<5 | 1<<4 | 0<<2);  // SET_THROTTLE=0 | MODE=LFSR | RESET=0
	dev->UpdateWireIns();

	startTimer();
	for (i=0; i<u32Count; i++) {
		u32Remaining = m_u32TransferSize;
		while (u32Remaining > 0) {
			u32SegmentSize = MIN(m_u32SegmentSize, u32Remaining);
			u32Remaining -= u32SegmentSize;

			// If we're validating data, generate data per segment.
			if (m_bCheck) {
				dev->SetWireInValue(0x00, 0<<5 | 1<<4 | 1<<2);  // SET_THROTTLE=0 | MODE=LFSR | RESET=1
				dev->UpdateWireIns();
				dev->SetWireInValue(0x00, 0<<5 | 1<<4 | 0<<2);  // SET_THROTTLE=0 | MODE=LFSR | RESET=0
				dev->UpdateWireIns();
				generateData(pValid, u32SegmentSize, dev->GetHostInterfaceWidth());
			}

			if (bWrite) {
				if (1024 != m_u32BlockSize) {
					dev->WriteToBlockPipeIn(0x80, m_u32BlockSize, u32SegmentSize, pValid);
				} else {
					dev->WriteToPipeIn(0x80, u32SegmentSize, pValid);
				}
			} else {
				if (1024 != m_u32BlockSize) {
					dev->ReadFromBlockPipeOut(0xA0, m_u32BlockSize, u32SegmentSize, pBuffer);
				} else {
					dev->ReadFromPipeOut(0xA0, u32SegmentSize, pBuffer);
				}
			}
			if (m_bCheck) {
				if (false == bWrite) {
					if (false == checkData(pBuffer, pValid, u32SegmentSize)) {
						printf("ERROR: Data check failed!\n");
					}
				} else {
					dev->UpdateWireOuts();
					if (0 != dev->GetWireOutValue(0x21)) {
						printf("ERROR: Data check failed!\n");
					}
				}
			}
		}
	}
	stopTimer();
#if defined(__QNX__)
	usbd_free(pValid);
	usbd_free(pBuffer);
#else
	delete [] pValid;
	delete [] pBuffer;
#endif

	return(true);
}



void
BenchmarkWires(okCFrontPanel *dev)
{
	UINT32 i;

	printf("UpdateWireIns  (1000 calls)  ");
	startTimer();
	for (i=0; i<1000; i++)
		dev->UpdateWireIns();
	stopTimer();
	reportRateResults(1000);
	
	printf("UpdateWireOuts (1000 calls)  ");
	startTimer();
	for (i=0; i<1000; i++)
		dev->UpdateWireOuts();
	stopTimer();
	reportRateResults(1000);
}



void
BenchmarkTriggers(okCFrontPanel *dev)
{
	UINT32 i;

	printf("ActivateTriggerIns  (1000 calls)  ");
	startTimer();
	for (i=0; i<1000; i++)
		dev->ActivateTriggerIn(0x40, 0x01);
	stopTimer();
	reportRateResults(1000);
	
	printf("UpdateTriggerOuts (1000 calls)  ");
	startTimer();
	for (i=0; i<1000; i++)
		dev->UpdateTriggerOuts();
	stopTimer();
	reportRateResults(1000);
}



void
BenchmarkPipes(okCFrontPanel *dev)
{
	UINT32 i, j, u32Count;
	bool bWrite;
	UINT32 matrix[][4] = { // BlockSize, SegmentSize,    TransferSize, Count
	                        { 1024,      4*1024*1024,    64*1024*1024,     1 },
	                        { 1024,      4*1024*1024,    32*1024*1024,     1 },
	                        { 1024,      4*1024*1024,    16*1024*1024,     2 },
	                        { 1024,      4*1024*1024,     8*1024*1024,     4 },
	                        { 1024,      4*1024*1024,     4*1024*1024,     8 },
	                        { 1024,      1*1024*1024,    32*1024*1024,     1 },
	                        { 1024,         256*1024,    32*1024*1024,     1 },
	                        { 1024,          64*1024,    16*1024*1024,     1 },
	                        { 1024,          16*1024,     4*1024*1024,     1 },
	                        { 1024,           4*1024,     1*1024*1024,     1 },
	                        { 1024,           1*1024,     1*1024*1024,     1 },
	                        {  900,      1*1024*1024,    32*1024*1024,     1 },
	                        {  800,      1*1024*1024,    32*1024*1024,     1 },
	                        {  700,      1*1024*1024,    32*1024*1024,     1 },
	                        {  600,      1*1024*1024,    32*1024*1024,     1 },
	                        {  512,      1*1024*1024,    32*1024*1024,     1 },
	                        {  500,      1*1024*1024,    32*1024*1024,     1 },
	                        {  400,      1*1024*1024,    16*1024*1024,     1 },
	                        {  300,      1*1024*1024,    16*1024*1024,     1 },
	                        {  256,      1*1024*1024,    16*1024*1024,     1 },
	                        {  200,      1*1024*1024,     8*1024*1024,     1 },
	                        {  128,      1*1024*1024,     8*1024*1024,     1 },
	                        {  100,      1*1024*1024,     8*1024*1024,     1 },
	                        {    0,                0,               0,     0 } };

	for (j=0; j<2; j++) {
		bWrite = (j==1);
		for (i=0; matrix[i][0]!=0; i++) {
			m_u32BlockSize     = matrix[i][0];
			m_u32SegmentSize   = matrix[i][1];
			m_u32SegmentSize  -= (m_u32SegmentSize % m_u32BlockSize);  // Segment size must be a multiple of block length
			m_u32TransferSize  = matrix[i][2];
			m_u32TransferSize -= (m_u32TransferSize % m_u32BlockSize);  // Segment size must be a multiple of block length
			u32Count           = matrix[i][3];
			printf("%s BS:%-10ld  SS:%-10ld  TS:%-10ld   ", bWrite ? ("Write") : ("Read "), 
			       m_u32BlockSize, m_u32SegmentSize, m_u32TransferSize);
			Transfer(dev, u32Count, bWrite);
			reportBandwidthResults(u32Count);
		}
	}
}



bool
InitializeFPGA(okCFrontPanel *dev, char *bitfile, char *serial)
{
	if (okCFrontPanel::NoError != dev->OpenBySerial(std::string(serial))) {
		printf("Device could not be opened.  Is one connected?\n");
		return(false);
	}
	printf("Found a device: %s\n", dev->GetBoardModelString(dev->GetBoardModel()).c_str());

	dev->LoadDefaultPLLConfiguration();	

	// Get some general information about the XEM.
	std::string str;
	printf("Device firmware version: %d.%d\n", dev->GetDeviceMajorVersion(), dev->GetDeviceMinorVersion());
	str = dev->GetSerialNumber();
	printf("Device serial number: %s\n", str.c_str());
	str = dev->GetDeviceID();
	printf("Device device ID: %s\n", str.c_str());

	// Download the configuration file.
	if (okCFrontPanel::NoError != dev->ConfigureFPGA(bitfile)) {
		printf("FPGA configuration failed.\n");
		return(false);
	}

	// Check for FrontPanel support in the FPGA configuration.
	if (dev->IsFrontPanelEnabled())
		printf("FrontPanel support is enabled.\n");
	else
		printf("FrontPanel support is not enabled.\n");

	return(true);
}


static void
printUsage(char *progname)
{
	printf("Usage: %s bitfile [check] [bench] [blocksize B] [segmentsize S] [inject] [read N] [write N]\n", progname);
	printf("   bitfile        - Configuration file to download.\n");
	printf("   check          - Turns on validity checks.\n");
	printf("   bench          - Runs a preset benchmark script and prints results.\n");
	printf("   blocksize B    - Sets the block size to B (for BTPipes).\n");
	printf("   segmentsize S  - Sets the segment size to S.\n");
	printf("   inject         - Injects an error during data generation.\n");
	printf("   read N         - Performs a read of N bytes and optionally checks for validity.\n");
	printf("   write N        - Performs a write of N bytes and optionally checks for validity.\n");
}


int
main(int argc, char *argv[])
{
	okCFrontPanel *dev;
	char bitfile[128], serial[128];
	char dll_date[32], dll_time[32];
	UINT32 i;


	printf("---- Opal Kelly ---- PipeTest Application v1.0 ----\n");
	if (FALSE == okFrontPanelDLL_LoadLib(NULL)) {
		printf("FrontPanel DLL could not be loaded.\n");
		return(-1);
	}
	okFrontPanelDLL_GetVersion(dll_date, dll_time);
	printf("FrontPanel DLL loaded.  Built: %s  %s\n", dll_date, dll_time);


	if (argc < 2) {
		printUsage(argv[0]);
		return(-1);
	}

	// Initialize the FPGA with our configuration bitfile.
	dev = new okCFrontPanel;
	strncpy(bitfile, argv[1], 128);
	if ((argc>=3) && (!strcmp(argv[2], "serial"))) {
		sscanf(argv[3], "%s", serial);
		i = 4;
	} else {
		serial[0] = '\0';
		i = 2;
	}
	if (false == InitializeFPGA(dev, bitfile, serial)) {
		printf("FPGA could not be initialized.\n");
		goto done;
	}

	m_bCheck = false;
	m_u32BlockSize = 1024;
	m_u32SegmentSize = 4*1024*1024;
	m_u32ThrottleIn = 0xffffffff;
	m_u32ThrottleOut = 0xffffffff;
	for (; i<(UINT32)argc; i++) {
		if (!strcmp(argv[i], "blocksize")) {
			sscanf(argv[++i], "%ld", &m_u32BlockSize);
		}
		if (!strcmp(argv[i], "segmentsize")) {
			sscanf(argv[++i], "%ld", &m_u32SegmentSize);
		}
		if (!strcmp(argv[i], "check")) {
			m_bCheck = true;
		}
		if (!strcmp(argv[i], "inject")) {
			m_bInjectError = true;
		}
		if (!strcmp(argv[i], "throttlein")) {
			sscanf(argv[++i], "%08lx", &m_u32ThrottleIn);
		}
		if (!strcmp(argv[i], "throttleout")) {
			sscanf(argv[++i], "%08lx", &m_u32ThrottleOut);
		}
		if (!strcmp(argv[i], "read")) {
			sscanf(argv[++i], "%ld", &m_u32TransferSize);
			Transfer(dev, 1, false);
			reportBandwidthResults(1);
		}
		if (!strcmp(argv[i], "write")) {
			sscanf(argv[++i], "%ld", &m_u32TransferSize);
			Transfer(dev, 1, true);
			reportBandwidthResults(1);
		}
		if (!strcmp(argv[i], "bench")) {
			BenchmarkWires(dev);
			BenchmarkTriggers(dev);
			BenchmarkPipes(dev);
		}
	}

done:
	delete dev;
	return(0);
}
