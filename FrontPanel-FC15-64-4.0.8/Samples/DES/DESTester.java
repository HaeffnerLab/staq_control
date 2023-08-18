// destest.java

import java.io.*;
import com.opalkelly.frontpanel.*;

public class DESTester
{
	okFrontPanel m_dev;

	static 
	{
		System.loadLibrary("okjFrontPanel");
	}

	public boolean InitializeDevice()
	{
		// Create an instance of the device.
		m_dev = new okFrontPanel();
		if (okFrontPanel.ErrorCode.NoError != m_dev.OpenBySerial("")) {
			System.out.println("A device could not be opened.  Is one connected?");
			return(false);
		}

		// Get some general information about the device.
		System.out.println("Device firmware version: " + 
			m_dev.GetDeviceMajorVersion() + "." +
			m_dev.GetDeviceMinorVersion());
		System.out.println("Device serial number: " + m_dev.GetSerialNumber());
		System.out.println("Device ID: " + m_dev.GetDeviceID());

		// Setup the PLL from defaults.
		m_dev.LoadDefaultPLLConfiguration();

		// Download the configuration file.
		if (okFrontPanel.ErrorCode.NoError != m_dev.ConfigureFPGA("destop.bit")) {
			System.out.println("FPGA configuration failed.");
			return(false);
		}

		// Check for FrontPanel support in the FPGA configuration.
		if (false == m_dev.IsFrontPanelEnabled()) {
			System.out.println("FrontPanel support is not available.");
			return(false);
		}
		
		System.out.println("FrontPanel support is available.");

		return(true);
	}

	public void SetKey(byte key[])
	{
		for (int i=0; i<8; i++)
			m_dev.SetWireInValue((short)(0x0f-i), (short)key[i], (short)0xff);
		m_dev.UpdateWireIns();
	}

	public void ResetDES()
	{
		m_dev.SetWireInValue((short)0x10, (short)0xff, (short)0x01);
		m_dev.UpdateWireIns();
		m_dev.SetWireInValue((short)0x10, (short)0x00, (short)0x01);
		m_dev.UpdateWireIns();
	}

	private void EncryptDecrypt(String infile, String outfile)
	{
		FileInputStream fileIn;
		FileOutputStream fileOut;
		try 
		{
			fileIn = new FileInputStream(infile);
			fileOut = new FileOutputStream(outfile);
		}
		catch (FileNotFoundException ex)
		{
			return;
		}

		byte [] buf = new byte[2048];

		// Reset the RAM address pointer.
		m_dev.ActivateTriggerIn((short)0x41, (short)0);

		int got, len, i;
		got = 0;
		while (true) 
		{
			try 
			{
				got = fileIn.read(buf);
			}
			catch (IOException ex)
			{
				return;
			}

			if (got == -1)
				return;

			if (got < 2048)
				for (i=got; i<2048; buf[i++]=0);

			// Write a block of data.
			m_dev.ActivateTriggerIn((short)0x41, (short)0);
			m_dev.WriteToPipeIn((short)0x80, 2048, buf);

			// Perform DES on the block.
			m_dev.ActivateTriggerIn((short)0x40, (short)0);

			// Wait for the TriggerOut indicating DONE.
			for (i=0; i<10; i++) 
			{
				m_dev.UpdateTriggerOuts();
				if (m_dev.IsTriggered((short)0x60, (short)1))
					break;
			}

			len = 2048;
			m_dev.ReadFromPipeOut((short)0xa0, len, buf);

			try 
			{
				fileOut.write(buf);
			}
			catch (IOException ex)
			{
			}
		}
	}

	public void Encrypt(String infile, String outfile)
	{
		System.out.println("Encrypting " + infile + " ---> " + outfile);

		// Set the encrypt Wire In.
		m_dev.SetWireInValue((short)0x10, (short)0x00, (short)0x10);
		m_dev.UpdateWireIns();

		EncryptDecrypt(infile, outfile);
	}

	public void Decrypt(String infile, String outfile)
	{
		System.out.println("Decrypting " + infile + " ---> " + outfile);

		// Set the decrypt Wire In.
		m_dev.SetWireInValue((short)0x10, (short)0xff, (short)0x10);
		m_dev.UpdateWireIns();

		EncryptDecrypt(infile, outfile);
	}


	public static void main(String argv[])
	{
		System.out.println("------ DES Encrypt/Decrypt Tester in Java ------");

		DESTester des = new DESTester();
		if (false == des.InitializeDevice())
			return;
		des.ResetDES();

		if (argv.length != 4) {
			System.out.println("Usage: DESTester [d|e] key infile outfile");
			System.out.println("   [d|e]   - d to decrypt the input file.  e to encrypt it.");
			System.out.println("   key     - 64-bit hexadecimal string used for the key.");
			System.out.println("   infile  - an input file to encrypt/decrypt.");
			System.out.println("   outfile - destination output file.");
		}

		// Get the hex digits entered as the key
		byte key[] = new byte[8];
		String strkey = argv[1];
		for (int i=0; i<8; i++)
			key[i] = Byte.parseByte(strkey.substring(i*2, i*2+2));
		des.SetKey(key);

		// Encrypt or decrypt
		if (argv[0].charAt(0) == 'd') 
			des.Decrypt(argv[2], argv[3]);
		else
			des.Encrypt(argv[2], argv[3]);
	}
}
