unit usbdriver;

interface

uses Windows, SysUtils, Dialogs, Masks; // , SetupApi;

type
  THDEVINFO = THANDLE;

type
  // types for asynchronous calls
  TOperationKind = (okWrite, okRead);

  TAsync = record
    Overlapped: TOverlapped;
    Kind: TOperationKind;
    Data: Pointer;
    Size: Integer;
  end;

  PAsync = ^TAsync;

  // ------------------------------------------------------------------------------
  // GUID
  // ------------------------------------------------------------------------------
type
  P_GUID_ = ^_GUID_;

  _GUID_ = record
    Data1: DWord;
    Data2: word;
    Data3: word;
    Data4: array [0 .. 7] of Byte;
  end;

const
  (* USB GUID. *)
  USB_DRIVER_GUID: _GUID_ = (Data1: $CEF494FA; Data2: $29C5; Data3: $4EED;
    Data4: ($AD, $71, $BE, $6B, $48, $23, $10, $69));

  { *Call SetupAPI.dll * }
  SetupAPIFile = 'SetupApi.dll';

  // ------------------------------------------------------------------------------
  // SP_DEVICE_INTERFACE_DETAIL_DATA_A, *PSP_DEVICE_INTERFACE_DETAIL_DATA_A;
  // ------------------------------------------------------------------------------
type
  P_SP_INTERF_DETAIL_ = ^_SP_INTERF_DETAIL_;

  _SP_INTERF_DETAIL_ = packed record
    cbSize: DWord;
    DevPath: AnsiChar;
  end;

  // ------------------------------------------------------------------------------
  // SP_DEVICE_INTERFACE_DATA, *PSP_DEVICE_INTERFACE_DATA;
  // ------------------------------------------------------------------------------
type
  P_SP_INTERF_ = ^_SP_INTERF_;

  _SP_INTERF_ = record
    cbSize: DWord;
    Guid: _GUID_;
    Flags: DWord;
    Reserve: Pointer;
  end;

  // ------------------------------------------------------------------------------
  // SP_DEVINFO_DATA, *PSP_DEVINFO_DATA;
  // ------------------------------------------------------------------------------
type
  P_SP_INFO_ = ^_SP_INFO_;

  _SP_INFO_ = record
    cbSize: DWord;
    Guid: _GUID_;
    DevInst: DWord;
    Reserve: DWord;
  end;

  // ------------------------------------------------------------------------------
  // HANDLES for usb BulkIn/BulkOut
  // ------------------------------------------------------------------------------
var
  hMyDevice: THANDLE;
  hMyDevPipeIn: THANDLE;
  hMyDevPipeOut: THANDLE;
  mydevice: string;

function usbOpenMyDevice(): boolean;
procedure usbCloseMyDevice();
function chatch_device: Byte;
function usbRead(TimeOut: DWord; dwCount: DWord; var Buffer): Integer;
function usbWrite(TimeOut: DWord; dwCount: DWord; const Buffer): Integer;
function DeviceConnected(): boolean;

implementation

function SetupDiGetClassDevsA(Guid: P_GUID_; Enumrator: PChar; hPar: THANDLE;
  Flags: DWord): THANDLE; stdcall; external SetupAPIFile;

function SetupDiEnumDeviceInterfaces(DevInfo: THANDLE; InfoData: P_SP_INFO_;
  Guid: P_GUID_; Index: DWord; DevInterfD: P_SP_INTERF_): bool; stdcall;
  external SetupAPIFile;

function SetupDiDestroyDeviceInfoList(hPar: THANDLE): bool; stdcall;
  external SetupAPIFile;

function SetupDiGetDeviceInterfaceDetailA(DevInfo: THANDLE;
  InterData: P_SP_INTERF_; InfoDetail: P_SP_INTERF_DETAIL_; DetailSize: DWord;
  ReqSize: PDWord; InfoData: P_SP_INFO_): bool; stdcall; external SetupAPIFile;

// ------------------------------------------------------------------------------
// use SetupDiGetClassDevsA
// ------------------------------------------------------------------------------
const
  DIGCF_DEFAULT = $001;

const
  DIGCF_PRESENT = $002;

const
  DIGCF_ALLCLASSES = $004;

const
  DIGCF_PROFILE = $008;

const
  DIGCF_DEVICEINTERFACE = $010;

  // ------------------------------------------------------------------------------
  // initialization of PAsync variables used in asynchronous calls
  // ------------------------------------------------------------------------------
procedure InitAsync(var AsyncPtr: PAsync);
begin
  New(AsyncPtr);
  with AsyncPtr^ do
  begin
    FillChar(Overlapped, SizeOf(TOverlapped), 0);
    Overlapped.hEvent := CreateEvent(nil, True, FALSE, nil);
    Data := nil;
    Size := 0;
  end;
end;

// ------------------------------------------------------------------------------
// clean-up of PAsync variable
// ------------------------------------------------------------------------------
procedure DoneAsync(var AsyncPtr: PAsync);
begin
  with AsyncPtr^ do
  begin
    CloseHandle(Overlapped.hEvent);
    if Data <> nil then
      FreeMem(Data);
  end;
  Dispose(AsyncPtr);
  AsyncPtr := nil;
end;

// ------------------------------------------------------------------------------
// prepare PAsync variable for read/write operation
// ------------------------------------------------------------------------------
procedure PrepareAsync(AKind: TOperationKind; const Buffer; Count: Integer;
  AsyncPtr: PAsync);
begin
  with AsyncPtr^ do
  begin
    Kind := AKind;
    if Data <> nil then
      FreeMem(Data);
    GetMem(Data, Count);
    Move(Buffer, Data^, Count);
    Size := Count;
  end;
end;

// ------------------------------------------------------------------------------
// wait for asynchronous operation to end : TimeOut : Result = -1
// ------------------------------------------------------------------------------
function WaitForAsync(hReadOrWrite: THANDLE; TimeOut: DWord;
  var AsyncPtr: PAsync): Integer;
var
  BytesTrans: DWord;
  // Success: Boolean;
begin
  result := -1; // Signaled = WAIT_OBJECT_TIMEOUT
  if WAIT_OBJECT_0 <> WaitForSingleObject(AsyncPtr^.Overlapped.hEvent, TimeOut)
  then
    Exit;
  if not GetOverlappedResult(hReadOrWrite, AsyncPtr^.Overlapped, BytesTrans,
    FALSE) then
    Exit;
  result := BytesTrans;
end;

// ------------------------------------------------------------------------------
// perform asynchronous write operation
// ------------------------------------------------------------------------------
function WriteAsync(hWrite: THANDLE; const Buffer; Count: Integer;
  var AsyncPtr: PAsync): Integer;
var
  Success: boolean;
  BytesTrans: DWord;
begin
  result := -1;

  PrepareAsync(okWrite, Buffer, Count, AsyncPtr);

  Success := WriteFile(hWrite, Buffer, Count, BytesTrans, @AsyncPtr^.Overlapped)
    or (GetLastError = ERROR_IO_PENDING);

  // if Device is not present -- Success is FALSE !
  if not Success then
    Exit;

  result := BytesTrans; // if WriteFile is Complete at once
end;

// ------------------------------------------------------------------------------
// perform synchronous write operation
// ------------------------------------------------------------------------------
function Write(hWrite: THANDLE; TimeOut: DWord; const Buffer;
  Count: Integer): Integer;
var
  AsyncPtr: PAsync;
begin
  InitAsync(AsyncPtr);
  try
    result := WriteAsync(hWrite, Buffer, Count, AsyncPtr);
    if result = Count then
      Exit;

    result := WaitForAsync(hWrite, TimeOut, AsyncPtr);
  finally
    DoneAsync(AsyncPtr);
  end;
end;

// ------------------------------------------------------------------------------
// perform asynchronous read operation
// ------------------------------------------------------------------------------
function ReadAsync(hRead: THANDLE; var Buffer; Count: Integer;
  var AsyncPtr: PAsync): Integer;
var
  ErrorCode: DWord;
  BytesTrans: DWord;
begin
  result := -1;

  AsyncPtr^.Kind := okRead;
  PrepareAsync(okRead, Buffer, Count, AsyncPtr);

  if not ReadFile(hRead, Buffer, Count, BytesTrans, @AsyncPtr^.Overlapped) then
  begin
    ErrorCode := GetLastError;
    if (ErrorCode <> ERROR_IO_PENDING) then
    begin
      // ShowMessage(SysErrorMessage(GetLastError));
      Exit;
    end;
  end;

  result := BytesTrans;
end;

/////////////////// COUNTINUE FROM FIRST POST///////////////
// perform synchronous read operation
// ------------------------------------------------------------------------------
function Read(hRead: THANDLE; TimeOut: DWord; var Buffer;
  Count: Integer): Integer;
var
  AsyncPtr: PAsync;
begin
  InitAsync(AsyncPtr);
  try
    ReadAsync(hRead, Buffer, Count, AsyncPtr);
    result := WaitForAsync(hRead, TimeOut, AsyncPtr);
  finally
    DoneAsync(AsyncPtr);
  end;
end;

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
function OpenOneDevice(hDevInfo: THDEVINFO; DevInfoData: P_SP_INTERF_;
  var sDevNameBuf: PChar): THANDLE;
var
  iReqLen: DWord;
  iDevDataLen: DWord;
  pDevData: P_SP_INTERF_DETAIL_;
  devi: string;
begin
  result := INVALID_HANDLE_VALUE;

  iReqLen := 0;
  SetupDiGetDeviceInterfaceDetailA(hDevInfo, DevInfoData, nil, 0,
    @iReqLen, nil);

  iDevDataLen := iReqLen; // sizeof(SP_FNCLASS_DEVICE_DATA) + 512;
  try
    GetMem(pDevData, iDevDataLen);
  except
    SetupDiDestroyDeviceInfoList(hDevInfo);
    Exit;
  end;
  pDevData.cbSize := SizeOf(_SP_INTERF_DETAIL_);

  if not SetupDiGetDeviceInterfaceDetailA(hDevInfo, DevInfoData, pDevData,
    iDevDataLen, @iReqLen, nil) then
  begin
    FreeMem(pDevData);
    SetupDiDestroyDeviceInfoList(hDevInfo);
    Exit;
  end;

  StrCopy(sDevNameBuf, @pDevData.DevPath);
  devi := strpas(PChar(sDevNameBuf)) + '\MAIN';
  mydevice := devi;
  sDevNameBuf := PChar(devi);

  result := CreateFile(sDevNameBuf, GENERIC_READ or GENERIC_WRITE,
    FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, 0);

  FreeMem(pDevData);
  SetupDiDestroyDeviceInfoList(hDevInfo);
end;

function chatch_device: Byte;

var
  hDevInfo: THDEVINFO;
  deviceInfoData: _SP_INTERF_;
  nGuessCount: DWord;
  iDevIndex: DWord;
  iReqLen: DWord;
  iDevDataLen: DWord;
  pDevData: P_SP_INTERF_DETAIL_;
  devi: string;
begin
  result := $00;
  iReqLen := 0;
  hDevInfo := SetupDiGetClassDevsA(@USB_DRIVER_GUID, nil, 0, DIGCF_PRESENT or
    DIGCF_DEVICEINTERFACE);
  deviceInfoData.cbSize := SizeOf(_SP_INTERF_);
  nGuessCount := $8000;
  for iDevIndex := 0 to nGuessCount - 1 do
  begin
    if SetupDiEnumDeviceInterfaces(hDevInfo, nil, @USB_DRIVER_GUID, iDevIndex,
      @deviceInfoData) then
    begin
      SetupDiGetDeviceInterfaceDetailA(hDevInfo, @deviceInfoData, nil, 0,
        @iReqLen, nil);
      iDevDataLen := iReqLen;
      try
        GetMem(pDevData, iDevDataLen);
      except
        SetupDiDestroyDeviceInfoList(hDevInfo);
        Exit;
      end;
      pDevData.cbSize := SizeOf(_SP_INTERF_DETAIL_);

      if not SetupDiGetDeviceInterfaceDetailA(hDevInfo, @deviceInfoData,
        pDevData, iDevDataLen, @iReqLen, nil) then
      begin
        FreeMem(pDevData);
        SetupDiDestroyDeviceInfoList(hDevInfo);
        Exit;
      end;

      devi := strpas(PChar(@pDevData.DevPath));
      if devi = '' then
        Break;
      if not MatchesMask(devi, '*vid_ffff&pid_*') then
        Break;
      if MatchesMask(devi, '*vid_ffff&pid_0000*') then
        Result := $01
      else if MatchesMask(devi, '*vid_ffff&pid_0000*') then
        Result := $02
      else
        Result := $03;
    end
    else if GetLastError() = ERROR_NO_MORE_ITEMS then
      Break;
  end;
end;

// ------------------------------------------------------------------------------
function OpenUsbDevice(const pGuid: P_GUID_; sDevNameBuf: PChar): THANDLE;
var
  hDevInfo: THDEVINFO;
  deviceInfoData: _SP_INTERF_;
  nGuessCount: DWord;
  iDevIndex: DWord;
begin
  result := INVALID_HANDLE_VALUE;
  hDevInfo := SetupDiGetClassDevsA(pGuid, nil, 0, DIGCF_PRESENT or
    DIGCF_DEVICEINTERFACE);
  deviceInfoData.cbSize := SizeOf(_SP_INTERF_);
  nGuessCount := $8000;
  for iDevIndex := 0 to nGuessCount - 1 do
  begin
    if SetupDiEnumDeviceInterfaces(hDevInfo, nil, pGuid, iDevIndex,
      @deviceInfoData) then
    begin
      result := OpenOneDevice(hDevInfo, @deviceInfoData, sDevNameBuf);
      if result <> INVALID_HANDLE_VALUE then
        Break;
    end
    // No more items
    else if GetLastError() = ERROR_NO_MORE_ITEMS then
      Break;
  end;
  SetupDiDestroyDeviceInfoList(hDevInfo);
end;

// ------------------------------------------------------------------------------
function GetUsbDeviceFileName(const pGuid: P_GUID_; sDevNameBuf: PChar)
  : boolean;
var
  hDev: THANDLE;
begin
  result := FALSE;
  hDev := OpenUsbDevice(pGuid, sDevNameBuf);
  if hDev <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(hDev);
    result := True;
  end;
end;

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
function OpenMyDeviceEx(): THANDLE;
var
  DeviceName: string;
begin
  SetLength(DeviceName, 1024);
  result := OpenUsbDevice(@USB_DRIVER_GUID, PChar(DeviceName));
  // USB_DRIVER_GUID
end;

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
procedure CloseMyDeviceEx(hDev: THANDLE);
begin
  try
    if hDev <> INVALID_HANDLE_VALUE then
      CloseHandle(hDev);
  except
  end;
end;

// ------------------------------------------------------------------------------
// ------------------------------------------------------------------------------
function DeviceConnected(): boolean;
var
  hMyDev: THANDLE;
begin
  hMyDev := OpenMyDeviceEx();
  result := hMyDev <> INVALID_HANDLE_VALUE;
  CloseMyDeviceEx(hMyDev);
end;

// ------------------------------------------------------------------------------
// uses hMyDevPipeOut always
// ------------------------------------------------------------------------------
function usbWrite(TimeOut: DWord; dwCount: DWord; const Buffer): Integer;
begin
  result := usbdriver.Write(hMyDevice, TimeOut, Buffer, dwCount);
end;

// ------------------------------------------------------------------------------
// uses hMyDevPipeIn always
// ------------------------------------------------------------------------------
function usbRead(TimeOut: DWord; dwCount: DWord; var Buffer): Integer;
begin
  result := 0;
  while result = 0 do
  begin
    result := usbdriver.Read(hMyDevice, TimeOut, Buffer, dwCount);
  end; // while
end;

function usbOpenMyDevice(): boolean;
begin
  result := FALSE;

  hMyDevice := INVALID_HANDLE_VALUE;
  hMyDevice := OpenMyDeviceEx();
  if hMyDevice = INVALID_HANDLE_VALUE then
    Exit;

  result := True;
end;

procedure usbCloseMyDevice();
begin
  if hMyDevice <> INVALID_HANDLE_VALUE then
    CloseHandle(hMyDevice);
end;

end.
