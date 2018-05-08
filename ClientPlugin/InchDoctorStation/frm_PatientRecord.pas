{*******************************************************}
{                                                       }
{         ����HCView�ĵ��Ӳ�������  ���ߣ���ͨ          }
{                                                       }
{ �˴������ѧϰ����ʹ�ã�����������ҵĿ�ģ��ɴ�������  }
{ �����ʹ���߳е�������QQȺ 649023932 ����ȡ����ļ��� }
{ ������                                                }
{                                                       }
{*******************************************************}

unit frm_PatientRecord;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, frm_RecordEdit, Vcl.ExtCtrls,
  Vcl.ComCtrls, emr_Common, Vcl.Menus, HCCustomData, System.ImageList,
  Vcl.ImgList, EmrElementItem, EmrGroupItem, HCDrawItem, Vcl.StdCtrls;

type
  TTraverse = class(TObject)
  public
    const
      ReplaceElement = 0;  // ģ����غ��滻��Ԫ��
      CheckContent = 1;  // ����ʱУ��Ԫ��
      ShowTrace = 2;  // ��ʾ�ۼ�����
  end;

  TfrmPatientRecord = class(TForm)
    spl1: TSplitter;
    pgRecordEdit: TPageControl;
    tsHelp: TTabSheet;
    tvRecord: TTreeView;
    pmRecord: TPopupMenu;
    mniNew: TMenuItem;
    pmpg: TPopupMenu;
    mniCloseRecordEdit: TMenuItem;
    mniEdit: TMenuItem;
    mniDelete: TMenuItem;
    mniView: TMenuItem;
    mniPreview: TMenuItem;
    il: TImageList;
    mniN1: TMenuItem;
    mniN2: TMenuItem;
    pnl1: TPanel;
    btn1: TButton;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure mniNewClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tvRecordExpanding(Sender: TObject; Node: TTreeNode;
      var AllowExpansion: Boolean);
    procedure tvRecordDblClick(Sender: TObject);
    procedure pgRecordEditMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure mniCloseRecordEditClick(Sender: TObject);
    procedure mniEditClick(Sender: TObject);
    procedure mniViewClick(Sender: TObject);
    procedure mniDeleteClick(Sender: TObject);
    procedure mniPreviewClick(Sender: TObject);
    procedure pmRecordPopup(Sender: TObject);
    procedure mniN2Click(Sender: TObject);
    procedure btn1Click(Sender: TObject);
  private
    { Private declarations }
    FPatientInfo: TPatientInfo;
    FOnCloseForm: TNotifyEvent;
    procedure ReplaceTemplateElement(const ARecordEdit: TfrmRecordEdit);
    procedure DoTraverseItem(const AData: THCCustomData;
      const AItemNo, ATag: Integer; var AStop: Boolean);
    procedure ClearRecordNode;
    procedure RefreshRecordNode;
    procedure DoSaveRecordContent(Sender: TObject);
    procedure DoRecordChangedSwitch(Sender: TObject);
    procedure DoRecordReadOnlySwitch(Sender: TObject);

    function GetRecordEditPageIndex(const ARecordID: Integer): Integer;
    function GetPageRecordEdit(const APageIndex: Integer): TfrmRecordEdit;
    procedure CloseRecordEditPage(const APageIndex: Integer;
      const ASaveChange: Boolean = True);

    function GetPatientNode: TTreeNode;

    procedure GetPatientRecordListUI;
    procedure EditPatientDeSet(const ADeSetID, ARecordID: Integer);

    procedure LoadPatientDeSetContent(const ADeSetID: Integer);
    procedure LoadPatientRecordContent(const ARecordID: Integer);
    procedure DeletePatientRecord(const ARecordID: Integer);

    procedure GetNodeRecordInfo(const ANode: TTreeNode; var ADeSetPID, ARecordID: Integer);

    /// <summary> �򿪽ڵ��Ӧ�Ĳ���(�����༭�������أ�������������) </summary>
    procedure OpenPatientDeSet(const ADeSetID, ARecordID: Integer);

    /// <summary> ����ָ��������Ӧ�Ľڵ� </summary>
    function FindRecordNode(const ARecordID: Integer): TTreeNode;

    /// <summary> ����ĵ����� </summary>
    procedure CheckRecordContent(const ARecordEdit: TfrmRecordEdit);
  public
    { Public declarations }
    UserInfo: TUserInfo;
    property OnCloseForm: TNotifyEvent read FOnCloseForm write FOnCloseForm;
    property PatientInfo: TPatientInfo read FPatientInfo;
  end;

var
  frmPatientRecord: TfrmPatientRecord;

implementation

uses
  DateUtils, HCCommon, HCDataCommon, HCStyle, HCParaStyle, EmrView,
  emr_BLLServerProxy, emr_BLLConst, FireDAC.Comp.Client, frm_TemplateList, Data.DB;

{$R *.dfm}

var
  FTraverseDT: TDateTime;

procedure TfrmPatientRecord.btn1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmPatientRecord.CheckRecordContent(
  const ARecordEdit: TfrmRecordEdit);
var
  vItemTraverse: TItemTraverse;
begin
  FTraverseDT := TBLLServer.GetServerDateTime;
  vItemTraverse := TItemTraverse.Create;
  try
    vItemTraverse.Tag := TTraverse.CheckContent;
    vItemTraverse.Process := DoTraverseItem;
    ARecordEdit.EmrView.TraverseItem(vItemTraverse);
  finally
    vItemTraverse.Free;
  end;
  ARecordEdit.EmrView.FormatData;
end;

procedure TfrmPatientRecord.ClearRecordNode;
var
  i: Integer;
  vNode: TTreeNode;
begin
  for i := 0 to tvRecord.Items.Count - 1 do
  begin
    //ClearTemplateGroupNode(tvTemplate.Items[i]);
    vNode := tvRecord.Items[i];
    if vNode <> nil then
    begin
      if TreeNodeIsRecordDeSet(vNode) then
        TRecordDeSetInfo(vNode.Data).Free
      else
        TRecordInfo(vNode.Data).Free;
    end;
  end;

  tvRecord.Items.Clear;
end;

procedure TfrmPatientRecord.CloseRecordEditPage(const APageIndex: Integer;
  const ASaveChange: Boolean);
var
  i: Integer;
  vPage: TTabSheet;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if APageIndex >= 0 then
  begin
    vPage := pgRecordEdit.Pages[APageIndex];

    for i := 0 to vPage.ControlCount - 1 do
    begin
      if vPage.Controls[i] is TfrmRecordEdit then
      begin
        if ASaveChange and (vPage.Tag > 0) then  // ��Ҫ���䶯���ǲ���
        begin
          vfrmRecordEdit := (vPage.Controls[i] as TfrmRecordEdit);
          if vfrmRecordEdit.EmrView.IsChanged then  // �б䶯
          begin
            if MessageDlg('�Ƿ񱣴没�� ' + TRecordInfo(vfrmRecordEdit.ObjectData).NameEx + ' ��',
              mtWarning, [mbYes, mbNo], 0) = mrYes
            then
            begin
              DoSaveRecordContent(vfrmRecordEdit);
            end;
          end;
        end;

        vPage.Controls[i].Free;
        Break;
      end;
    end;
    
    vPage.Free;

    if APageIndex > 0 then
      pgRecordEdit.ActivePageIndex := APageIndex - 1;
  end;
end;

procedure TfrmPatientRecord.DeletePatientRecord(const ARecordID: Integer);
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_DELETEINCHRECORD;  // ɾ��ָ����סԺ����
      ABLLServerReady.ExecParam.I['RID'] := ARecordID;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // ����˷�������ִ�в��ɹ�
        raise Exception.Create(ABLLServer.MethodError);
    end);
end;

procedure TfrmPatientRecord.DoRecordChangedSwitch(Sender: TObject);
var
  vText: string;
begin
  if (Sender is TfrmRecordEdit) then
  begin
    if (Sender as TfrmRecordEdit).Parent is TTabSheet then
    begin
      if (Sender as TfrmRecordEdit).EmrView.IsChanged then
        vText := TRecordInfo((Sender as TfrmRecordEdit).ObjectData).NameEx + '*'
      else
        vText := TRecordInfo((Sender as TfrmRecordEdit).ObjectData).NameEx;

      ((Sender as TfrmRecordEdit).Parent as TTabSheet).Caption := vText;
    end;
  end;
end;

procedure TfrmPatientRecord.DoRecordReadOnlySwitch(Sender: TObject);
begin
  if (Sender is TfrmRecordEdit) then
  begin
    if (Sender as TfrmRecordEdit).Parent is TTabSheet then
    begin
      if (Sender as TfrmRecordEdit).EmrView.ActiveSection.PageData.ReadOnly then
        ((Sender as TfrmRecordEdit).Parent as TTabSheet).ImageIndex := 1
      else
        ((Sender as TfrmRecordEdit).Parent as TTabSheet).ImageIndex := 0;
    end;
  end;
end;

procedure TfrmPatientRecord.DoSaveRecordContent(Sender: TObject);
var
  vSM: TMemoryStream;
  vRecordInfo: TRecordInfo;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  vSM := TMemoryStream.Create;
  try
    vfrmRecordEdit := Sender as TfrmRecordEdit;
    vRecordInfo := TRecordInfo(vfrmRecordEdit.ObjectData);

    CheckRecordContent(vfrmRecordEdit);  // ����ĵ��ʿء��ۼ�������
    vfrmRecordEdit.EmrView.SaveToStream(vSM);

    if vRecordInfo.ID > 0 then  // �༭�󱣴�
    begin
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_SAVERECORDCONTENT;  // ����ָ����סԺ����
          ABLLServerReady.ExecParam.I['rid'] := vRecordInfo.ID;
          ABLLServerReady.ExecParam.ForcePathObject('content').LoadBinaryFromStream(vSM);
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if ABLLServer.MethodRunOk then  // ����˷�������ִ�гɹ�
            ShowMessage('����ɹ���')
          else
            ShowMessage(ABLLServer.MethodError);
        end);
    end
    else  // �����½��Ĳ���
    begin
      BLLServerExec(
        procedure(const ABLLServerReady: TBLLServerProxy)
        begin
          ABLLServerReady.Cmd := BLL_NEWINCHRECORD;  // �����½�����
          ABLLServerReady.ExecParam.I['PatID'] := FPatientInfo.PatID;
          ABLLServerReady.ExecParam.I['VisitID'] := FPatientInfo.VisitID;
          ABLLServerReady.ExecParam.I['desid'] := vRecordInfo.DesID;
          ABLLServerReady.ExecParam.S['Name'] := vRecordInfo.NameEx;
          ABLLServerReady.ExecParam.S['CreateUserID'] := UserInfo.ID;
          ABLLServerReady.ExecParam.ForcePathObject('Content').LoadBinaryFromStream(vSM);
          //
          ABLLServerReady.AddBackField('RecordID');
        end,
        procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
        begin
          if ABLLServer.MethodRunOk then  // ����˷�������ִ�гɹ�
          begin
            vRecordInfo.ID := ABLLServer.BackField('RecordID').AsInteger;
            ShowMessage('���没�� ' + vRecordInfo.NameEx + ' �ɹ���');
            GetPatientRecordListUI;
            tvRecord.Selected := FindRecordNode(vRecordInfo.ID);
          end
          else
            ShowMessage(ABLLServer.MethodError);
        end);
    end;
  finally
    FreeAndNil(vSM);
  end;
end;

procedure TfrmPatientRecord.DoTraverseItem(const AData: THCCustomData;
  const AItemNo, ATag: Integer; var AStop: Boolean);
var
  vItem: TEmrTextItem;

  {$REGION 'SetElementText �滻Ԫ������'}
  procedure SetElementText;
  var
    vDeIndex: string;
  begin
    vDeIndex := vItem[TDeProp.Index];
    if vDeIndex <> '' then
    begin
      if vDeIndex = '748' then  // ����
        vItem.Text := FPatientInfo.NameEx
      else
      if vDeIndex = '749' then  // �Ա�
        vItem.Text := FPatientInfo.Sex
      else
      if vDeIndex = '129' then  // ����
        vItem.Text := FPatientInfo.Age
      else
      if vDeIndex = '450' then  // ����׶�
        vItem.Text := '����'
      else
      if vDeIndex = '1452' then  // ����
        vItem.Text := '�ļ�3��'
      else
      if vDeIndex = '1706' then  // ����
        vItem.Text := FPatientInfo.DeptName
      else
//      if vDeIndex = '1148' then  // ��Ժ����
//        vItem.Text := FormatDateTime('YYYY-MM-DD', Now)
//      else
//      if vDeIndex = '1280' then  // ʵ��סԺ����
//        vItem.Text := '8'
//      else
      if vDeIndex = '186' then  // ����
        vItem.Text := FPatientInfo.BedNo
      else
      if vDeIndex = '201' then  // סԺ��
        vItem.Text := FPatientInfo.InpNo
      else
//      if vDeIndex = '1666' then  // ����׶�
//        vItem.Text := '����'
//      else
//      if vDeIndex = '1952' then  // ����ҽ��
//        vItem.Text := '��ҽʦ'
//      else
//      if vDeIndex = '1953' then  // �������ҽ��
//        vItem.Text := '��ҽʦ'
//      else
//      if vDeIndex = '1951' then  // ��鱨��ʱ��
//        vItem.Text := '2017-11-21 13:56'
//      else
      if vDeIndex = '446' then  // ������� ��ǰʱ��
        vItem.Text := FormatDateTime('YYYY-MM-DD HH:mm', Now)
//      else
//      if vDeIndex = '1606' then  // ����ID
//        vItem.Text := 'ZY201711023'
//      else
//      if vDeIndex = '1629' then  // ��Ժ����
//        vItem.Text := FormatDateTime('YYYY-MM-DD', DateUtils.IncDay(Now, -8))
      else
      if vDeIndex = '453' then  // ��ǰ��¼ҽ��
        vItem.Text := UserInfo.NameEx;
    end;
  end;
  {$ENDREGION}

begin
  if not (AData.Items[AItemNo] is TEmrTextItem) then Exit;  // ֻ��Ԫ����Ч�����������ʱ������

  vItem := AData.Items[AItemNo] as TEmrTextItem;

  case ATag of
    TTraverse.ReplaceElement:  // Ԫ�����ݸ�ֵ
      if AData.Items[AItemNo].StyleNo > THCStyle.RsNull then
        SetElementText;

    TTraverse.CheckContent:  // У��Ԫ������
      begin
        case vItem.StyleEx of
          cseNone: vItem[TDeProp.Trace] := '';

          cseDel:
            begin
              if vItem[TDeProp.Trace] = '' then  // �ºۼ�
                vItem[TDeProp.Trace] := UserInfo.NameEx + '(' + UserInfo.ID + ') ɾ�� ' + FormatDateTime('YYYY-MM-DD HH:mm:SS', FTraverseDT);
            end;

          cseAdd:
            begin
              if vItem[TDeProp.Trace] = '' then  // �ºۼ�
                vItem[TDeProp.Trace] := UserInfo.NameEx + '(' + UserInfo.ID + ') ��� ' + FormatDateTime('YYYY-MM-DD HH:mm:SS', FTraverseDT);
            end;
        end;
      end;

    TTraverse.ShowTrace: // �ۼ���ʾ����
      begin
        if AData.Items[AItemNo] is TEmrTextItem then
        begin
          if vItem.StyleEx = TStyleExtra.cseDel then
            vItem.Visible := not vItem.Visible;
        end;
      end;
  end;
end;

procedure TfrmPatientRecord.EditPatientDeSet(const ADeSetID, ARecordID: Integer);
//var
//  vEmrRichView: TEmrRichView;
//  i: Integer;
begin
  //OpenPatientDeSet(ADeSetID, ARecordID);
//  OpenPatientRecord(tvRecord.Selected);  // ��
//
//  if (not TreeNodeIsRecordDeSet(tvRecord.Selected))  // �ǲ���
//    and (pgRecordEdit.ActivePageIndex >= 0)  // �л���Ҫ�༭�Ĳ���
//  then
//  begin
//    vEmrRichView := GetPageRecordEdit(pgRecordEdit.ActivePageIndex).EmrView;
//    for i := 0 to vEmrRichView.Sections.Count - 1 do
//    begin
//      vEmrRichView.Sections[i].Header.ReadOnly := True;
//      vEmrRichView.Sections[i].Footer.ReadOnly := True;
//      vEmrRichView.Sections[i].Data.ReadOnly := False;
//    end;
//  end;
end;

function TfrmPatientRecord.FindRecordNode(const ARecordID: Integer): TTreeNode;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to tvRecord.Items.Count - 1 do
  begin
    if TreeNodeIsRecord(tvRecord.Items[i]) then
    begin
      if ARecordID = TRecordInfo(tvRecord.Items[i].Data).ID then
      begin
        Result := tvRecord.Items[i];
        Break;
      end;
    end;
  end;
end;

procedure TfrmPatientRecord.FormClose(Sender: TObject;
  var Action: TCloseAction);
begin
  if Assigned(FOnCloseForm) then
    FOnCloseForm(Self);
end;

procedure TfrmPatientRecord.FormCreate(Sender: TObject);
begin
  //SetWindowLong(Handle, GWL_EXSTYLE, (GetWindowLong(handle, GWL_EXSTYLE) or WS_EX_APPWINDOW));
  FPatientInfo := TPatientInfo.Create;
end;

procedure TfrmPatientRecord.FormDestroy(Sender: TObject);
var
  i, j: Integer;
begin
  for i := 0 to pgRecordEdit.PageCount - 1 do
  begin
    for j := 0 to pgRecordEdit.Pages[i].ControlCount - 1 do
    begin
      if pgRecordEdit.Pages[i].Controls[j] is TfrmRecordEdit then
      begin
        pgRecordEdit.Pages[i].Controls[j].Free;
        Break;
      end;
    end;
  end;

  FreeAndNil(FPatientInfo);
end;

procedure TfrmPatientRecord.FormShow(Sender: TObject);
begin
  Caption := FPatientInfo.BedNo + '����' + FPatientInfo.NameEx;
  pnl1.Caption := FPatientInfo.BedNo + '����' + FPatientInfo.NameEx + '��'
    + FPatientInfo.Sex + '��' + FPatientInfo.Age + '��' + FPatientInfo.PatID.ToString + '��'
    + FPatientInfo.InpNo + '��' + FPatientInfo.VisitID.ToString + '��'
    + FormatDateTime('YYYY-MM-DD HH:mm', FPatientInfo.InDeptDateTime) + '��ƣ�'
    + FPatientInfo.CareLevel.ToString + '������';

  GetPatientRecordListUI;
end;

procedure TfrmPatientRecord.GetNodeRecordInfo(const ANode: TTreeNode;
  var ADeSetPID, ARecordID: Integer);
var
  vNode: TTreeNode;
begin
  ADeSetPID := -1;
  ARecordID := -1;

  if TreeNodeIsRecord(ANode) then  // �����ڵ�
  begin
    ARecordID := TRecordInfo(ANode.Data).ID;

    ADeSetPID := -1;
    vNode := ANode;
    while vNode.Parent <> nil do
    begin
      vNode := vNode.Parent;
      if TreeNodeIsRecordDeSet(vNode) then
      begin
        ADeSetPID := TRecordDeSetInfo(vNode.Data).DesPID;  // �����������ݼ�����
        Break;
      end;
    end;
  end;
end;

function TfrmPatientRecord.GetPageRecordEdit(const APageIndex: Integer): TfrmRecordEdit;
var
  i: Integer;
begin
  Result := nil;
  for i := 0 to pgRecordEdit.Pages[APageIndex].ControlCount - 1 do
  begin
    if pgRecordEdit.Pages[APageIndex].Controls[i] is TfrmRecordEdit then
    begin
      Result := (pgRecordEdit.Pages[APageIndex].Controls[i] as TfrmRecordEdit);
      Break;
    end;
  end;
end;

procedure TfrmPatientRecord.GetPatientRecordListUI;
var
  vPatNode: TTreeNode;
begin
  RefreshRecordNode;  // ������нڵ㣬Ȼ����ӱ���סԺ��Ϣ�ڵ�

  vPatNode := GetPatientNode;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETINCHRECORDLIST;  // ��ȡָ����סԺ���߲����б�
      ABLLServerReady.ExecParam.I['PatID'] := FPatientInfo.PatID;
      ABLLServerReady.ExecParam.I['VisitID'] := FPatientInfo.VisitID;
      ABLLServerReady.BackDataSet := True;  // ���߷����Ҫ����ѯ���ݼ��������
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    var
      vRecordInfo: TRecordInfo;
      vRecordDeSetInfo: TRecordDeSetInfo;
      vDesPID: Integer;
      vNode: TTreeNode;
    begin
      if not ABLLServer.MethodRunOk then  // ����˷�������ִ�в��ɹ�
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      vDesPID := 0;
      vNode := nil;
      if AMemTable <> nil then
      begin
        if AMemTable.RecordCount > 0 then
        begin
          tvRecord.Items.BeginUpdate;
          try
            with AMemTable do
            begin
              First;
              while not Eof do
              begin
                if vDesPID <> FieldByName('desPID').AsInteger then
                begin
                  vDesPID := FieldByName('desPID').AsInteger;
                  vRecordDeSetInfo := TRecordDeSetInfo.Create;
                  vRecordDeSetInfo.DesPID := vDesPID;

                  vNode := tvRecord.Items.AddChildObject(vPatNode, GetDeSet(vDesPID).GroupName, vRecordDeSetInfo);
                  vNode.HasChildren := True;
                end;

                vRecordInfo := TRecordInfo.Create;
                vRecordInfo.ID := FieldByName('ID').AsInteger;
                vRecordInfo.DesID := FieldByName('desID').AsInteger;
                vRecordInfo.NameEx := FieldByName('Name').AsString;

                tvRecord.Items.AddChildObject(vNode, vRecordInfo.NameEx, vRecordInfo);

                Next;
              end;
            end;
          finally
            tvRecord.Items.EndUpdate;
          end;
        end;
      end;
    end);
end;

function TfrmPatientRecord.GetRecordEditPageIndex(
  const ARecordID: Integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to pgRecordEdit.PageCount - 1 do
  begin
    if pgRecordEdit.Pages[i].Tag = ARecordID then
    begin
      Result := i;
      Break;
    end;
  end;
end;

procedure TfrmPatientRecord.LoadPatientDeSetContent(const ADeSetID: Integer);
var
  vfrmRecordEdit: TfrmRecordEdit;
  vSM: TMemoryStream;
  vPage: TTabSheet;
  vIndex: Integer;
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETDESETRECORDCONTENT;  // ��ȡģ������ӷ����ģ��
      ABLLServerReady.ExecParam.I['PatID'] := FPatientInfo.PatID;
      ABLLServerReady.ExecParam.I['VisitID'] := FPatientInfo.VisitID;
      ABLLServerReady.ExecParam.I['pid'] := ADeSetID;
      ABLLServerReady.BackDataSet := True;  // ���߷����Ҫ����ѯ���ݼ��������
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    //var
    //  vDeGroup: TDeGroup;
    begin
      if not ABLLServer.MethodRunOk then  // ����˷�������ִ�в��ɹ�
      begin
        ShowMessage(ABLLServer.MethodError);
        Exit;
      end;

      if AMemTable <> nil then
      begin
        if AMemTable.RecordCount > 0 then
        begin
          vIndex := 0;

          vfrmRecordEdit := TfrmRecordEdit.Create(nil);  // �����༭��
          //vfrmRecordEdit.HideToolbar;  // ���̺ϲ���ʾ��֧�ֱ༭
          //vfrmRecordEdit.ObjectData := tvRecord.Selected.Data;
          //vfrmRecordEdit.OnChangedSwitch := DoRecordChangedSwitch;
          vfrmRecordEdit.OnReadOnlySwitch := DoRecordReadOnlySwitch;

          vPage := TTabSheet.Create(pgRecordEdit);
          vPage.Caption := '���̼�¼';
          vPage.Tag := -ADeSetID;
          vPage.PageControl := pgRecordEdit;
          vfrmRecordEdit.Align := alClient;
          vfrmRecordEdit.Parent := vPage;

          vFrmRecordEdit.EmrView.BeginUpdate;
          try
            vSM := TMemoryStream.Create;
            try
              with AMemTable do
              begin
                First;
                while not Eof do
                begin
                  vSM.Clear;
                  //GetRecordContent(FieldByName('id').AsInteger, vSM);  // ��������
                  (AMemTable.FieldByName('content') as TBlobField).SaveToStream(vSM);
                  if vSM.Size > 0 then
                  begin
                    if vIndex > 0 then  // �ӵڶ�����������ǰһ�����滻���ٲ���
                    begin
                      vfrmRecordEdit.EmrView.ActiveSection.ActiveData.SelectLastItemAfter;
                      vfrmRecordEdit.EmrView.InsertBreak;
                      vfrmRecordEdit.EmrView.ApplyParaAlignHorz(TParaAlignHorz.pahLeft);
                    end;

                    {// ���벡��������
                    vDeGroup := TDeGroup.Create;
                    vDeGroup.Propertys.Add(DeIndex + '=' + FieldByName('id').AsString);
                    vDeGroup.Propertys.Add(DeName + '=' + FieldByName('name').AsString);
                    //vDeGroup.Propertys.Add(DeCode + '=' + sgdDE.Cells[2, sgdDE.Row]);
                    vFrmRecordEdit.EmrView.InsertDeGroup(vDeGroup);

                    // ѡ���������м�
                    vfrmRecordEdit.EmrView.ActiveSection.ActiveData.SelectItemAfter(
                      vfrmRecordEdit.EmrView.ActiveSection.ActiveData.Items.Count - 2); }

                    vfrmRecordEdit.EmrView.InsertStream(vSM);  // ��������
                    //Break;
                  end;

                  Inc(vIndex);
                  Next;
                end;
              end;
            finally
              vSM.Free;
            end;
          finally
            vFrmRecordEdit.EmrView.EndUpdate;
          end;

          vfrmRecordEdit.Show;

          pgRecordEdit.ActivePage := vPage;
        end
        else
          ShowMessage('û�в��̲�����');
      end;
    end);
end;

procedure TfrmPatientRecord.LoadPatientRecordContent(const ARecordID: Integer);
var
  vSM: TMemoryStream;
  vfrmRecordEdit: TfrmRecordEdit;
  vPage: TTabSheet;
begin
  vSM := TMemoryStream.Create;
  try
    GetRecordContent(ARecordID, vSM);

    vfrmRecordEdit := TfrmRecordEdit.Create(nil);  // �����༭��
    vfrmRecordEdit.ObjectData := tvRecord.Selected.Data;
    vfrmRecordEdit.OnSave := DoSaveRecordContent;
    vfrmRecordEdit.OnChangedSwitch := DoRecordChangedSwitch;
    vfrmRecordEdit.OnReadOnlySwitch := DoRecordReadOnlySwitch;

    vPage := TTabSheet.Create(pgRecordEdit);
    vPage.Caption := tvRecord.Selected.Text;
    vPage.Tag := ARecordID;
    vPage.PageControl := pgRecordEdit;

    vfrmRecordEdit.Align := alClient;
    vfrmRecordEdit.Parent := vPage;  // ��ֵ�����ڣ��Ա���غ�״̬(ֻ����)�ڸ�������ʾ

    if vSM.Size > 0 then
      vfrmRecordEdit.EmrView.LoadFromStream(vSM);

    vfrmRecordEdit.EmrView.ReadOnly := True;

    vfrmRecordEdit.Show;

    pgRecordEdit.ActivePage := vPage;
  finally
    vSM.Free;
  end;
end;

procedure TfrmPatientRecord.mniCloseRecordEditClick(Sender: TObject);
begin
  CloseRecordEditPage(pgRecordEdit.ActivePageIndex);
end;

procedure TfrmPatientRecord.mniDeleteClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // ���ǲ����ڵ�

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then  // ��Ч�Ĳ���
  begin
    if MessageDlg('ɾ������ ' + tvRecord.Selected.Text + ' ��',
      mtWarning, [mbYes, mbNo], 0) = mrYes
    then
    begin
      vPageIndex := GetRecordEditPageIndex(vRecordID);
      if vPageIndex >= 0 then  // ����
        CloseRecordEditPage(pgRecordEdit.ActivePageIndex, False);

      DeletePatientRecord(vRecordID);

      tvRecord.Items.Delete(tvRecord.Selected);
    end;
  end;
end;

procedure TfrmPatientRecord.mniEditClick(Sender: TObject);
var
  i, vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // ���ǲ����ڵ�

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(vRecordID);
    if vPageIndex < 0 then  // û��
    begin
      LoadPatientRecordContent(vRecordID);  // ��������
      //vPageIndex := GetRecordEditPageIndex(vRecordID);
    end
    else  // �Ѿ������л���
      pgRecordEdit.ActivePageIndex := vPageIndex;

    // �л���д����
    vfrmRecordEdit := GetPageRecordEdit(pgRecordEdit.ActivePageIndex);

    for i := 0 to vfrmRecordEdit.EmrView.Sections.Count - 1 do
    begin
      vfrmRecordEdit.EmrView.Sections[i].Header.ReadOnly := True;
      vfrmRecordEdit.EmrView.Sections[i].Footer.ReadOnly := True;
      vfrmRecordEdit.EmrView.Sections[i].PageData.ReadOnly := False;
      //vfrmRecordEdit.OnItemMouseClick := DoRecordItemMouseClick;
    end;

    try
      vfrmRecordEdit.EmrView.Trace := GetInchRecordSignature(vRecordID);
      if vfrmRecordEdit.EmrView.Trace then
      begin
        vfrmRecordEdit.EmrView.ShowAnnotation := True;
        ShowMessage('�����Ѿ�ǩ�����������޸Ľ������޸ĺۼ���');
      end;
    except
      vfrmRecordEdit.EmrView.ReadOnly := True;  // ��ȡʧ�����л�Ϊֻ��
    end;
  end;
end;

procedure TfrmPatientRecord.OpenPatientDeSet(const ADeSetID, ARecordID: Integer);
var
  vPageIndex: Integer;
begin
  if ARecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(-ADeSetID);
    if vPageIndex < 0 then
    begin
      LoadPatientDeSetContent(ADeSetID);
      //vPageIndex := GetRecordEditPageIndex(-ADeSetID);
    end
    else
      pgRecordEdit.ActivePageIndex := vPageIndex;
  end;
end;

function TfrmPatientRecord.GetPatientNode: TTreeNode;
begin
  Result := tvRecord.Items[0];
end;

procedure TfrmPatientRecord.mniN2Click(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // ���ǲ����ڵ�

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(vRecordID);
    if vPageIndex >= 0 then  // ���ˣ��л���ֻ��
      vfrmRecordEdit := GetPageRecordEdit(vPageIndex);

    if SignatureInchRecord(vRecordID, UserInfo.ID) then
      ShowMessage(UserInfo.NameEx + '��ǩ���ɹ���');

    if vfrmRecordEdit <> nil then  // �Ѿ��򿪣����л������ۼ�
      vfrmRecordEdit.EmrView.Trace := True;
  end;
end;

procedure TfrmPatientRecord.mniNewClick(Sender: TObject);
var
  vPage: TTabSheet;
  vfrmRecordEdit: TfrmRecordEdit;
  //vOpenDlg: TOpenDialog;
  vFrmTempList: TfrmTemplateList;
  vTemplateID, vDesID: Integer;
  vRecordName: string;
  vSM: TMemoryStream;
  vRecordInfo: TRecordInfo;
begin
  // ѡ��ģ��
  vTemplateID := -1;
  vFrmTempList := TfrmTemplateList.Create(nil);
  try
    vFrmTempList.Parent := Self;
    vFrmTempList.ShowModal;
    if vFrmTempList.ModalResult = mrOk then
    begin
      vTemplateID := vFrmTempList.TemplateID;
      vDesID := vFrmTempList.DesID;
      vRecordName := vFrmTempList.RecordName;
    end
    else
      Exit;
  finally
    FreeAndNil(vFrmTempList);
  end;

  //if vTemplateID < 0 then Exit;  // û��ѡ��ģ��

  vSM := TMemoryStream.Create;
  try
    GetTemplateContent(vTemplateID, vSM);  // ȡģ������

    // ������Ϣ����
    vRecordInfo := TRecordInfo.Create;
    vRecordInfo.DesID := vDesID;
    vRecordInfo.NameEx := vRecordName;
    // ����pageҳ
    vPage := TTabSheet.Create(pgRecordEdit);
    vPage.PageControl := pgRecordEdit;
    vPage.Caption := vRecordName;
    // ������������
    vfrmRecordEdit := TfrmRecordEdit.Create(nil);
    vfrmRecordEdit.ObjectData := vRecordInfo;
    vfrmRecordEdit.OnSave := DoSaveRecordContent;
    vfrmRecordEdit.OnChangedSwitch := DoRecordChangedSwitch;
    vfrmRecordEdit.OnReadOnlySwitch := DoRecordReadOnlySwitch;
    vfrmRecordEdit.Align := alClient;
    vfrmRecordEdit.Parent := vPage;
    if vSM.Size > 0 then  // �����ݣ���������
    begin
      vfrmRecordEdit.EmrView.LoadFromStream(vSM);  // ����ģ��
      ReplaceTemplateElement(vfrmRecordEdit);  // �滻Ԫ������
    end;
    // ��ʾ������
    vfrmRecordEdit.Show;
    pgRecordEdit.ActivePage := vPage;
  finally
    vSM.Free;
  end;
end;

procedure TfrmPatientRecord.mniPreviewClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // ���ǲ����ڵ�

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vDeSetID = TDeSetInfo.Proc then  // ���̼�¼
  begin
    vPageIndex := GetRecordEditPageIndex(-vDeSetID);
    if vPageIndex < 0 then
    begin
      LoadPatientDeSetContent(vDeSetID);
      vPageIndex := GetRecordEditPageIndex(-vDeSetID);
      // ֻ��
      //GetPageRecordEdit(vPageIndex).EmrView.ReadOnly := True;
    end
    else
      pgRecordEdit.ActivePageIndex := vPageIndex;
  end
end;

procedure TfrmPatientRecord.mniViewClick(Sender: TObject);
var
  vDeSetID, vRecordID, vPageIndex: Integer;
  vfrmRecordEdit: TfrmRecordEdit;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then Exit;  // ���ǲ����ڵ�

  GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

  if vRecordID > 0 then
  begin
    vPageIndex := GetRecordEditPageIndex(vRecordID);
    if vPageIndex < 0 then  // û��
    begin
      LoadPatientRecordContent(vRecordID);  // ��������

      // ֻ��
      vPageIndex := GetRecordEditPageIndex(vRecordID);
    end
    else  // �Ѿ������л���
      pgRecordEdit.ActivePageIndex := vPageIndex;

    try
      vfrmRecordEdit := GetPageRecordEdit(vPageIndex);
    finally
      vfrmRecordEdit.EmrView.ReadOnly := True;
    end;

    vfrmRecordEdit.EmrView.Trace := GetInchRecordSignature(vRecordID);
    if vfrmRecordEdit.EmrView.Trace then  // �Ѿ�ǩ������ģʽ
      vfrmRecordEdit.EmrView.ShowAnnotation := True;
  end;
end;

procedure TfrmPatientRecord.pgRecordEditMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vTabIndex: Integer;
  vPt: TPoint;
begin
  if (Y < 20) and (Button = TMouseButton.mbRight) then  // Ĭ�ϵ� pgRecordEdit.TabHeight ��ͨ����ȡ����ϵͳ�����õ�����ȷ��
  begin
    vTabIndex := pgRecordEdit.IndexOfTabAt(X, Y);

    //if pgRecordEdit.Pages[vTabIndex].Name = tsHelp then Exit; // ����

    if (vTabIndex >= 0) and (vTabIndex = pgRecordEdit.ActivePageIndex) then
    begin
      vPt := pgRecordEdit.ClientToScreen(Point(X, Y));
      pmpg.Popup(vPt.X, vPt.Y);
    end;
  end;
end;

procedure TfrmPatientRecord.pmRecordPopup(Sender: TObject);
var
  vDeSetID, vRecordID: Integer;
begin
  if not TreeNodeIsRecord(tvRecord.Selected) then  // ���ǲ����ڵ�
  begin
    mniView.Visible := False;
    mniEdit.Visible := False;
    mniDelete.Visible := False;
    mniPreview.Visible := False;  // ���̼�¼
  end
  else
  begin
    GetNodeRecordInfo(tvRecord.Selected, vDeSetID, vRecordID);

    mniView.Visible := vRecordID > 0;
    mniEdit.Visible := vRecordID > 0;
    mniDelete.Visible := vRecordID > 0;
    mniPreview.Visible := vDeSetID = 13;  // ���̼�¼
  end;
end;

procedure TfrmPatientRecord.RefreshRecordNode;
var
  vNode: TTreeNode;
begin
  ClearRecordNode;

  // ����סԺ�ڵ�
  vNode := tvRecord.Items.AddObject(nil, FPatientInfo.BedNo + ' ' + FPatientInfo.NameEx
    + ' ' + FormatDateTime('YYYY-MM-DD HH:mm', FPatientInfo.InHospDateTime), nil);
  vNode.HasChildren := True;

  // �̼߳�������סԺ��Ϣ
end;

procedure TfrmPatientRecord.ReplaceTemplateElement(const ARecordEdit: TfrmRecordEdit);
var
  vItemTraverse: TItemTraverse;
begin
  vItemTraverse := TItemTraverse.Create;
  try
    vItemTraverse.Tag := TTraverse.ReplaceElement;
    vItemTraverse.Process := DoTraverseItem;
    ARecordEdit.EmrView.TraverseItem(vItemTraverse);
  finally
    vItemTraverse.Free;
  end;
  ARecordEdit.EmrView.FormatData;
  ARecordEdit.EmrView.IsChanged := True;
end;

procedure TfrmPatientRecord.tvRecordDblClick(Sender: TObject);
begin
  mniViewClick(Sender);
end;

procedure TfrmPatientRecord.tvRecordExpanding(Sender: TObject; Node: TTreeNode;
  var AllowExpansion: Boolean);
var
  vPatNode: TTreeNode;
begin
  if Node.Parent = nil then  // ����סԺ��Ϣ�����
  begin
    if Node.Count = 0 then  // �����޲����ڵ�ʱ�Ż�ȡ�����ε��½�������ɴ���ѡ�нڵ�Ĵ���
    begin
      GetPatientRecordListUI;  // ��ȡ���߲����б�

      // �޲���ʱ���߽ڵ�չ����ȥ��+��
      vPatNode := GetPatientNode;
      if vPatNode.Count = 0 then
        vPatNode.HasChildren := False;
    end;
  end;
end;

end.
