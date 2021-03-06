{*******************************************************}
{                                                       }
{         基于HCView的电子病历程序  作者：荆通          }
{                                                       }
{ 此代码仅做学习交流使用，不可用于商业目的，由此引发的  }
{ 后果请使用者承担，加入QQ群 649023932 来获取更多的技术 }
{ 交流。                                                }
{                                                       }
{*******************************************************}

unit emr_Common;

interface

uses
  Classes, SysUtils, Vcl.ComCtrls, FireDAC.Comp.Client, System.Generics.Collections,
  emr_BLLServerProxy, FunctionIntf, frm_Hint;

const
  // 常量注意大小写有修改后，要处理sqlite库中对应的字段大小写一致
  // 本地参数
  PARAM_LOCAL_MSGHOST = 'MsgHost';    // 消息服务器IP
  PARAM_LOCAL_MSGPORT = 'MsgPort';    // 消息服务器端口
  PARAM_LOCAL_BLLHOST = 'BLLHost';    // 业务服务器IP
  PARAM_LOCAL_BLLPORT = 'BLLPort';    // 业务服务器端口
  PARAM_LOCAL_UPDATEHOST = 'UpdateHost';  // 更新服务器IP
  PARAM_LOCAL_UPDATEPORT = 'UpdatePort';  // 更新服务器端口
  PARAM_LOCAL_DEPTCODE = 'DeptCode';  // 科室
  PARAM_LOCAL_VERSIONID = 'VersionID';  // 版本号
  PARAM_LOCAL_PLAYSOUND = 'PlaySound';  // 插入呼叫声音
  // 服务端参数
  PARAM_GLOBAL_HOSPITAL = 'Hospital';  // 医院

type
  TClientParam = class(TObject)  // 客户端参数(仅Win平台使用)
  private
    FMsgServerIP, FBLLServerIP, FUpdateServerIP: string;
    FMsgServerPort, FBLLServerPort, FUpdateServerPort: Word;
    FTimeOut: Integer;
  public
    /// <summary> 消息服务器IP </summary>
    property MsgServerIP: string read FMsgServerIP write FMsgServerIP;

    /// <summary> 业务服务器IP </summary>
    property BLLServerIP: string read FBLLServerIP write FBLLServerIP;

    /// <summary> 更新服务器IP </summary>
    property UpdateServerIP: string read FUpdateServerIP write FUpdateServerIP;

    /// <summary> 消息服务器端口 </summary>
    property MsgServerPort: Word read FMsgServerPort write FMsgServerPort;

    /// <summary> 业务服务器端口 </summary>
    property BLLServerPort: Word read FBLLServerPort write FBLLServerPort;

    /// <summary> 更新服务器端口 </summary>
    property UpdateServerPort: Word read FUpdateServerPort write FUpdateServerPort;

    /// <summary> 响应超时时间 </summary>
    property TimeOut: Integer read FTimeOut write FTimeOut;
  end;

  TBLLServerReadyEvent = reference to procedure(const ABLLServerReady: TBLLServerProxy);
  TBLLServerRunEvent = reference to procedure(const ABLLServerRun: TBLLServerProxy; const AMemTable: TFDMemTable = nil);

  TOnErrorEvent = procedure(const AErrCode: Integer; const AParam: string) of object;

  TBLLServer = class(TObject)  // 业务服务端
  protected
    FOnError: TOnErrorEvent;
    procedure DoServerError(const AErrCode: Integer; const AParam: string);
  public
    /// <summary>
    /// 创建一个服务端代理
    /// </summary>
    /// <returns></returns>
    class function GetBLLServerProxy: TBLLServerProxy;

    /// <summary>
    /// 获取服务端时间
    /// </summary>
    /// <returns></returns>
    class function GetServerDateTime: TDateTime;

    /// <summary>
    /// 获取全局系统参数
    /// </summary>
    /// <param name="AParamName"></param>
    /// <returns></returns>
    function GetParam(const AParamName: string): string;

    /// <summary>
    /// 获取业务服务端是否在指定时间内可响应
    /// </summary>
    /// <param name="AMesc"></param>
    /// <returns></returns>
    function GetBLLServerResponse(const AMesc: Word): Boolean;
    property OnError: TOnErrorEvent read FOnError write FOnError;
  end;

  TUpdateFile = class(TObject)  // 存储升级文件信息
  private
    FFileName, FRelativePath, FVersion, FHash: string;
    FVerID: Integer;
    FSize: Int64;
    FEnforce: Boolean;
  public
    constructor Create; overload;
    constructor Create(const AFileName, ARelativePath, AVersion, AHash: string;
      const ASize: Int64; const AVerID: Integer; const AEnforce: Boolean); overload;
    destructor Destroy;

    /// <summary> 文件名 </summary>
    property FileName: string read FFileName write FFileName;

    /// <summary> 相对路径 </summary>
    property RelativePath: string read FRelativePath write FRelativePath;

    /// <summary> 文件版本号 </summary>
    property Version: string read FVersion write FVersion;

    /// <summary> 文件Hash值 </summary>
    property Hash: string read FHash write FHash;

    /// <summary> 文件大小 </summary>
    property Size: Int64 read FSize write FSize;

    /// <summary> 文件版本号(比较文件版本号使用) </summary>
    property VerID: Integer read FVerID write FVerID;

    /// <summary> 文件是否强制升级 </summary>
    property Enforce: Boolean read FEnforce write FEnforce;
  end;

  TCustomUserInfo = class(TObject)
  strict private
    FID: string;  // 用户ID
    FNameEx: string;  // 用户名
    FDeptID: string;  // 用户所属科室ID
    FDeptName: string;  // 用户所属科室名称
  protected
    procedure Clear; virtual;
    procedure SetUserID(const Value: string); virtual;
  public
    property ID: string read FID write SetUserID;
    property NameEx: string read FNameEx write FNameEx;
    property DeptID: string read FDeptID write FDeptID;
    property DeptName: string read FDeptName write FDeptName;
  end;

  TUserInfo = class(TCustomUserInfo)  // 记录用户信息
  private
    FGroupDeptIDs: string;  // 用户所有工作组对应科室
    FFunCDS: TFDMemTable;
    procedure IniUserInfo;  //设置用户基本信息
    procedure IniFuns;  // 设置指定用户所有角色对应的功能
    procedure IniGroupDepts;  // 设置指定用户所有工作组对应的科室
  protected
    procedure SetUserID(const Value: string); override;  // 用户所有角色对应的功能
    procedure Clear; override;
    /// <summary>
    /// 判断当前用户是否有某功能权限，如果有则判断ADeptID是否在当前用户使用该功能要求的科室范围
    /// 或APerID是否是当前用户
    /// </summary>
    /// <param name="AFunID">功能ID</param>
    /// <param name="ADeptID">科室ID</param>
    /// <param name="APerID">用户ID</param>
    /// <returns>True: 有此权限</returns>
    function FunAuth(const AFunID, ADeptID: Integer; const APerID: string): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    {由于不同医院维护的功能不同，因此数据库中同一功能ID对应的可能是不同的功能，
       所以代码不能用功能ID作为参数判断是否有权限，而使用可配置的控件名称来处理。}
    /// <summary>
    /// 根据操作科室ID、操作人判断指定窗体非控件类功能是否有权限(适用于进行具体操作的事件时判断用户有无权限)
    /// </summary>
    /// <param name="AFormAuthControls">窗体所有受权限管理的控件及对应的功能ID</param>
    /// <param name="AControlName">控件名称</param>
    /// <param name="ADeptID">科室</param>
    /// <param name="APerID">操作人</param>
    /// <returns>True: 有权限操作</returns>
    function FormUnControlAuth(const AFormAuthControls: TFDMemTable; const AControlName: string;
      const ADeptID: Integer; const APerID: string): Boolean;

    /// <summary>
    /// 根据指定的科室ID、操作人信息设置指定窗体受权限控制控件的状态(适用于患者切换后及时根据用户对新选中患者的权限设置窗体控件状态)
    /// </summary>
    /// <param name="AForm">窗体</param>
    /// <param name="ADeptID">科室ID</param>
    /// <param name="APersonID">操作人</param>
    procedure SetFormAuthControlState(const AForm: TComponent; const ADeptID: Integer; const APersonID: string);

    /// <summary> 获取指定窗体上受权限控制的控件信息并添加当前用户权限信息(适用于用户登录后或打开窗体后) </summary>
    /// <param name="AForm">窗体</param>
    /// <param name="AAuthControls">窗体所有受权限控制的控件及控件对应的功能ID</param>
    procedure IniFormControlAuthInfo(const AForm: TComponent; const AAuthControls: TFDMemTable);

    property FunCDS: TFDMemTable read FFunCDS;
    property GroupDeptIDs: string read FGroupDeptIDs;
  end;

  TPatientInfo = class(TObject)
  private
    FInpNo, FBedNo, FNameEx, FSex, FAge, FDeptName: string;
    FPatID: Cardinal;
    FInHospDateTime, FInDeptDateTime: TDateTime;
    FCareLevel,  // 护理级别
    FVisitID  // 住院次数
      : Byte;
  protected
    procedure SetInpNo(const AInpNo: string);
  public
    procedure Assign(const ASource: TPatientInfo);
    property PatID: Cardinal read FPatID write FPatID;
    property NameEx: string read FNameEx write FNameEx;
    property Sex: string read FSex write FSex;
    property Age: string read FAge write FAge;
    property BedNo: string read FBedNo write FBedNo;
    property InpNo: string read FInpNo write SetInpNo;
    property InHospDateTime: TDateTime read FInHospDateTime write FInHospDateTime;
    property InDeptDateTime: TDateTime read FInDeptDateTime write FInDeptDateTime;
    property CareLevel: Byte read FCareLevel write FCareLevel;
    property VisitID: Byte read FVisitID write FVisitID;
    property DeptName: string read FDeptName write FDeptName;
  end;

  TRecordDeSetInfo = class(TObject)
  private
    FDesPID: Cardinal;
  public
    property DesPID: Cardinal read FDesPID write FDesPID;
  end;

  TRecordInfo = class(TObject)  // 能否和 TTemplateDeSetInfo 合并？
  private
    FID,
    FDesID  // 数据集ID
      : Cardinal;
    //FSignature: Boolean;  // 就否已经签名
    FNameEx: string;
  public
    property ID: Cardinal read FID write FID;
    property DesID: Cardinal read FDesID write FDesID;
    //property Signature: Boolean read FSignature write FSignature;
    property NameEx: string read FNameEx write FNameEx;
  end;

  TDeSetInfo = class(TObject)  // 数据集信息
  public
    const
      // 数据集
      /// <summary> 数据集正文 </summary>
      CLASS_DATA = 1;
      /// <summary> 数据集页眉 </summary>
      CLASS_HEADER = 2;
      /// <summary> 数据集页脚 </summary>
      CLASS_FOOTER = 3;

      // 使用范围 1临床 2护理 3临床及护理
      /// <summary> 模板使用范围 临床 </summary>
      USERANG_CLINIC = 1;
      /// <summary> 模板使用范围 护理 </summary>
      USERANG_NURSE = 2;
      /// <summary> 模板使用范围 临床及护理 </summary>
      USERANG_CLINICANDNURSE = 3;

      // 住院or门诊 1住院 2门诊 3住院及门诊
      /// <summary> 住院 </summary>
      INOROUT_IN = 1;
      /// <summary> 门诊 </summary>
      INOROUT_OUT = 2;
      /// <summary> 住院及门诊 </summary>
      INOROUT_INOUT = 3;
  public
    ID, PID, GroupClass,  // 模板类别 1正文 2页眉 3页脚
    GroupType,  // 模板类型 1数据集模板 2数据组模板
    UseRang,  // 使用范围 1临床 2护理 3临床及护理
    InOrOut  // 住院or门诊 1住院 2门诊 3住院及门诊
      : Integer;
    GroupName: string;

    const
      Proc = 13;
  end;

  TTemplateInfo = class(TObject)  // 模板信息
    ID, Owner, OwnerID, DesID: Integer;
    NameEx: string;
  end;

  TUpdateHint = procedure(const AHint: string) of object;
  THintProcesEvent = reference to procedure(const AUpdateHint: TUpdateHint);

  procedure HintFormShow(const AHint: string; const AHintProces: THintProcesEvent);

  /// <summary>
  /// 通过调用指定业务操作执行业务后返回的查询数据
  /// </summary>
  /// <param name="ABLLServerReady">准备调用业务</param>
  /// <param name="ABLLServerRun">操作执行业务后返回的数据</param>
  procedure BLLServerExec(const ABLLServerReady: TBLLServerReadyEvent; const ABLLServerRun: TBLLServerRunEvent);

    /// <summary>
  /// 获取服务端当前最新的客户端版本号
  /// </summary>
  /// <param name="AVerID">版本ID(主要用于比较版本)</param>
  /// <param name="AVerStr">版本号(主要用于显示版本信息)</param>
  procedure GetLastVersion(var AVerID: Integer; var AVerStr: string);

  /// <summary>
  /// 按照指定的格式输出数据
  /// </summary>
  /// <param name="AFormatStr">格式</param>
  /// <param name="ASize">数据</param>
  /// <returns>格式化的数据</returns>
  function FormatSize(const AFormatStr: string; const ASize: Int64): string;

  function TreeNodeIsTemplate(const ANode: TTreeNode): Boolean;
  function TreeNodeIsRecordDeSet(const ANode: TTreeNode): Boolean;
  function TreeNodeIsRecord(const ANode: TTreeNode): Boolean;
  procedure GetTemplateContent(const ATempID: Cardinal; const AStream: TStream);
  procedure GetRecordContent(const ARecordID: Cardinal; const AStream: TStream);
  function GetDeSets: TObjectList<TDeSetInfo>;
  function GetDeSet(const AID: Integer): TDeSetInfo;
  function SignatureInchRecord(const ARecordID: Integer; const AUserID: string): Boolean;
  function GetInchRecordSignature(const ARecordID: Integer): Boolean;

var
  GClientParam: TClientParam;
  GRunPath: string;

implementation

uses
  Variants, emr_MsgPack, emr_BLLConst, emr_Entry, FireDAC.Stan.Intf, FireDAC.Stan.StorageBin;

var
  FDeSetInfos: TObjectList<TDeSetInfo>;

function GetDeSets: TObjectList<TDeSetInfo>;
begin
  if FDeSetInfos <> nil then
    Result := FDeSetInfos
  else
  begin
    BLLServerExec(
      procedure(const ABLLServerReady: TBLLServerProxy)
      begin
        ABLLServerReady.Cmd := BLL_GETDATAELEMENTSETROOT;  // 获取数据集(根目录)信息
        ABLLServerReady.BackDataSet := True;  // 告诉服务端要将查询数据集结果返回
      end,
      procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
      var
        vDeSetInfo: TDeSetInfo;
      begin
        if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
        begin
          raise Exception.Create(ABLLServer.MethodError);
          Exit;
        end;

        if AMemTable <> nil then
        begin
          FDeSetInfos := TObjectList<TDeSetInfo>.Create;

          with AMemTable do
          begin
            First;
            while not Eof do
            begin
              vDeSetInfo := TDeSetInfo.Create;
              vDeSetInfo.ID := FieldByName('id').AsInteger;
              vDeSetInfo.PID := FieldByName('pid').AsInteger;
              vDeSetInfo.GroupClass := FieldByName('Class').AsInteger;
              vDeSetInfo.GroupType := FieldByName('Type').AsInteger;
              vDeSetInfo.GroupName := FieldByName('Name').AsString;
              FDeSetInfos.Add(vDeSetInfo);

              Next;
            end;
          end;
        end;
      end);
  end;
end;

procedure HintFormShow(const AHint: string; const AHintProces: THintProcesEvent);
var
  vFrmHint: TfrmHint;
begin
  vFrmHint := TfrmHint.Create(nil);
  try
    vFrmHint.lblHint.Caption := AHint;
    vFrmHint.Show;

    AHintProces(vFrmHint.UpdateHint);
  finally
    FreeAndNil(vFrmHint);
  end;
end;

function GetDeSet(const AID: Integer): TDeSetInfo;
var
  i: Integer;
begin
  Result := nil;
  
  if FDeSetInfos = nil then
    GetDeSets;

  for i := 0 to FDeSetInfos.Count - 1 do
  begin
    if FDeSetInfos[i].ID = AID then
    begin
      Result := FDeSetInfos[i];
      Break;
    end;
  end;
end;

function SignatureInchRecord(const ARecordID: Integer; const AUserID: string): Boolean;
begin
  Result := False;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_INCHRECORDSIGNATURE;  // 住院病历签名
      ABLLServerReady.ExecParam.I['RID'] := ARecordID;
      ABLLServerReady.ExecParam.S['UserID'] := AUserID;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
        raise Exception.Create(ABLLServer.MethodError);
    end);

  Result := True;
end;

function GetInchRecordSignature(const ARecordID: Integer): Boolean;
var
  vSignatureCount: Integer;
begin
  Result := False;
  vSignatureCount := 0;

  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETINCHRECORDSIGNATURE;  // 获取住院病历签名信息
      ABLLServerReady.ExecParam.I['RID'] := ARecordID;
      ABLLServerReady.BackDataSet := True;
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
        raise Exception.Create(ABLLServer.MethodError);

      if AMemTable <> nil then
        vSignatureCount := AMemTable.RecordCount;
    end);

  Result := vSignatureCount > 0;
end;

function TreeNodeIsTemplate(const ANode: TTreeNode): Boolean;
begin
  Result := (ANode <> nil) and (TObject(ANode.Data) is TTemplateInfo);
end;

function TreeNodeIsRecordDeSet(const ANode: TTreeNode): Boolean;
begin
  Result := (ANode <> nil) and (TObject(ANode.Data) is TRecordDeSetInfo);
end;

function TreeNodeIsRecord(const ANode: TTreeNode): Boolean;
begin
  Result := (ANode <> nil) and (TObject(ANode.Data) is TRecordInfo);
end;

procedure GetTemplateContent(const ATempID: Cardinal; const AStream: TStream);
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETTEMPLATECONTENT;  // 获取模板分组子分组和模板
      ABLLServerReady.ExecParam.I['TID'] := ATempID;
      ABLLServerReady.AddBackField('content');
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
        raise Exception.Create(ABLLServer.MethodError);

      ABLLServer.BackField('content').SaveBinaryToStream(AStream);
    end);
end;

procedure GetRecordContent(const ARecordID: Cardinal; const AStream: TStream);
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    begin
      ABLLServerReady.Cmd := BLL_GETINCHRECORDCONTENT;  // 获取模板分组子分组和模板
      ABLLServerReady.ExecParam.I['RID'] := ARecordID;
      ABLLServerReady.AddBackField('content');
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then  // 服务端方法返回执行不成功
        raise Exception.Create(ABLLServer.MethodError);

      ABLLServer.BackField('content').SaveBinaryToStream(AStream);
    end);
end;

procedure GetLastVersion(var AVerID: Integer; var AVerStr: string);
var
  vVerID: Integer;
  vVerStr: string;
begin
  vVerID := 0;
  vVerStr := '';
  BLLServerExec(
    procedure(const ABllServerReady: TBLLServerProxy)
    begin
      ABllServerReady.Cmd := BLL_GETLASTVERSION;  // 获取要升级的最新版本号
      ABllServerReady.AddBackField('id');
      ABllServerReady.AddBackField('Version');
    end,
    procedure(const ABLLServer: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServer.MethodRunOk then
        raise Exception.Create(ABLLServer.MethodError);

      vVerID := ABLLServer.BackField('id').AsInteger;  // 版本ID
      vVerStr := ABLLServer.BackField('Version').AsString;  // 版本号
    end);
  AVerID := vVerID;
  AVerStr := vVerStr;
end;

function FormatSize(const AFormatStr: string; const ASize: Int64): string;
begin
  Result := '';
  if ASize < 1024 then  // 字节
    Result := ASize.ToString + 'B'
  else
  if (ASize >= 1024) and (ASize < 1024 * 1024) then  // KB
    Result := FormatFloat(AFormatStr, ASize / 1024) + 'KB'
  else  // MB
    Result := FormatFloat(AFormatStr, ASize / (1024 * 1024)) + 'MB';
end;

{ TUserInfo }

procedure TUserInfo.Clear;
begin
  inherited Clear;
  FGroupDeptIDs := '';
  if not FFunCDS.IsEmpty then  // 清除功能
    FFunCDS.EmptyDataSet;
end;

constructor TUserInfo.Create;
begin
  FFunCDS := TFDMemTable.Create(nil);
end;

destructor TUserInfo.Destroy;
begin
  FFunCDS.Free;
  inherited;
end;

function TUserInfo.FormUnControlAuth(const AFormAuthControls: TFDMemTable;
  const AControlName: string; const ADeptID: Integer;
  const APerID: string): Boolean;
begin

end;

function TUserInfo.FunAuth(const AFunID, ADeptID: Integer;
  const APerID: string): Boolean;
begin
  Result := False;
end;

procedure TUserInfo.IniFormControlAuthInfo(const AForm: TComponent;
  const AAuthControls: TFDMemTable);
//var
//  i: Integer;
begin
  // 先将控件的权限属性释放防止上一次的信息影响本次调用
//  for i := 0 to AForm.ComponentCount - 1 do
//  begin
//    if (AForm.Components[i] is TControl) and ((AForm.Components[i] as TControl).TagObject <> nil) then
//      (AForm.Components[i] as TControl).TagObject.Free;
//  end;
//
//  if not AAuthControls.IsEmpty then  // 清空已有的权限控件数据
//    AAuthControls.EmptyDataSet;
//
//  BLLServerExec(
//    procedure(const ABLLServer: TBLLServerProxy)
//    var
//      vExecParam: TMsgPack;
//    begin
//      ABLLServer.Cmd := BLL_GETCONTROLSAUTH;  // 获取指定窗体上所有受权限控制的控件
//      vExecParam := ABLLServer.ExecParam;
//      vExecParam.S['FormName'] := AForm.Name;  // 窗体名
//      ABLLServer.BackDataSet := True;
//    end,
//    procedure(const ABLLServer: TBLLServerProxy)
//
//    var
//      vHasAuth: Boolean;
//      vControl: TControl;
//      vCustomFunInfo: TCustomFunInfo;
//    begin
//      if not ABLLServer.MethodRunOk then
//        raise Exception.Create('异常：获取窗体受权限控制控件错误！');
//
//      if not VarIsEmpty(ABLLServer.BLLDataSet) then  // 有受权限控制的控件处理为无权限状态
//      begin
//        AAuthControls.Data := ABLLServer.BLLDataSet;  // 存储当前窗体所有受权限管理的控件及控件对应的功能ID
//        AAuthControls.First;
//        while not AAuthControls.Eof do
//        begin
//          vHasAuth := False;
//          vControl := GetControlByName(AForm, AAuthControls.FieldByName('ControlName').AsString);
//          if vControl <> nil then  // 找到受权限控制的控件
//          begin
//            // 控制控件的状态
//            if not GUserInfo.FunCDS.IsEmpty then  // 当前用户有功能权限数据
//            begin
//              if GUserInfo.FunCDS.Locate('FunID', AAuthControls.FieldByName('FunID').AsInteger,
//                [TLocateOption.loCaseInsensitive])
//              then  // 当前用户有此功能的权限
//              begin
//                // 根据当前用户使用此功能的权限范围设置控件的权限属性
//                if vControl.TagObject <> nil then  // 如果控件有权限属性则先释放
//                  vControl.TagObject.Free;
//
//                // 将当前用户使用该控件的权限范围绑定到控件上
//                vCustomFunInfo := TCustomFunInfo.Create;
//                vCustomFunInfo.FunID := AAuthControls.FieldByName('FunID').AsInteger;
//                vCustomFunInfo.VisibleType := AAuthControls.FieldByName('VisibleType').AsInteger;
//                vCustomFunInfo.RangeID := GUserInfo.FunCDS.FieldByName('RangeID').AsInteger;
//                vCustomFunInfo.RangeDepts := GUserInfo.FunCDS.FieldByName('RangeDept').AsString;
//                vControl.TagObject := vCustomFunInfo;
//
//                vHasAuth := True;
//              end;
//            end;
//
//            if vHasAuth then  // 有功能的权限
//            begin
//              vControl.Visible := True;
//              vControl.Enabled := True;
//            end
//            else  // 当前用户无此功能的权限
//            begin
//              if AAuthControls.FieldByName('VisibleType').AsInteger = 0 then  // 无权限时不显示
//                vControl.Visible := False
//              else
//              if AAuthControls.FieldByName('VisibleType').AsInteger = 1 then  // 无权限时不可用
//              begin
//                vControl.Visible := True;
//                vControl.Enabled := False;
//              end;
//            end;
//          end;
//
//          AAuthControls.Next;
//        end;
//      end;
//    end);
end;

procedure TUserInfo.IniFuns;
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    var
      vExecParam: TMsgPack;
    begin
      ABLLServerReady.Cmd := BLL_GETUSERFUNS;  // 获取用户配置的所有功能
      vExecParam := ABLLServerReady.ExecParam;
      vExecParam.S[TUser.ID] := ID;
      ABLLServerReady.BackDataSet := True;
    end,
    procedure(const ABLLServerRun: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServerRun.MethodRunOk then
        raise Exception.Create(ABLLServerRun.MethodError); // Exit;  // ShowMessage(ABLLServer.MethodError);

      if AMemTable <> nil then
      begin
        FFunCDS.Close;
        FFunCDS.Data := AMemTable.Data;
      end;
    end);
end;

procedure TUserInfo.IniGroupDepts;
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    var
      vExecParam: TMsgPack;
    begin
      ABLLServerReady.Cmd := BLL_GETUSERGROUPDEPTS;  // 获取指定用户所有工作组对应的科室
      vExecParam := ABLLServerReady.ExecParam;
      vExecParam.S[TUser.ID] := ID;
      ABLLServerReady.BackDataSet := True;
    end,
    procedure(const ABLLServerRun: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServerRun.MethodRunOk then
        raise Exception.Create(ABLLServerRun.MethodError);  //Exit;  // ShowMessage(ABLLServer.MethodError);

      if AMemTable <> nil then
      begin
        AMemTable.First;
        while not AMemTable.Eof do  // 遍历科室
        begin
          if FGroupDeptIDs = '' then
            FGroupDeptIDs := AMemTable.FieldByName(TUser.DeptID).AsString
          else
            FGroupDeptIDs := FGroupDeptIDs + ',' + AMemTable.FieldByName(TUser.DeptID).AsString;

          AMemTable.Next;
        end;
      end;
    end);
end;

procedure TUserInfo.IniUserInfo;
begin
  BLLServerExec(
    procedure(const ABLLServerReady: TBLLServerProxy)
    var
      vExecParam: TMsgPack;
    begin
      ABLLServerReady.Cmd := BLL_GETUSERINFO;  // 获取指定用户的信息
      vExecParam := ABLLServerReady.ExecParam;
      vExecParam.S[TUser.ID] := ID;  // 用户ID

      ABLLServerReady.AddBackField(TUser.NameEx);
      ABLLServerReady.AddBackField(TUser.DeptID);
      ABLLServerReady.AddBackField(TUser.DeptName);
    end,

    procedure(const ABLLServerRun: TBLLServerProxy; const AMemTable: TFDMemTable = nil)
    begin
      if not ABLLServerRun.MethodRunOk then
        raise Exception.Create(ABLLServerRun.MethodError);  //Exit;

      NameEx := ABLLServerRun.BackField(TUser.NameEx).AsString;  // 用户姓名
      DeptID := ABLLServerRun.BackField(TUser.DeptID).AsString;  // 所属科室ID
      DeptName := ABLLServerRun.BackField(TUser.DeptName).AsString;  // 科室
    end);
end;

procedure TUserInfo.SetFormAuthControlState(const AForm: TComponent;
  const ADeptID: Integer; const APersonID: string);
//var
//  i: Integer;
//  vControl: TControl;
begin
//  for i := 0 to AForm.ComponentCount - 1 do  // 遍历窗体的所有控件
//  begin
//    if AForm.Components[i] is TControl then
//    begin
//      vControl := AForm.Components[i] as TControl;
//      if vControl.TagObject <> nil then
//      begin
//        if Self.FunAuth((vControl.TagObject as TCustomFunInfo).FunID, ADeptID, APersonID) then  // 有权限
//        begin
//          vControl.Visible := True;
//          vControl.Enabled := True;
//        end
//        else  // 没有权限
//        begin
//          if (vControl.TagObject as TCustomFunInfo).VisibleType = 0 then  // 无权限，不可见
//            vControl.Visible := False
//          else
//          if (vControl.TagObject as TCustomFunInfo).VisibleType = 1 then  // 无权限，不可用
//          begin
//            vControl.Visible := True;
//            vControl.Enabled := False;
//          end;
//        end;
//      end;
//    end;
//  end;
end;

procedure TUserInfo.SetUserID(const Value: string);
begin
  Clear;
  inherited SetUserID(Value);
  if ID <> '' then
  begin
    IniUserInfo;    // 取用户基本信息
    IniGroupDepts;  // 取工作组对应的所有科室
    IniFuns;        // 取角色对应的所有功能及范围
  end;
end;

{ TBLLServer }

procedure BLLServerExec(const ABLLServerReady: TBLLServerReadyEvent; const ABLLServerRun: TBLLServerRunEvent);
var
  vBLLSrvProxy: TBLLServerProxy;
  vMemTable: TFDMemTable;
  vMemStream: TMemoryStream;
begin
  vBLLSrvProxy := TBLLServer.GetBLLServerProxy;
  try
    ABLLServerReady(vBLLSrvProxy);  // 设置调用业务
    if vBLLSrvProxy.DispatchPack then  // 服务端响应成功
    begin
      if vBLLSrvProxy.BackDataSet then  // 返回数据集
      begin
        vMemTable := TFDMemTable.Create(nil);
        vMemStream := TMemoryStream.Create;
        try
          vBLLSrvProxy.GetBLLDataSet(vMemStream);
          vMemStream.Position := 0;
          vMemTable.LoadFromStream(vMemStream, TFDStorageFormat.sfBinary);
        finally
          FreeAndNil(vMemStream);
        end;
      end
      else
        vMemTable := nil;

      ABLLServerRun(vBLLSrvProxy, vMemTable);  // 操作执行业务后返回的查询数据
    end;
  finally
    if vMemTable <> nil then
      FreeAndNil(vMemTable);
    FreeAndNil(vBLLSrvProxy);
  end;
end;

procedure TBLLServer.DoServerError(const AErrCode: Integer;
  const AParam: string);
begin
  if Assigned(FOnError) then
    FOnError(AErrCode, AParam);
end;

class function TBLLServer.GetBLLServerProxy: TBLLServerProxy;
begin
  Result := TBLLServerProxy.CreateEx(GClientParam.BLLServerIP, GClientParam.BLLServerPort);
  Result.TimeOut := GClientParam.TimeOut;
  Result.ReConnectServer;
end;

function TBLLServer.GetBLLServerResponse(const AMesc: Word): Boolean;
var
  vServerProxy: TBLLServerProxy;
begin
  Result := False;
  vServerProxy := TBLLServerProxy.CreateEx(GClientParam.BLLServerIP, GClientParam.BLLServerPort);
  try
    vServerProxy.OnError := DoServerError;
    vServerProxy.TimeOut := AMesc;
    vServerProxy.ReConnectServer;
    Result := vServerProxy.Active;
  finally
    FreeAndNil(vServerProxy);
  end;
end;

function TBLLServer.GetParam(const AParamName: string): string;
var
  vBLLSrvProxy: TBLLServerProxy;
  vExecParam: TMsgPack;
begin
  vBLLSrvProxy := GetBLLServerProxy;
  try
    vBLLSrvProxy.Cmd := BLL_COMM_GETPARAM;  // 调用获取服务端参数功能
    vExecParam := vBLLSrvProxy.ExecParam;  // 传递到服务端的参数数据存放的列表
    vExecParam.S['Name'] := AParamName;
    vBLLSrvProxy.AddBackField('value');

    if vBLLSrvProxy.DispatchPack then  // 执行方法成功(不代表方法执行的结果，仅表示服务端成功收到客户端调用请求并且处理完成)
      Result := vBLLSrvProxy.BackField('value').AsString;
  finally
    vBLLSrvProxy.Free;
  end;
end;

class function TBLLServer.GetServerDateTime: TDateTime;
var
  vBLLSrvProxy: TBLLServerProxy;
begin
  vBLLSrvProxy := GetBLLServerProxy;
  try
    vBLLSrvProxy.Cmd := BLL_SRVDT;  // 调用获取服务端时间功能
    vBLLSrvProxy.AddBackField('dt');

    if vBLLSrvProxy.DispatchPack then  // 执行方法成功(不代表方法执行的结果，仅表示服务端成功收到客户端调用请求并且处理完成)
      Result := vBLLSrvProxy.BackField('dt').AsDateTime;
  finally
    vBLLSrvProxy.Free;
  end;
end;

{ TCustomUserInfo }

procedure TCustomUserInfo.Clear;
begin
  FID := '';
  FNameEx := '';
end;

procedure TCustomUserInfo.SetUserID(const Value: string);
begin
  if FID <> Value then
    FID := Value;
end;

{ TPatientInfo }

procedure TPatientInfo.Assign(const ASource: TPatientInfo);
begin
  FInpNo := ASource.InpNo;
  FBedNo := ASource.BedNo;
  FNameEx := ASource.NameEx;
  FSex := ASource.Sex;
  FAge := ASource.Age;
  FDeptName := ASource.DeptName;
  FPatID := ASource.PatID;
  FInHospDateTime := ASource.InHospDateTime;
  FInDeptDateTime := ASource.InDeptDateTime;
  FCareLevel := ASource.CareLevel;
  FVisitID := ASource.VisitID;
end;

procedure TPatientInfo.SetInpNo(const AInpNo: string);
begin
  if FInpNo <> AInpNo then
  begin
    FInpNo := AInpNo;
  end;
end;

{ TUpdateFile }

constructor TUpdateFile.Create;
begin
  inherited Create;
end;

constructor TUpdateFile.Create(const AFileName, ARelativePath, AVersion,
  AHash: string; const ASize: Int64; const AVerID: Integer;
  const AEnforce: Boolean);
begin
  Create;
  FFileName := AFileName;
  FRelativePath := ARelativePath;
  FVersion := AVersion;
  FHash := AHash;
  FSize := ASize;
  FVerID := AVerID;
  FEnforce := AEnforce;
end;

destructor TUpdateFile.Destroy;
begin
  inherited Destroy;
end;

initialization

finalization
  if FDeSetInfos <> nil then
    FreeAndNil(FDeSetInfos);

end.
