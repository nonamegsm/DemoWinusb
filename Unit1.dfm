object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'First WinUSB Comms test'
  ClientHeight = 495
  ClientWidth = 596
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 304
    Width = 453
    Height = 13
    Caption = 
      'Device Path of a WinUSB Interface (for this first demo you must ' +
      'obtain with GetDevPath.exe):'
  end
  object Bevel1: TBevel
    Left = 8
    Top = 456
    Width = 577
    Height = 2
  end
  object Bevel2: TBevel
    Left = 8
    Top = 416
    Width = 577
    Height = 2
  end
  object Label2: TLabel
    Left = 8
    Top = 464
    Width = 128
    Height = 13
    Caption = 'Outgoing packet contents:'
  end
  object Label3: TLabel
    Left = 8
    Top = 368
    Width = 506
    Height = 13
    Caption = 
      '(This is the device path that corresponds to the example .INF fi' +
      'le in my computer. Yours might be similar.)'
  end
  object Label4: TLabel
    Left = 8
    Top = 400
    Width = 427
    Height = 13
    Caption = 
      'After you have successfully opened the device, you can try commu' +
      'nication with WinUSB:'
  end
  object Bevel4: TBevel
    Left = 8
    Top = 384
    Width = 577
    Height = 2
  end
  object SendPacketButton: TButton
    Left = 152
    Top = 424
    Width = 209
    Height = 25
    Caption = 'Send Packet to endpoint $01 (OUT1)'
    TabOrder = 0
    OnClick = SendPacketButtonClick
  end
  object DeviceName1: TEdit
    Left = 8
    Top = 320
    Width = 497
    Height = 21
    TabOrder = 1
  end
  object Memo1: TMemo
    Left = 8
    Top = 8
    Width = 577
    Height = 289
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object DeviceName2: TEdit
    Left = 8
    Top = 344
    Width = 497
    Height = 21
    TabOrder = 3
    Text = '\\?\usb#vid_1781&pid_aaac#{CEF494FA-29C5-4EED-AD71-BE6B48231069}'
  end
  object Open1: TButton
    Left = 512
    Top = 320
    Width = 75
    Height = 21
    Caption = 'Open'
    TabOrder = 4
    OnClick = Open1Click
  end
  object Open2: TButton
    Left = 512
    Top = 344
    Width = 75
    Height = 21
    Caption = 'Open'
    TabOrder = 5
    OnClick = Open2Click
  end
  object ReceivePacketButton: TButton
    Left = 376
    Top = 424
    Width = 209
    Height = 25
    Caption = 'Receive Packet from endpoint $81 (IN1)'
    TabOrder = 6
    OnClick = ReceivePacketButtonClick
  end
  object GetDeviceInfoButton: TButton
    Left = 8
    Top = 424
    Width = 129
    Height = 25
    Caption = 'Get Device Info'
    TabOrder = 7
    OnClick = GetDeviceInfoButtonClick
  end
  object Edit1: TEdit
    Left = 152
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 8
    Text = '$01'
  end
  object Edit2: TEdit
    Left = 208
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 9
    Text = '$02'
  end
  object Edit3: TEdit
    Left = 264
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 10
    Text = '$03'
  end
  object Edit4: TEdit
    Left = 320
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 11
    Text = '$04'
  end
  object Edit5: TEdit
    Left = 376
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 12
    Text = '$05'
  end
  object Edit6: TEdit
    Left = 432
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 13
    Text = '$06'
  end
  object Edit7: TEdit
    Left = 488
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 14
    Text = '$07'
  end
  object Edit8: TEdit
    Left = 544
    Top = 464
    Width = 41
    Height = 21
    TabOrder = 15
    Text = '$08'
  end
end
