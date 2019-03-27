unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, WinUsbDll;
type
  TForm1 = class(TForm)
    SendPacketButton: TButton;
    DeviceName1: TEdit;
    Memo1: TMemo;
    DeviceName2: TEdit;
    Label1: TLabel;
    Open1: TButton;
    Open2: TButton;
    ReceivePacketButton: TButton;
    GetDeviceInfoButton: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Bevel1: TBevel;
    Bevel2: TBevel;
    Label2: TLabel;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    Bevel4: TBevel;
    procedure SendPacketButtonClick(Sender: TObject);
    procedure Open1Click(Sender: TObject);
    procedure Open2Click(Sender: TObject);
    procedure ReceivePacketButtonClick(Sender: TObject);
    procedure GetDeviceInfoButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;


var
  Form1: TForm1;
  hWinUsbHandle: THandle = INVALID_HANDLE_VALUE; //Should be invalid before init.


implementation

{$R *.dfm}

procedure Info(msg:string);
begin
  Form1.Memo1.Lines.Add(timetostr(now)+': '+msg);
end;


procedure SendPacket (packetLength : Integer; var buffer : array of byte);
var
  BytesWritten: Cardinal;
  I:Integer;
  s:string;
begin
  if hWinUsbHandle = INVALID_HANDLE_VALUE then begin
    Info('Proper device handle from WinUSB is needed before communicating with device');
    Exit;
  end;
  try
    WinUsb_WritePipe (hWinUsbHandle,1,@buffer,packetLength,BytesWritten,nil);
    s := '';
    for I := 0 to BytesWritten - 1 do begin
      s := s + IntToStr(buffer[i]) + ' ';
    end;
    Info(inttostr(BytesWritten)+' byte(s) sent: '+s);
  except on E:Exception do Info('Exception caught: '+E.Message);
  end;

end;


procedure OpenWinUSBDevice(deviceName: String);
var hDevice: THandle;
begin
    Info('Trying to open '+deviceName);
    hDevice := CreateFile(
      PChar(deviceName),
      GENERIC_WRITE or GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE,
      nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_OVERLAPPED, 0);

    if hDevice = INVALID_HANDLE_VALUE then begin
      Info('Cannot get a handle for the device. Perhaps it''s not attached.');
      Exit;
    end else begin
      Info('Device opened. Device handle is $'+inttohex(Integer(hDevice),8));
    end;

    Info('Obtaining WinUSB handle based on the device handle...');
    if WinUsb_Initialize(hDevice, hWinUsbHandle) then begin
      Info('WinUSB Init Ok. WinUSB handle is $'+inttohex(Integer(hWinUsbHandle),8));
    end else begin
      Info('WinUSB Init Failed.');
      Exit;
    end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  Info('First WinUSB Communications Test by Panu-Kristian Poiksalo, 2007.');
  Info('Demo started.');
  Info('To use this demo, you need to make your USB device communicate with WinUSB and install the WinUSB Driver. '
  +'You can use the example vlsi.inf and descriptor files as a basis for your development. You need the redistributable '
  +'driver package that is officially available from the Windows Driver Kit, but you should be able to find it '
  +'floating around the net. At time of writing this I found it for instance from http://www.raccoonrezcats.com/soundcard.html '
  +'buried in the file audiostreamer.zip. The example .INF is for version 1.5 of WDF/WinUSB. '
  +#13#10#13#10'You then need to know the device path to your WinUSB device. At the time of writing this '
  +'there is no delphi code to search for the device, but I have written (based on MS C++ example) a '
  +'small program (GetDevPath.exe) that finds the device path when you give the INTERFACE GUID (from the .INF file) '
  +'as a parameter for it. (note that there are 2 guids in the inf file).'
  +'The second editbox for the device path contains the device path that exists for the '
  +'device in my WinXP computer. The device path for your device might be similar. '
  +#13#10#13#10+'When you know the device path, you can use CreateFile() to get a file handle for the device. '
  +'That is converted to a WinUSB handle by a call to WinUSB_Initialize(). With that handle you can '
  +'send and receive packets to and from your device. This demo was compiled with the no-cost TurboDelphi Explorer from CodeGear.'
  +#13#10#13#10'Good luck!');


end;

procedure TForm1.GetDeviceInfoButtonClick(Sender: TObject);
var d: DESCRIPTOR;
    pipeInfo: WINUSB_PIPE_INFORMATION;
    bytesRead:Cardinal;
    i: Cardinal;
begin
  if hWinUsbHandle = INVALID_HANDLE_VALUE then begin
    Info('Proper device handle from WinUSB is needed before communicating with device');
    Exit;
  end;
  try
    Info('Get Device Descriptor...');
    WinUsb_GetDescriptor (hWinUsbHandle,1{Device Descriptor},0,$0409,@d,18,bytesRead);
    Info('Descriptor Length: '+inttostr(d.Length)+' Type: '+inttostr(d.DescriptorType));
    Info('Vendor ID: '+inttohex(d.data[7],2)+inttohex(d.data[6],2)
      +' Product ID: '+inttohex(d.data[9],2)+inttohex(d.data[8],2));

    Info('Get Pipe Info...');
    i := 0;
    while WinUsb_QueryPipe (hWinUsbHandle,0,i,@pipeInfo) do begin
      Info('Pipe '+inttostr(i)+': Endpoint=$'+inttohex(pipeInfo.PipeId,2)
        +' Type='+inttostr(i)
        +' Maximum packet length='+inttostr(pipeInfo.MaximumPacketSize)+' bytes.');
      inc(i);
    end;

  except on E:Exception do Info('Exception caught: '+E.Message);
  end;
end;

procedure TForm1.Open1Click(Sender: TObject);
begin
  OpenWinUSBDevice(DeviceName1.Text);
end;


procedure TForm1.Open2Click(Sender: TObject);
begin
 OpenWinUSBDevice(DeviceName2.Text);
end;

procedure TForm1.SendPacketButtonClick(Sender: TObject);
var
  BytesWritten: Cardinal;
  buffer: Array[0..7] of Byte;
  I:Integer;
begin
  if hWinUsbHandle = INVALID_HANDLE_VALUE then begin
    Info('Proper device handle from WinUSB is needed before communicating with device');
    Exit;
  end;

  for I := 0 to sizeof(buffer)-1 do buffer[i] := 0;

  buffer[0] := StrToInt(Edit1.Text);
  buffer[1] := StrToInt(Edit2.Text);
  buffer[2] := StrToInt(Edit3.Text);
  buffer[3] := StrToInt(Edit4.Text);
  buffer[4] := StrToInt(Edit5.Text);
  buffer[5] := StrToInt(Edit6.Text);
  buffer[6] := StrToInt(Edit7.Text);
  buffer[7] := StrToInt(Edit8.Text);

  try
    WinUsb_WritePipe (hWinUsbHandle,1,@buffer,sizeof(buffer),BytesWritten,nil);
    Info('Packet Sent.');
  except on E:Exception do Info('Exception caught: '+E.Message);
  end;

end;



procedure TForm1.ReceivePacketButtonClick(Sender: TObject);
var
  BytesRead: Cardinal;
  buffer: Array[0..255] of Byte;
  i:Integer;
  s:String;
begin
  if hWinUsbHandle = INVALID_HANDLE_VALUE then begin
    Info('Proper device handle from WinUSB is needed before communicating with device');
    Exit;
  end;
  try
    WinUsb_ReadPipe(hWinUsbHandle,$81,@buffer,sizeof(buffer),BytesRead,nil);
    s := '';

    for i := 0 to BytesRead - 1 do s:=s+inttohex(buffer[i],2)+' ';
    Info('Data received: '+inttostr(BytesRead)+' bytes: '+s);
  except on E:Exception do Info('Exception caught: '+E.Message);
  end;

end;





{
Hi there!
This is a very very early test of communication with WinUSB using Delphi.
Obviously you need to install the WinUSB driver and make a .INF file for it for your device. Fortunately you can
use the various ready examples from web.
Currently the complete device path to a WinUSB interface is needed before communication can be tested.
I know it can be found by using the GUID of the interface, but I haven't (yet) written Delphi code to get it.
In my computer, it can be found from the registry under
HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Control\DeviceClasses by looking for the VID/PID and finding the
GUID\#\SymbolicLink key. Good luck!
}





end.


