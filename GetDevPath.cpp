

#include <iostream>
#include <windows.h>
#include <winusb.h>
#include <setupapi.h>
#include <tchar.h>
#include <strsafe.h>
#include <initguid.h>

using namespace std;

HANDLE h;
WINUSB_INTERFACE_HANDLE hIf;

BOOL GetDevicePath (const GUID* InterfaceClassGuid, LPTSTR& lpDevicePath, DWORD 
dwMemberIndex)
{
	BOOL bSuccess;

	SP_DEVICE_INTERFACE_DATA DeviceInterfaceData;

	// Get handle to a device information set
	HDEVINFO hdevClassInfo = SetupDiGetClassDevs (InterfaceClassGuid, NULL, NULL, 
		DIGCF_PRESENT | DIGCF_DEVICEINTERFACE);
	if (hdevClassInfo == INVALID_HANDLE_VALUE) { 
		printf ("Error retrieving device information set for given GUID\n");
	}

	DWORD dwMembers;
	for (dwMembers = 0; TRUE; dwMembers++)
	{
		DeviceInterfaceData.cbSize = sizeof (SP_INTERFACE_DEVICE_DATA);

		//printf("SetupDiEnumDeviceInterfaces\n");
		bSuccess = SetupDiEnumDeviceInterfaces (hdevClassInfo, NULL, 
		InterfaceClassGuid, dwMembers, &DeviceInterfaceData);

		if (!bSuccess) {
			// Check if last item
			if (GetLastError () == ERROR_NO_MORE_ITEMS);
				//printf("No More Items\n");
			break;
		} else {
			
		}
	}

	if (dwMemberIndex < dwMembers) {

		DeviceInterfaceData.cbSize = sizeof (SP_INTERFACE_DEVICE_DATA);

		bSuccess = SetupDiEnumDeviceInterfaces(hdevClassInfo, NULL, 
		InterfaceClassGuid, dwMemberIndex, &DeviceInterfaceData);
		
		if (bSuccess) {

			DWORD dwRequiredSize;

			// Retrieve the size of the device data
			bSuccess = SetupDiGetDeviceInterfaceDetail (hdevClassInfo, 
			&DeviceInterfaceData, NULL, 0, &dwRequiredSize, NULL);

			// This function is expected to fail
			bSuccess = !bSuccess;

			if (bSuccess) {
				printf("Size of device detail data is: %i\n", dwRequiredSize);

				// Allocate memory for the device detail buffer
				PSP_INTERFACE_DEVICE_DETAIL_DATA pBuffer = 
				(PSP_INTERFACE_DEVICE_DETAIL_DATA) malloc (dwRequiredSize);
				if (pBuffer) { 

					SP_DEVINFO_DATA DevInfoData;

					// Initialize cbSize members, required by function call
					pBuffer->cbSize = sizeof (SP_DEVICE_INTERFACE_DETAIL_DATA);
					DevInfoData.cbSize = sizeof (SP_DEVINFO_DATA);

					bSuccess = SetupDiGetDeviceInterfaceDetail (hdevClassInfo, 
					&DeviceInterfaceData, pBuffer, dwRequiredSize, NULL, &DevInfoData);

					if (bSuccess) { 
						size_t nLength = strlen(pBuffer->DevicePath) + 1;

						lpDevicePath = (LPTSTR)malloc (nLength * sizeof(TCHAR));

						if (lpDevicePath) {
							StringCchCopy (lpDevicePath, nLength, pBuffer->DevicePath);
						}
						else {
							bSuccess = FALSE;
						}
					}
					else {
						printf("Error retrieving device interface detail.\n");
					}

					free (pBuffer);
				}
				else {
					printf ("Failed to allocate memory for the device detail data.\n");

					bSuccess = FALSE;
				}
			}
		}
	}

	return bSuccess;
}


//DEFINE_GUID(myGUID, 0xF53EB9CA, 0x9486, 0x47CB, 0x8D, 0x79, 0x5F, 0x1E, 0x1C, 0xD3, 0x18, 0x45);

#define DeviceHandle hDev

static void pause() { getc(stdin); }
	
GUID ig;		

int main(int argc, char *argv[]){
	LPTSTR myDevicePath = NULL;
	HANDLE hDev = NULL;
	WINUSB_INTERFACE_HANDLE WinUsbDeviceHandle = NULL;
	WINUSB_PIPE_INFORMATION pipeInfo;
	unsigned char deviceDescriptor[18];
	int i = 0;
	int pipeIndex = 0;
	int pipeToDevice, pipeFromDevice;
	unsigned char packet[64];
	unsigned long bytesWritten;
	unsigned long bytesRead;
	char *s="{a5dcbf10-6530-11d2-901f-00c04fb951ed}                 ";



	
	if (argc<2) {
		printf("USAGE: %s InterfaceGUID [/t]\n\nEXAMPLE: %s {f53eb9ca-9486-47cb-8d79-5f1e1cd31845}\n\n",argv[0],argv[0]);		
		Sleep(1000);
		return -1;
	}

	
	sscanf(argv[1],"{%x-%x-%x-%2x%2x-%2x%2x%2x%2x%2x%2x",&ig.Data1,&ig.Data2,&ig.Data3,
		&ig.Data4[0], &ig.Data4[1], &ig.Data4[2], &ig.Data4[3], &ig.Data4[4], &ig.Data4[5], &ig.Data4[6], &ig.Data4[7]);

	printf("\nLooking for interface {%08x-%04x-%04x-%x02x%02x-%02x%02x%02x%02x%02x%02x}\n",ig.Data1,ig.Data2,ig.Data3,
		ig.Data4[0], ig.Data4[1], ig.Data4[2], ig.Data4[3], ig.Data4[4], ig.Data4[5], ig.Data4[6], ig.Data4[7]);
	

	
	if(GetDevicePath(&ig, myDevicePath, 0)) {
		printf("GetDevicePath succeeded!\nDEVICE PATH FOUND:\n%s\n\nTesting...\n",myDevicePath);
		// \\?\usb#vid_1234&pid_000f#123412340000#{e6603915-7fef-4768-98b6-7cac5301af93}
	} else {
		printf("GetDevicePath failed miserably.\n");
		return -1;
	}


	hDev = CreateFile(myDevicePath, GENERIC_WRITE | GENERIC_READ, FILE_SHARE_WRITE | FILE_SHARE_READ,
			NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL | FILE_FLAG_OVERLAPPED, NULL);
							
	if ( DeviceHandle == INVALID_HANDLE_VALUE ){
		DWORD Error = GetLastError();
		printf("Can't get Device Handle. Perhaps the device is in use by another program.\n");
		return -1;
	}

	if (!WinUsb_Initialize( DeviceHandle, &WinUsbDeviceHandle) ){
		printf("WinUSB Init Failed\n");
		return -1;
	}
	
	Sleep(50);
	
	if (!WinUsb_GetDescriptor (WinUsbDeviceHandle, USB_DEVICE_DESCRIPTOR_TYPE, 0,
		0x0409, deviceDescriptor, 18, &bytesRead ))	{
		printf("Cannot read descriptor");	
		return -1;	
	}else{	
		printf("Vendor Id: %02x%02x, Product Id: %02x%02x\n",
			deviceDescriptor[9],deviceDescriptor[8],deviceDescriptor[11],deviceDescriptor[10]);
	}
							
	while (WinUsb_QueryPipe(WinUsbDeviceHandle,/*AltIntN*/0,/*InterfaceIndex*/pipeIndex++,&pipeInfo)){
		printf("Pipe %d: Endpoint %02x, Type:%d, MaxPacketSize: %d\n",(pipeIndex-1),pipeInfo.PipeId,pipeInfo.PipeType,pipeInfo.MaximumPacketSize);
		if (USB_ENDPOINT_DIRECTION_IN(pipeInfo.PipeId)) pipeFromDevice = pipeInfo.PipeId;
		if (USB_ENDPOINT_DIRECTION_OUT(pipeInfo.PipeId)) pipeToDevice = pipeInfo.PipeId;
		//WinUsb_ResetPipe(WinUsbDeviceHandle, pipeInfo.PipeId);
	}
	
	if (argc<3) {
		printf("/t argument not found, skipping pcaket IO test.\n\Done.\n\n");
		return 0;
	}
	
	// Test packet IO		
	// Put some data into the packet
	for (int i=0; i<sizeof(packet); i++) packet[i] = i&0xff;

	// Write Packet
	printf("Writing packet...\n");
	WinUsb_WritePipe(WinUsbDeviceHandle, pipeToDevice, packet, sizeof(packet), &bytesWritten, NULL);

	// Read Packet
	printf("Reading packet...\n");
	WinUsb_ReadPipe(WinUsbDeviceHandle, pipeFromDevice, packet, sizeof(packet), &bytesRead, NULL);
	
	printf("%ld bytes read: ",bytesRead);
	for (i=0; i<bytesRead; i++) {
		printf("%02x ",packet[i]);
	}
	printf("\n");
	
	printf("Done.\n\n");	
}


