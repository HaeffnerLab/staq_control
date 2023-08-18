import ok
import sys
import string

class DESTester:
	def __init__(self):
		return
		
	def InitializeDevice(self):
		# Try the XEM3001v1
		self.xem = ok.FrontPanel()
		if (self.xem.NoError != self.xem.OpenBySerial("")):
			print "A device could not be opened.  Is one connected?"
			return(False)

		if (self.xem.brdXEM3001v2 == self.xem.GetBoardModel()):
			print "Device model: XEM3001v2"

		if (self.xem.brdXEM3010 == self.xem.GetBoardModel()):
			print "Device model: XEM3010"
		
		self.xem.LoadDefaultPLLConfiguration()

		# Get some general information about the device.
		print "Device firmware version: %d.%d" % (self.xem.GetDeviceMajorVersion(), self.xem.GetDeviceMinorVersion())
		print "Device serial number: %s" % self.xem.GetSerialNumber()
		print "Device ID: %s" % self.xem.GetDeviceID()

		# Download the configuration file.
		if (self.xem.NoError != self.xem.ConfigureFPGA("destop.bit")):
			print "FPGA configuration failed."
			return(False)

		# Check for FrontPanel support in the FPGA configuration.
		if (False == self.xem.IsFrontPanelEnabled()):
			print "FrontPanel support is not available."
			return(False)
		
		print "FrontPanel support is available."
		return(True)


	def SetKey(self, key):
		for i in range(8):
			self.xem.SetWireInValue((0x0f-i), key[i], 0xff)
		self.xem.UpdateWireIns()


	def ResetDES(self):
		self.xem.SetWireInValue(0x10, 0xff, 0x01)
		self.xem.UpdateWireIns()
		self.xem.SetWireInValue(0x10, 0x00, 0x01)
		self.xem.UpdateWireIns()


	def EncryptDecrypt(self, infile, outfile):
		fileIn = file(infile, "rb")
		fileOut = file(outfile, "wb")

		# Reset the RAM address pointer.
		self.xem.ActivateTriggerIn(0x41, 0)

		while fileIn:
			buf = fileIn.read(2048)
			got = len(buf)
			if (got == 0):
				break

			if (got < 2048):
				buf += "\x00"*(2048-got)

			# Write a block of data.
			self.xem.ActivateTriggerIn(0x41, 0)
			self.xem.WriteToPipeIn(0x80, buf)

			# Perform DES on the block.
			self.xem.ActivateTriggerIn(0x40, 0)

			# Wait for the TriggerOut indicating DONE.
			for i in range(10):
				self.xem.UpdateTriggerOuts()
				if (self.xem.IsTriggered(0x60, 1)):
					break

			self.xem.ReadFromPipeOut(0xa0, buf)
			fileOut.write(buf)
		
		fileIn.close()
		fileOut.close()


	def Encrypt(self, infile, outfile):
		print "Encrypting %s ----> %s" % (infile, outfile)
		# Set the encrypt Wire In.
		self.xem.SetWireInValue(0x0010, 0x0000, 0x0010)
		self.xem.UpdateWireIns()
		self.EncryptDecrypt(infile, outfile)


	def Decrypt(self, infile, outfile):
		print "Decrypting %s ---> %s" % (infile, outfile)
		# Set the decrypt Wire In.
		self.xem.SetWireInValue(0x0010, 0x00ff, 0x0010)
		self.xem.UpdateWireIns()
		self.EncryptDecrypt(infile, outfile)


# Main code
print "------ DES Encrypt/Decrypt Tester in Python ------"
des = DESTester()
if (False == des.InitializeDevice()):
	exit

des.ResetDES()

if (len(sys.argv) != 5):
	print "Usage: DESTester [d|e] key infile outfile"
	print "   [d|e]   - d to decrypt the input file.  e to encrypt it."
	print "   key     - 64-bit hexadecimal string used for the key."
	print "   infile  - an input file to encrypt/decrypt."
	print "   outfile - destination output file."

# Get the hex digits entered as the key
key = []
strkey = sys.argv[2]
for i in range(8):
	key.append(string.atoi(strkey[i*2 : i*2+2], 16))
des.SetKey(key)

# Encrypt or decrypt
if (sys.argv[1] == 'd'):
	des.Decrypt(sys.argv[3], sys.argv[4])
else:
	des.Encrypt(sys.argv[3], sys.argv[4])
