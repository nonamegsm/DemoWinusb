unit WinUsbDll;

{Quick wrapper for WinUSB.DLL by Panu-Kristian Poiksalo}

{WARNING: Mostly untested - Only initialize, readpipe and writepipe work ok}
{License: LGPL. Assume that it doesn't work and don't blame me for any errors.}
{Most data types were manually converted from strange types to Pascal types.
Much of it was jus a quick hack. Those types that were not known or interesting
to me were guessed so don't rely on any structured type to work properly.
This is very early and very untested code. Only use it as basis for bad ideas.}

{P.S. Instead of using winusb.dll, I think someone should make a delphi
implementation for the WinUSB COM interface.}

{Version: 0.01 Date: 18.11(November).2007}


interface
uses
{$IFDEF WIN32}
  Windows, Dialogs;
{$ELSE}
  Wintypes, WinProcs, Dialogs;
{$ENDIF}

type
  HANDLE = THandle;
  PWINUSB_INTERFACE_HANDLE = ^THandle;
  WINUSB_INTERFACE_HANDLE = Handle;

  PVOID = Pointer;
  LPOVERLAPPED = Pointer;
  LONG = Cardinal;

{ #pragma pack(1) }


// not tested so don't use
type
  _WINUSB_SETUP_PACKET = record
    RequestType_UNTESTED_DO_NOT_USE: Byte;
    Request_UNTESTED_DO_NOT_USE: Byte;
    Value_UNTESTED_DO_NOT_USE: Word;
    Index_UNTESTED_DO_NOT_USE: Word;
    Length_UNTESTED_DO_NOT_USE: Word;
  end {_WINUSB_SETUP_PACKET};



  WINUSB_SETUP_PACKET = _WINUSB_SETUP_PACKET;
  PWINUSB_SETUP_PACKET = ^_WINUSB_SETUP_PACKET;

  type DESCRIPTOR = record //Generic descriptor
    Length: Byte;
    DescriptorType: Byte;
    Data : Array [0..1000] of Byte; //will crash if descriptor is longer.
  end;


{ #pragma pack() }
 type
  USBD_PIPE_TYPE = (
    UsbdPipeTypeControl,
    UsbdPipeTypeIsochronous,
    UsbdPipeTypeBulk,
    UsbdPipeTypeInterrupt  );

 type
  _WINUSB_PIPE_INFORMATION = record
    PipeType: Cardinal;
    PipeId: Word; //strange, I know, but seems to fit the data
    MaximumPacketSize: Word;
    Interval: Word; //(?)
  end {_WINUSB_PIPE_INFORMATION};

type
  WINUSB_PIPE_INFORMATION = _WINUSB_PIPE_INFORMATION;
  PWINUSB_PIPE_INFORMATION = ^_WINUSB_PIPE_INFORMATION;
  USB_INTERFACE_DESCRIPTOR = DESCRIPTOR;
  PUSB_INTERFACE_DESCRIPTOR = ^USB_INTERFACE_DESCRIPTOR;
  USB_CONFIGURATION_DESCRIPTOR = DESCRIPTOR;
  PUSB_CONFIGURATION_DESCRIPTOR = ^USB_CONFIGURATION_DESCRIPTOR;

type
  BufferArray = Array of byte;
  PBufferArray = ^BufferArray;


var
  WinUsb_Initialize: function(DeviceHandle:  HANDLE;
                              var InterfaceHandle: WINUSB_INTERFACE_HANDLE): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};


var
  WinUsb_Free_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};


var
  WinUsb_GetAssociatedInterface_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                          AssociatedInterfaceIndex:  Byte;
                                          AssociatedInterfaceHandle:  PWINUSB_INTERFACE_HANDLE): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};



var
  WinUsb_GetDescriptor: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                 DescriptorType:  Byte;
                                 Index:  Byte;
                                 LanguageID:  Word;
                                 Buffer:  PUCHAR;
                                 BufferLength:  Cardinal;
                                 var LengthTransferred: Cardinal): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_QueryInterfaceSettings_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                          AlternateInterfaceNumber:  Byte; 
                                          UsbAltInterfaceDescriptor:  PUSB_INTERFACE_DESCRIPTOR): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

var
  WinUsb_QueryDeviceInformation_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                          InformationType:  Cardinal; 
                                          BufferLength:   PULONG; 
                                          Buffer:  PVOID): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_SetCurrentAlternateSetting_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                              SettingNumber:  Byte): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

var
  WinUsb_GetCurrentAlternateSetting_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                              SettingNumber:  PUCHAR): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 


var
  WinUsb_QueryPipe: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                             AlternateInterfaceNumber:  Byte; 
                             PipeIndex:  Byte; 
                             PipeInformation: PWINUSB_PIPE_INFORMATION): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 


var
  WinUsb_SetPipePolicy_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                 PipeID:  Byte; 
                                 PolicyType:  Cardinal; 
                                 ValueLength:  Cardinal; 
                                 Value:  PVOID): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

var
  WinUsb_GetPipePolicy_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                 PipeID:  Byte; 
                                 PolicyType:  Cardinal; 
                                 ValueLength:   PULONG; 
                                 Value:  PVOID): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF}; 

var
  WinUsb_ReadPipe: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE; 
                            PipeID:  Byte; 
                            Buffer:  PBufferArray;
                            BufferLength:  Cardinal;
                            var LengthTransferred:  Cardinal;
                            Overlapped:  LPOVERLAPPED): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_WritePipe: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                             PipeID:  Byte;
                             Buffer:  PBufferArray;
                             BufferLength:  Cardinal;
                             var LengthTransferred:  Cardinal;
                             Overlapped:  LPOVERLAPPED): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_ControlTransfer_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                   SetupPacket:  WINUSB_SETUP_PACKET;
                                   Buffer:  PUCHAR;
                                   BufferLength:  Cardinal;
                                   LengthTransferred:  PULONG;
                                   Overlapped:  LPOVERLAPPED): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_ResetPipe: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                             PipeID:  Byte): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_AbortPipe_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                             PipeID:  Byte): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_FlushPipe_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                             PipeID:  Byte): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_SetPowerPolicy_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                  PolicyType:  Cardinal;
                                  ValueLength:  Cardinal;
                                  Value:  PVOID): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_GetPowerPolicy_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                  PolicyType:  Cardinal;
                                  ValueLength:   PULONG;
                                  Value:  PVOID): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};

var
  WinUsb_GetOverlappedResult_NotYetTested: function(InterfaceHandle:  WINUSB_INTERFACE_HANDLE;
                                       lpOverlapped:  LPOVERLAPPED;
                                       lpNumberOfBytesTransferred:  LPDWORD;
                                       bWait: Bool): Bool cdecl  {$IFDEF WIN32} stdcall {$ENDIF};


var
  WinUsb_ParseConfigurationDescriptor_NotYetTested: function(ConfigurationDescriptor:  PUSB_CONFIGURATION_DESCRIPTOR;
                                                StartPosition:  PVOID;
                                                InterfaceNumber:  LONG;
                                                AlternateSetting:  LONG;
                                                InterfaceClass:  LONG;
                                                InterfaceSubClass:  LONG;
                                                InterfaceProtocol: LONG
                                                )  : USB_INTERFACE_DESCRIPTOR cdecl  {$IFDEF WIN32} stdcall {$ENDIF};


  var
  WinUsb_ParseDescriptors_NotYetTested: function(DescriptorBuffer:  PVOID;
                                    TotalLength:  Cardinal;
                                    StartPosition: PVOID;
                                    DescriptorType: LONG): DESCRIPTOR cdecl  {$IFDEF WIN32} stdcall {$ENDIF};





var
  DLLLoaded: Boolean { is DLL (dynamically) loaded already? }
    {$IFDEF WIN32} = False; {$ENDIF}

implementation

var
  SaveExit: pointer;
  DLLHandle: THandle;
{$IFNDEF MSDOS}
  ErrorMode: Integer;
{$ENDIF}

  procedure NewExit; far;
  begin
    ExitProc := SaveExit;
    FreeLibrary(DLLHandle)
  end {NewExit};

procedure LoadDLL;
begin
  if DLLLoaded then Exit;
{$IFNDEF MSDOS}
  ErrorMode := SetErrorMode($8000{SEM_NoOpenFileErrorBox});
{$ENDIF}
  DLLHandle := LoadLibrary('WINUSB.DLL');
  if DLLHandle >= 32 then
  begin
    DLLLoaded := True;
    SaveExit := ExitProc;
    ExitProc := @NewExit;
    @WinUsb_Initialize := GetProcAddress(DLLHandle,'WinUsb_Initialize');
  {$IFDEF WIN32}
    Assert(@WinUsb_Initialize <> nil);
  {$ENDIF}
    @WinUsb_Free_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_Free');
  {$IFDEF WIN32}
    Assert(@WinUsb_Free_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_GetAssociatedInterface_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_GetAssociatedInterface');
  {$IFDEF WIN32}
    Assert(@WinUsb_GetAssociatedInterface_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_GetDescriptor := GetProcAddress(DLLHandle,'WinUsb_GetDescriptor');
  {$IFDEF WIN32}
    Assert(@WinUsb_GetDescriptor <> nil);
  {$ENDIF}
    @WinUsb_QueryInterfaceSettings_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_QueryInterfaceSettings');
  {$IFDEF WIN32}
    Assert(@WinUsb_QueryInterfaceSettings_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_QueryDeviceInformation_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_QueryDeviceInformation');
  {$IFDEF WIN32}
    Assert(@WinUsb_QueryDeviceInformation_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_SetCurrentAlternateSetting_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_SetCurrentAlternateSetting');
  {$IFDEF WIN32}
    Assert(@WinUsb_SetCurrentAlternateSetting_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_GetCurrentAlternateSetting_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_GetCurrentAlternateSetting');
  {$IFDEF WIN32}
    Assert(@WinUsb_GetCurrentAlternateSetting_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_QueryPipe := GetProcAddress(DLLHandle,'WinUsb_QueryPipe');
  {$IFDEF WIN32}
    Assert(@WinUsb_QueryPipe <> nil);
  {$ENDIF}
    @WinUsb_SetPipePolicy_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_SetPipePolicy');
  {$IFDEF WIN32}
    Assert(@WinUsb_SetPipePolicy_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_GetPipePolicy_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_GetPipePolicy');
  {$IFDEF WIN32}
    Assert(@WinUsb_GetPipePolicy_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_ReadPipe := GetProcAddress(DLLHandle,'WinUsb_ReadPipe');
  {$IFDEF WIN32}
    Assert(@WinUsb_ReadPipe <> nil);
  {$ENDIF}
    @WinUsb_WritePipe := GetProcAddress(DLLHandle,'WinUsb_WritePipe');
  {$IFDEF WIN32}
    Assert(@WinUsb_WritePipe <> nil);
  {$ENDIF}
    @WinUsb_ControlTransfer_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_ControlTransfer');
  {$IFDEF WIN32}
    Assert(@WinUsb_ControlTransfer_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_ResetPipe := GetProcAddress(DLLHandle,'WinUsb_ResetPipe');
  {$IFDEF WIN32}
    Assert(@WinUsb_ResetPipe <> nil);
  {$ENDIF}
    @WinUsb_AbortPipe_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_AbortPipe');
  {$IFDEF WIN32}
    Assert(@WinUsb_AbortPipe_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_FlushPipe_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_FlushPipe');
  {$IFDEF WIN32}
    Assert(@WinUsb_FlushPipe_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_SetPowerPolicy_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_SetPowerPolicy');
  {$IFDEF WIN32}
    Assert(@WinUsb_SetPowerPolicy_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_GetPowerPolicy_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_GetPowerPolicy');
  {$IFDEF WIN32}
    Assert(@WinUsb_GetPowerPolicy_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_GetOverlappedResult_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_GetOverlappedResult');
  {$IFDEF WIN32}
    Assert(@WinUsb_GetOverlappedResult_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_ParseConfigurationDescriptor_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_ParseConfigurationDescriptor');
  {$IFDEF WIN32}
    Assert(@WinUsb_ParseConfigurationDescriptor_NotYetTested <> nil);
  {$ENDIF}
    @WinUsb_ParseDescriptors_NotYetTested := GetProcAddress(DLLHandle,'WinUsb_ParseDescriptors');
  {$IFDEF WIN32}
    Assert(@WinUsb_ParseDescriptors_NotYetTested <> nil);
  {$ENDIF}
  end
  else
  begin
    DLLLoaded := False;
    ShowMessage('Error: WINUSB.DLL could not be loaded !!');
    { Error: WINUSB.DLL could not be loaded !! }
  end;
{$IFNDEF MSDOS}
  SetErrorMode(ErrorMode)
{$ENDIF}
end {LoadDLL};

begin
  LoadDLL;
end.
