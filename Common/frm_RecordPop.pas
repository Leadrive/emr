{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_RecordPop;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, EmrElementItem, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Grids,
  FireDAC.Comp.Client, FireDAC.UI.Intf, FireDAC.VCLUI.Wait, FireDAC.Stan.Intf,
  FireDAC.Comp.UI;

type
  TfrmRecordPop = class(TForm)
    pgPop: TPageControl;
    tsDomain: TTabSheet;
    btnDomainOk: TButton;
    tsNumber: TTabSheet;
    tsMemo: TTabSheet;
    tsDateTime: TTabSheet;
    sgdDomain: TStringGrid;
    pnl1: TPanel;
    lbl2: TLabel;
    edtSpliter: TEdit;
    pnl2: TPanel;
    edtvalue: TButtonedEdit;
    chkhideunit: TCheckBox;
    cbbUnit: TComboBox;
    btn1: TButton;
    btn3: TButton;
    btn4: TButton;
    btn5: TButton;
    btn6: TButton;
    btn7: TButton;
    btn8: TButton;
    btn9: TButton;
    btn0: TButton;
    btnDiv: TButton;
    btn2: TButton;
    btnAdd: TButton;
    btnDec: TButton;
    btnMul: TButton;
    btnCE: TButton;
    btnC: TButton;
    btnResult: TButton;
    btn41: TButton;
    btnDot: TButton;
    btn39: TButton;
    btn40: TButton;
    btn35: TButton;
    btn36: TButton;
    btn37: TButton;
    btn38: TButton;
    btnNumberOk: TButton;
    btn42: TButton;
    pnl3: TPanel;
    pnl4: TPanel;
    btnMemoOk: TButton;
    btnDateTimeOk: TButton;
    mmoMemo: TMemo;
    fdgxwtcrsr: TFDGUIxWaitCursor;
    pnlDate: TPanel;
    pnlTime: TPanel;
    dtpdate: TDateTimePicker;
    cbbdate: TComboBox;
    dtptime: TDateTimePicker;
    cbbtime: TComboBox;
    lblHint: TLabel;
    procedure btnDomainOkClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnDateTimeOkClick(Sender: TObject);
    procedure btnCEClick(Sender: TObject);
    procedure edtvalueKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure cbbUnitCloseUp(Sender: TObject);
    procedure cbbUnitSelect(Sender: TObject);
    procedure btnCClick(Sender: TObject);
    procedure btnNumberOkClick(Sender: TObject);
    procedure btn1Click(Sender: TObject);
    procedure btnDotClick(Sender: TObject);
    procedure btnResultClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btn35Click(Sender: TObject);
    procedure btnMemoOkClick(Sender: TObject);
  private
    { Private declarations }
    // ��������
    FSnum1, FSnum2, FSmark, FOldUnit: string;
    FNum1, FNum2{, FMark}: Real;
    FFlag, FSign, FTemp, FTemplate: Boolean;
    FConCalcValue: Boolean;  // True �����������ʱ��ԭ���ַ������� False���ԭ���������ַ�
    //
    FFrmtp: string;
    FEmrTextItem: TEmrTextItem;
    FDBDomain: TFDMemTable;
    FOnActiveItemChange: TNotifyEvent;
    procedure SetEmrElementItemValue(const AValue: string);

    procedure SetValueFocus;  // ���������ʱ�����㷵�ص���ֵ��
    procedure SetConCalcValue;  // ������������ּ�ʱ �����Ƿ�ԭֵ���������ַ�
    procedure PutCalcNumber(const ANum: Integer);
  public
    { Public declarations }
    procedure PopupEmrElement(const AEmrTextItem: TEmrTextItem);
    property OnActiveItemChange: TNotifyEvent read FOnActiveItemChange write FOnActiveItemChange;
  end;

implementation

uses
  emr_Common, emr_BLLConst, emr_BLLServerProxy;

{$R *.dfm}

function ConversionValueByUnit(const AValue, AOldUnit, ANewUnit: string): string;
var
  vOldUnit, vNewUnit: string;
  viValue{, vReValue}: Single;
begin
  Result := AValue;
  if not TryStrToFloat(AValue, viValue) then  // ֵ
    Exit;
  vOldUnit := LowerCase(AOldUnit);  // ԭʼ��λ
  vNewUnit := LowerCase(ANewUnit);  // �µ�λ
  if vOldUnit = 'mmhg' then  // �����mmHg  100mmHg=13.3kPa
  begin
    if vNewUnit = 'kpa' then
    begin
      viValue := viValue * 133.3 / 1000;
      Result := FormatFloat('#.#', viValue);
    end;
  end
  else
  if vOldUnit = 'kpa' then  // �����KPa
  begin
    if vNewUnit = 'mmhg' then
    begin
      viValue := viValue * 1000 / 133.3;
      Result := Format('%d', [Round(viValue)]);
    end;
  end
  else
  if vOldUnit = '��' then  // ������  37�� = 98.6�H
  begin
    if vNewUnit = '�H' then  // ת����
    begin
      viValue := (viValue * 9 / 5) + 32;
      Result := FormatFloat('#.#', viValue);
    end;
  end
  else
  if vOldUnit = '�H' then  // �ǻ���
  begin
    if vNewUnit = '��' then  // ת����
    begin
      viValue := (viValue - 32) * 5 / 9;
      Result := FormatFloat('#.#', viValue);
    end;
  end;
end;

function Equal(a: double; m: string; b: double): double;
var
  r: double;
begin
  if (m = '+')then
    r := a + b
  else
  if (m = '-')then
    r := a - b
  else
  if (m = '*')then
    r := a * b
  else
  if (m = '/')then
    r := a / b ;
  equal := r;
end;

procedure TfrmRecordPop.btn1Click(Sender: TObject);
begin
  PutCalcNumber((Sender as TButton).Tag);
end;

procedure TfrmRecordPop.btn35Click(Sender: TObject);
begin
  edtValue.Text := (Sender as TButton).Tag.ToString;
  FTemp := False;
  FTemplate := True;
  FConCalcValue := True;
  SetValueFocus;
end;

procedure TfrmRecordPop.btnAddClick(Sender: TObject);
begin
  if FSign then
  begin
    FSnum2 := edtValue.Text;
    if FSnum2 <> '' then
      FNum2 := StrToFloat(edtValue.Text) ;
    if(FSmark = '/') and (FNum2 = 0) then
    begin
      //lblPop.Caption := '��������Ϊ0';
      FNum1 := 0;
      FSmark := '';
      FNum2 := 0
    end
    else
    edtValue.Text := FloatToStr(equal(FNum1, FSmark, FNum2));
    FFlag := True;
  end;
  FSnum1 := edtValue.Text;
  if FSnum1 <> '' then
    FNum1 := StrToFloat(FSnum1)
  else
  begin
    FNum1 := 0;
  end;
  FSmark := (Sender as TButton).Caption;
  FFlag := False;
  FSign := True;
  FTemp := FSign;
  SetValueFocus;
end;

procedure TfrmRecordPop.btnCClick(Sender: TObject);
var
  vS: string;
begin
  vS := edtValue.Text;
  if FFlag then
    edtValue.Text := ''
  else
  begin
    vS := Copy(vS, 0, Length(vS) - 1);
    edtValue.Text := vS;
  end;
  SetValueFocus;
end;

procedure TfrmRecordPop.btnCEClick(Sender: TObject);
begin
  edtValue.Text := '';
  FNum1 := 0;
  FSmark := '';
  FNum2 := 0;
  FTemplate := False;
  SetValueFocus;
end;

procedure TfrmRecordPop.btnDateTimeOkClick(Sender: TObject);
var
  vText: string;
begin
  if FFrmtp = TDeFrmtp.Date then
    vText := FormatDateTime(cbbdate.Text, dtpdate.Date)
  else
  if FFrmtp = TDeFrmtp.Time then
    vText := FormatDateTime(cbbtime.Text, dtptime.Time)
  else
  if FFrmtp = TDeFrmtp.DateTime then
  begin
    dtpdate.Time := dtptime.Time;
    vText := FormatDateTime(cbbdate.Text + ' ' + cbbtime.Text, dtpdate.DateTime);
  end;

  if vText <> '' then
  begin
    SetEmrElementItemValue(vText);
    Close;
  end;
end;

procedure TfrmRecordPop.btnDomainOkClick(Sender: TObject);
begin
  if sgdDomain.Row > 0 then
  begin
    FEmrTextItem[TDeProp.CMVVCode] := sgdDomain.Cells[1, sgdDomain.Row];
    SetEmrElementItemValue(sgdDomain.Cells[0, sgdDomain.Row]);
    Close;
  end;
end;

procedure TfrmRecordPop.btnDotClick(Sender: TObject);
begin
  edtValue.Text := edtValue.Text + '.';
  SetValueFocus;
end;

procedure TfrmRecordPop.btnMemoOkClick(Sender: TObject);
begin
  SetEmrElementItemValue(mmoMemo.Text);
  Close;
end;

procedure TfrmRecordPop.btnNumberOkClick(Sender: TObject);
var
  vText: string;
begin
  if chkhideunit.Checked then
    vText := edtValue.Text
  else
    vText := edtValue.Text + cbbUnit.Text;

  FEmrTextItem[TDeProp.&Unit] := cbbUnit.Text;

  SetEmrElementItemValue(vText);
  Close;
end;

procedure TfrmRecordPop.btnResultClick(Sender: TObject);
begin
  if FFlag then
    edtValue.Text := FloatToStr(Equal(StrToFloat(edtValue.Text), FSmark, FNum2))
  else
  begin
    if (FSmark = '') then
      edtValue.text := edtValue.text
    else
    begin
      FSnum2 := edtValue.Text;
      if (FSnum2 <> '') then
        FNum2 := StrToFloat(edtValue.Text)
      else
        FNum2 := FNum1;
      if ((FSmark = '/') and (FNum2 = 0)) then
      begin
        //lblPop.Caption := '��������Ϊ0';
        FNum1 := 0;
        FSmark := '';
        FNum2 := 0
      end
      else
      edtValue.Text := FloatToStr(Equal(FNum1, FSmark, FNum2));
      FFlag := true;
      FSign := False;
      FTemp := true;
    end;
  end;
  SetValueFocus;
end;

procedure TfrmRecordPop.cbbUnitCloseUp(Sender: TObject);
begin
  FOldUnit := cbbUnit.Text;
end;

procedure TfrmRecordPop.cbbUnitSelect(Sender: TObject);
begin
  if Trim(edtvalue.Text) <> '' then
    edtvalue.Text := ConversionValueByUnit(edtvalue.Text, FOldUnit, cbbUnit.Text);
end;

procedure TfrmRecordPop.edtvalueKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    btnNumberOk.Click;
    Key := 0;
  end;
end;

procedure TfrmRecordPop.FormCreate(Sender: TObject);
var
  i: Integer;
begin
  FDBDomain := TFDMemTable.Create(Self);

  for i := 0 to pgPop.PageCount - 1 do
    pgPop.Pages[i].TabVisible := False;  // ���ر�ǩ
end;

procedure TfrmRecordPop.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FDBDomain);
end;

procedure TfrmRecordPop.PopupEmrElement(const AEmrTextItem: TEmrTextItem);

  {$REGION 'IniDomainUI ��ʾֵ��'}
  procedure IniDomainUI;
  var
    vRow: Integer;
  begin
    sgdDomain.RowCount := FDBDomain.RecordCount + 1;
    sgdDomain.ColWidths[0] := 120;
    sgdDomain.ColWidths[1] := 40;
    sgdDomain.ColWidths[2] := 25;
    sgdDomain.ColWidths[3] := 25;

    sgdDomain.Cells[0, 0] := 'ֵ';
    sgdDomain.Cells[1, 0] := '����';
    sgdDomain.Cells[2, 0] := 'ID';
    sgdDomain.Cells[3, 0] := 'ƴ��';

    vRow := 0;
    FDBDomain.First;
    while not FDBDomain.Eof do
    begin
      Inc(vRow);

      sgdDomain.Cells[0, vRow] := FDBDomain.FieldByName('devalue').AsString;
      sgdDomain.Cells[1, vRow] := FDBDomain.FieldByName('code').AsString;
      sgdDomain.Cells[2, vRow] := FDBDomain.FieldByName('id').AsString;
      sgdDomain.Cells[3, vRow] := FDBDomain.FieldByName('py').AsString;

      FDBDomain.Next;
    end;

    if sgdDomain.RowCount > 0 then
      sgdDomain.FixedRows := 1;
  end;
  {$ENDREGION}

var
  vDeUnit: string;
  vCMV: Integer;
begin
  FFrmtp := '';
  FEmrTextItem := AEmrTextItem;
  lblHint.Caption := FEmrTextItem[TDeProp.Name] + '(' + FEmrTextItem[TDeProp.Index] + ')';

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETDEPROPERTY;  // ��ȡָ������Ԫ��������Ϣ
      ABLLServerReady.ExecParam.I['deid'] := StrToInt(FEmrTextItem[TDeProp.Index]);
      ABLLServerReady.AddBackField('frmtp');
      ABLLServerReady.AddBackField('deunit');
      ABLLServerReady.AddBackField('domainid');
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // ����˷�������ִ�гɹ�
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      FFrmtp := ABLLServer.BackField('frmtp').AsString;
      vDeUnit := ABLLServer.BackField('deunit').AsString;
      vCMV := ABLLServer.BackField('domainid').AsInteger;
    end);

    // �������չʾ����
    if FFrmtp = TDeFrmtp.Number then  // ��ֵ
    begin
      edtvalue.Clear;
      pgPop.ActivePageIndex := 1;
      Self.Width := 195;
      Self.Height := 315;
    end
    else
    if (FFrmtp = TDeFrmtp.Date)
      or (FFrmtp = TDeFrmtp.Time)
      or (FFrmtp = TDeFrmtp.DateTime)
    then  // ����ʱ��
    begin
      pgPop.ActivePageIndex := 3;
      Self.Width := 260;
      Self.Height := 170;

      pnlDate.Visible := FFrmtp <> TDeFrmtp.Time;
      pnlTime.Visible := FFrmtp <> TDeFrmtp.Date;
    end
    else
    if (FFrmtp = TDeFrmtp.Radio) or (FFrmtp = TDeFrmtp.Multiselect) then  // ������ѡ
    begin
      edtSpliter.Clear;

      if FDBDomain.Active then
        FDBDomain.EmptyDataSet;

      sgdDomain.RowCount := 0;
      pgPop.ActivePageIndex := 0;
      Self.Width := 260;
      Self.Height := 300;

      if vCMV > 0 then
      begin
        BLLServerExec(
          procedure(const ABLLServerReady: TBLLServerProxy)
          begin
            ABLLServerReady.Cmd := BLL_GETDATAELEMENTDOMAIN;  // ��ȡ����Ԫֵ��ѡ��
            ABLLServerReady.ExecParam.I['domainid'] := vCMV;
            ABLLServerReady.BackDataSet := True;
          end,
          procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
          begin
            if not ABLLServer.MethodRunOk then  // ����˷�������ִ�гɹ�
            begin
              ShowMessage(ABLLServer.MethodError);
              Exit;
            end;

            if AMemTable <> nil then
              FDBDomain.CloneCursor(AMemTable, True);
          end);
      end;

      if FDBDomain.Active then
        IniDomainUI;
    end
    else
    if FFrmtp = TDeFrmtp.String then
    begin
      mmoMemo.Clear;
      pgPop.ActivePageIndex := 2;
      Self.Width := 260;
      Self.Height := 200;
    end;

  if not Visible then
    Show;
end;

procedure TfrmRecordPop.PutCalcNumber(const ANum: Integer);
begin
  if FTemplate then
  begin
    if ANum <> 0 then
      edtvalue.Text := edtvalue.Text + '.' + ANum.ToString
  end
  else
  begin
    SetConCalcValue;
    if FTemp or FFlag then
    begin
      edtValue.Text := ANum.ToString;
      FTemp := False;
    end
    else
      edtValue.Text := edtValue.text + ANum.ToString;
  end;
  SetValueFocus;
end;

procedure TfrmRecordPop.SetConCalcValue;
begin
  if not FConCalcValue then
  begin
    edtValue.Text := '';
    FConCalcValue := True;
  end;
end;

procedure TfrmRecordPop.SetEmrElementItemValue(const AValue: string);
begin
  FEmrTextItem.Text := AValue;
  if Assigned(FOnActiveItemChange) then
    FOnActiveItemChange(FEmrTextItem);  // ��������,�������Ա仯���õ��ô˷���
end;

procedure TfrmRecordPop.SetValueFocus;
begin
  edtValue.SetFocus;
  edtvalue.SelStart := Length(edtvalue.Text);
  edtvalue.SelLength := 0;
end;

end.
