unit DWTemperature;

{-------------------------------------------------------------------}
{                    Unit:    DWTemperature.pas                     }
{                    Project: EPA SWMM Module SWMM-HEAT             }
{                    Version: 5.2                                   }
{                    Date:    20/02/25    (5.2.4)                   }
{                    Author:  L. Rossman (original)                 }
{                                                                   }
{   Dialog form unit used to edit a SWMM-HEAT WTEMPERATURE object   }
{   and its properties. Extended from Dpollut.pas.                  }
{-------------------------------------------------------------------}

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, StdCtrls, ExtCtrls, Uproject, Uglobals, Uutils, PropEdit;

type
  TWTemperatureForm = class(TForm)
    Panel1: TPanel;
    Panel2: TPanel;
    OKBtn: TButton;
    CancelBtn: TButton;
    HelpBtn: TButton;
    Panel3: TPanel;
    HintLabel: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure OKBtnClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    { Private declarations }
    PropEdit1: TPropEdit;
    PropList: TStringlist;
    WTemperatureIndex: Integer;
    procedure ShowPropertyHint(Sender: TObject; aRow: LongInt);
    procedure ValidateEntry(Sender: TObject; Index: Integer; var S: String;
              var Errmsg: String; var IsValid: Boolean);
    function ValidateName: Boolean;
  public
    { Public declarations }
    HasChanged: Boolean;
    procedure SetData(const Index: Integer; WTemp: TWTemperature);
    procedure GetData(var S: String; WTemp: TWTemperature);
  end;

implementation

{$R *.DFM}

const
  TXT_PROPERTY = 'Property';
  TXT_VALUE = 'Value';
  MSG_NO_DATA = 'This data field cannot be blank.';
  MSG_INVALID_NAME = 'Invalid WTEMPERATURE object name.';
  MSG_DUPLICATE_NAME = 'Duplicate WTEMPERATURE object name.';

  DefaultProps: array[0..7] of String =
    ('', 'CELSIUS', '0.0', '0.0', '0.0', '0.0', '0.0', '0.0');

   WTemperatureHint: array[0..7] of String =
    ('User-assigned name of the WTEMPERATURE object.',
     'Temperature units for the WTEMPERATURE object.',
     'Temperature of the water in rain water.',
     'Temperature of the water in ground water.',
     'Temperature of the water in infiltration/inflow flow.',
     'Temperature of the water in dry weather sanitary flow.',
     'First-order decay coefficient of the WTEMPERATURE object (1/days).',
     'Initial Temperature of the water throughout the conveyance system.'
     );

var
  WTemperatureProps: array[0..7] of TPropRecord =
    ((Name: 'Name';         Style: esEdit;       Mask: emNoSpace;    Length: 0),
     (Name: 'Units';        Style: esComboList;  Mask: emNone;       Length: 0;
      List: 'CELSIUS'),
     (Name: 'Rain Temp..'; Style: esEdit;       Mask: emPosNumber;  Length: 0),
     (Name: 'GW Temp.';   Style: esEdit;       Mask: emPosNumber;  Length: 0),
     (Name: 'I&I Temp.';  Style: esEdit;       Mask: emPosNumber;  Length: 0),
     (Name: 'DWF Temp.';  Style: esEdit;       Mask: emPosNumber;  Length: 0),
     (Name: 'Decay Coeff.'; Style: esEdit;       Mask: emPosNumber;  Length: 0),
     (Name: 'Init. Temp.';Style: esEdit;       Mask: emPosNumber;  Length: 0)
     );

procedure TWTemperatureForm.FormCreate(Sender: TObject);
//-----------------------------------------------------------------------------
//  Form's OnCreate handler.
//-----------------------------------------------------------------------------
begin
  // Create a Property Editor
  PropEdit1 := TPropEdit.Create(self);
  with PropEdit1 do
  begin
    Parent := Panel1;
    Align := alClient;
    BorderStyle := bsNone;
    ColHeading1 := TXT_PROPERTY;
    ColHeading2 := TXT_VALUE;
    ValueColor := clNavy;
    OnValidate := ValidateEntry;
    OnRowSelect := ShowPropertyHint;
  end;

  // Create a Property stringlist
  PropList := TStringlist.Create;
end;

procedure TWTemperatureForm.FormDestroy(Sender: TObject);
//-----------------------------------------------------------------------------
//  Form's OnDestroy handler.
//-----------------------------------------------------------------------------
begin
  PropList.Free;
  PropEdit1.Free;
end;

procedure TWTemperatureForm.FormShow(Sender: TObject);
//-----------------------------------------------------------------------------
//  Form's OnShow handler.
//-----------------------------------------------------------------------------
begin
  PropEdit1.SetProps(WTemperatureProps, PropList);
  PropEdit1.Edit;
end;

procedure TWTemperatureForm.OKBtnClick(Sender: TObject);
//-----------------------------------------------------------------------------
//  OnClick handler for the OK button.
//-----------------------------------------------------------------------------
begin
  if (not PropEdit1.IsValid) or (not ValidateName) then
  begin
    ModalResult := mrNone;
    PropEdit1.Edit;
  end
  else
  begin
    HasChanged := PropEdit1.Modified;
    ModalResult := mrOK;
  end;
end;

procedure TWTemperatureForm.SetData(const Index: Integer; WTemp: TWTemperature);
//-----------------------------------------------------------------------------
//  Loads data for a specific WTEMPERATURE object into the form.
//-----------------------------------------------------------------------------
var
  K: Integer;
begin
  WTemperatureIndex := Index;
  if Index < 0 then
  begin
    for K := 0 to High(DefaultProps) do
      PropList.Add(DefaultProps[K]);
  end
  else
  begin
    PropList.Add(Project.Lists[WTEMPERATURE].Strings[Index]);
    for K := 1 to High(DefaultProps) do
      PropList.Add(WTemp.Data[K-1]);
  end;
  HasChanged := False;
end;

procedure TWTemperatureForm.GetData(var S: String; WTemp: TWTemperature);
//-----------------------------------------------------------------------------
//  Unloads data from the form into a specific WTEMPERATURE object.
//-----------------------------------------------------------------------------
var
  K: Integer;
begin
  S := PropList[0];
  for K := 1 to High(DefaultProps) do
    WTemp.Data[K-1] := PropList[K];
end;

procedure TWTemperatureForm.ValidateEntry(Sender: TObject; Index: Integer;
  var S: String; var Errmsg: String; var IsValid: Boolean);
//-----------------------------------------------------------------------------
//  Property Editor's OnValidate handler.
//-----------------------------------------------------------------------------
begin
  // Temperature & decay coeff. fields cannot be blank
  IsValid := True;
  if Index in [2, 3, 4, 5, 6] then
  begin
    if Length(Trim(S)) = 0 then
    begin
      Errmsg := MSG_NO_DATA;
      IsValid := False;
    end;
  end;
end;

function TWTemperatureForm.ValidateName: Boolean;
//-----------------------------------------------------------------------------
//  Checks for a valid WTEMPERATURE object name.
//-----------------------------------------------------------------------------
var
  S : String;
  I : Integer;
begin
  // Retrieve WTEMPERATURE object name from 1st entry of property list
  Result := True;
  S := Trim(PropList[0]);

  // Check that a unique name was entered
  if Length(S) = 0 then
  begin
    Uutils.MsgDlg(MSG_INVALID_NAME, mtError, [mbOK]);
    Result := False;
    Exit;
  end;
  with Project.Lists[WTEMPERATURE] do
  for I := 0 to Count-1 do
  begin
    if I = WTemperatureIndex then continue;
    if CompareText(S, Strings[I]) = 0 then
    begin
      Uutils.MsgDlg(MSG_DUPLICATE_NAME, mtError, [mbOK]);
      Result := False;
      Exit;
    end;
  end;
end;

procedure TWTemperatureForm.ShowPropertyHint(Sender: TObject; aRow: LongInt);
//-----------------------------------------------------------------------------
//  Property Editor's OnRowSelect handler. Displays a context-sensitive
//  hint in the form's hint panel when a new row (property) is selected. 
//-----------------------------------------------------------------------------
begin
  HintLabel.Caption := WTemperatureHint[aRow];
end;

procedure TWTemperatureForm.HelpBtnClick(Sender: TObject);
begin
  Application.HelpCommand(HELP_CONTEXT, 211360);
end;

procedure TWTemperatureForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_F1 then HelpBtnClick(Sender);
end;

end.
