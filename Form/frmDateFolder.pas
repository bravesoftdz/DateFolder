// DateFolder
// Purpose: Organize photos and videos by recording date
// Author:  etworker
// Version:
//  - 0.1   Publish on github
//  - 0.1.1 Update About
//  - 0.1.2 Update config

unit frmDateFolder;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, RzPanel, RzDlgBtn, StdCtrls, ComCtrls, ActnList, StrUtils,
  DateUtils, IniFiles, CCR.Exif;

const
  VERSION: string = 'V0.1.1';

type
  TDateFolderForm = class(TForm)
    lbledtPhotoDir: TLabeledEdit;
    btnButtons: TRzDialogButtons;
    lbledtCamera: TLabeledEdit;
    lbledtDateFormat: TLabeledEdit;
    lbledtDestDir: TLabeledEdit;
    chkMove: TCheckBox;
    pbProgress: TProgressBar;
    actlstMain: TActionList;
    actProcess: TAction;
    actAbout: TAction;
    actClose: TAction;
    lbledtImageExt: TLabeledEdit;
    lbledtSubDir: TLabeledEdit;
    lblStatus: TLabel;
    lbledtVideoDir: TLabeledEdit;
    lbledtVideoExt: TLabeledEdit;
    procedure FormCreate(Sender: TObject);
    procedure actProcessExecute(Sender: TObject);
    procedure actAboutExecute(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    m_AboutString: string;                                  // 关于
    m_PhotoDir: string;                                     // 照片目录
    m_VideoDir: string;                                     // 视频目录
    m_DestDir: string;                                      // 临时目录
    m_Camera: string;                                       // 照片类型
    m_SubDir: string;                                       // 新建子目录
    m_ImageExt: string;                                     // 图片扩展名
    m_ImageExtList: TStringList;                            // 图片扩展名列表
    m_VideoExt: string;                                     // 视频扩展名
    m_VideoExtList: TStringList;                            // 视频扩展名列表
    m_FileList: TStringList;                                // 文件列表
    m_SubDirList: TStringList;                              // 子目录列表
    m_DateFormat: string;                                   // 日期格式
    m_IsMove: Boolean;                                      // 是否移动

    // 设置状态信息
    procedure SetStatus(str: string; IsWarning: Boolean = False);

    // 分离参数
    procedure SplitParams(str: string; var List: TStringList);

    // 获取JPG图片拍摄时间
    function GetJpgImageDate(FileName: string): TDateTime;

    // 文件时间转日期时间
    function FileTimeToDateTime(FT: TFileTime): TDateTime;

    // 获取文件时间
    function GetFileDate(FileName: string): TDateTime;

    // 装载配置
    function LoadSettings: Boolean;

    // 保存配置
    function SaveSettings: Boolean;
  public
    { Public declarations }
  end;

var
  DateFolderForm: TDateFolderForm;

implementation

{$R *.dfm}

procedure SplitString(str: string; Delimiter: string; var strList: TStringList);
var
  DelimiterPos: Integer;
begin
  //Count := ExtractStrings([Delimiter], [' '], PChar(str), strList);

  strList.Clear;
  if str = '' then Exit;

  DelimiterPos := pos(Delimiter, str);
  while DelimiterPos > 0 do begin
    strList.Add(Copy(str, 1, DelimiterPos - 1));
    Delete(str, 1, DelimiterPos + Length(Delimiter) - 1);
    DelimiterPos := Pos(Delimiter, str);
  end;
  strList.Add(str);
end;

function GetFileListInDir(var List: TStringList; const Dir: string; IsPlusDir: Boolean = True): Boolean;
var
  fd: TSearchRec;
begin
  Result := False;

  List.Clear;

  if not DirectoryExists(Dir) then exit;

  if FindFirst(Dir + '\*.*', faAnyFile, fd) = 0 then begin
    while FindNext(fd) = 0 do
      if (fd.Name <> '.') and (fd.Name <> '..') then
        if IsPlusDir then
          List.Add(Dir + '\' + fd.Name)
        else
          List.Add(fd.Name);

    SysUtils.FindClose(fd);
    Result := True;
  end;
end;

procedure TDateFolderForm.actAboutExecute(Sender: TObject);
begin
  SetStatus(m_AboutString);
end;

procedure TDateFolderForm.actCloseExecute(Sender: TObject);
begin
  Close;
end;

procedure TDateFolderForm.actProcessExecute(Sender: TObject);
var
  TotalFileNum: Integer;                                    // 文件总数
  TodoFileNum: Integer;                                     // 需要处理的文件数
  ProcessFileNum: Integer;                                  // 处理了的文件数
  i, j: Cardinal;
  strExt: string;
  FileDate: TDateTime;
  DateDir: string;
  OutputDir, ImageDir, VideoDir: string;                    // 输出目录
  SubDir: string;                                           // 新建子目录
  FileName, FileExt: string;
  DstFileName: string;
begin
  // 获取参数
  m_PhotoDir := Trim(lbledtPhotoDir.Text);
  m_Camera := Trim(lbledtCamera.Text);
  m_SubDir := Trim(lbledtSubDir.Text);
  m_VideoDir := Trim(lbledtVideoDir.Text);
  m_ImageExt := Trim(lbledtImageExt.Text);
  m_VideoExt := Trim(lbledtVideoExt.Text);
  m_DestDir := Trim(lbledtDestDir.Text);
  m_DateFormat := Trim(lbledtDateFormat.Text);
  m_IsMove := chkMove.Checked;

  // 获取照片目录的文件列表
  if not GetFileListInDir(m_FileList, m_PhotoDir, true) then begin
    SetStatus('照片目录不存在，请检查', True);
    lbledtPhotoDir.SetFocus;
    Exit;
  end;

  // 处理照片类型
  if m_Camera = '' then begin
    SetStatus('照片类型不能为空，请检查', True);
    lbledtCamera.SetFocus;
    Exit;
  end;

  // 处理日期格式，如果为空，默认为 yyyy_mm_dd
  if m_DateFormat = '' then m_DateFormat := 'yyyy_mm_dd';

  // 提取图片扩展名列表，若空默认为jpg
  m_ImageExtList.Clear;
  if m_ImageExt = '' then begin
    lbledtImageExt.Text := 'jpg';
    m_ImageExtList.Add('jpg');
  end
  else begin
    SplitParams(m_ImageExt, m_ImageExtList);

    // 为了适应 ExtractFileExt() 得到的结果都带 .，所以提前都加上 .
    for i := 0 to m_ImageExtList.Count - 1 do
      m_ImageExtList.Strings[i] := '.' + Trim(m_ImageExtList.Strings[i]);
  end;

  // 提取视频扩展名列表，若空默认为mp4,mov
  m_VideoExtList.Clear;
  if m_VideoExt = '' then begin
    lbledtVideoExt.Text := 'mp4,mov';
    m_VideoExtList.Add('.mp4');
    m_VideoExtList.Add('.mov');
  end
  else begin
    SplitParams(m_VideoExt, m_VideoExtList);

    // 为了适应 ExtractFileExt() 得到的结果都带 .，所以提前都加上 .
    for i := 0 to m_VideoExtList.Count - 1 do
      m_VideoExtList.Strings[i] := '.' + Trim(m_VideoExtList.Strings[i]);
  end;

  // 检查照片目录下的文件个数
  if m_FileList.Count = 0 then begin
    SetStatus('照片目录下没有文件，请检查', True);
    Exit;
  end;

  // 过滤扩展名
  TotalFileNum := m_FileList.Count;

  for i := m_FileList.Count - 1 downto 0 do begin
    // 取得小写扩展名
    strExt := LowerCase(ExtractFileExt(m_FileList.Strings[i]));

    // 如果不在扩展名列表中，则从中删除
    if (m_ImageExtList.IndexOf(strExt) < 0) and (m_VideoExtList.IndexOf(strExt) < 0) then m_FileList.Delete(i);
  end;

  // 如果没有剩下的文件，则退出
  TodoFileNum := m_FileList.Count;

  if m_FileList.Count = 0 then begin
    SetStatus('照片目录下没有适合的文件，请检查', True);
    lbledtImageExt.SetFocus;
    Exit;
  end;

  // 提取子目录列表
  m_SubDirList.Clear;
  if m_SubDir <> '' then begin
    SplitParams(m_SubDir, m_SubDirList);
    for i := 0 to m_SubDirList.Count - 1 do
      m_SubDirList.Strings[i] := Trim(m_SubDirList.Strings[i]);
  end;

  // 处理临时目录，如果没有就建立，如果后面没有“\”就加上
  if not DirectoryExists(m_DestDir) then ForceDirectories(m_DestDir);
  if RightStr(m_DestDir, 1) <> '\' then m_DestDir := m_DestDir + '\';

  // 根据文件个数，设置进度条的最大值
  pbProgress.Position := 0;
  pbProgress.Min := 0;
  pbProgress.Max := TodoFileNum;
  pbProgress.Show;

  // 逐个对每个文件进行处理
  ProcessFileNum := 0;
  for i := 0 to m_FileList.Count - 1 do begin
    Application.HandleMessage;
    pbProgress.Position := i;

    FileName := m_FileList.Strings[i];
    FileExt := LowerCase(ExtractFileExt(FileName));
    if FileExt = '.jpg' then
      FileDate := GetJpgImageDate(FileName)
    else
      FileDate := GetFileDate(FileName);

    if FileDate = 0 then begin
      Application.MessageBox(PChar(Format('文件"%s"提取日期失败', [FileName])),
        '注意', MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
      Continue;
    end;

    // 获得日期
    DateDir := FormatDateTime(m_DateFormat, FileDate);

    // 创建子目录
    if m_SubDirList.Count > 0 then
      for j := 0 to m_SubDirList.Count - 1 do
        ForceDirectories(m_DestDir + DateDir + '\' + m_SubDirList.Strings[j]);

    // 将文件拷贝过去
    if m_VideoExtList.IndexOf(FileExt) >= 0 then
      OutputDir := Format('%s%s\%s\', [m_DestDir, DateDir, m_VideoDir])
    else
      OutputDir := Format('%s%s\%s\', [m_DestDir, DateDir, m_Camera]);

    if not DirectoryExists(OutputDir) then ForceDirectories(OutputDir);
    if CopyFile(PChar(FileName), PChar(OutputDir + ExtractFileName(FileName)), False) then begin
      Inc(ProcessFileNum);

      // 如果成功且需要移动，则删除本地的文件
      if m_IsMove then DeleteFile(FileName);
    end;
  end;

  // 隐藏进度条
  pbProgress.Hide;

  // 提示状态
  SetStatus(Format('照片目录下共有文件 %d 个，符合扩展名的共有 %d 个，%s成功处理了 %d 个',
    [TotalFileNum, TodoFileNum, #13#10, ProcessFileNum]));
end;

function TDateFolderForm.FileTimeToDateTime(FT: TFileTime): TDateTime;
var
  SysTime: TSystemTime;
  LocalFT: TFileTime;
begin
  try
    // Convert UTC time to local time
    Win32Check(FileTimeToLocalFileTime(FT, LocalFT));

    // Convert file time to system time, raising exception on error
    Win32Check(FileTimeToSystemTime(LocalFT, SysTime));

    // Convert system time to Delphi date time, raising excpetion on error
    Result := SystemTimeToDateTime(SysTime);
  except
    Result := 0;
  end;
end;

procedure TDateFolderForm.FormCreate(Sender: TObject);
begin
  lbledtPhotoDir.EditLabel.Caption := '照片目录';
  lbledtCamera.EditLabel.Caption := '相机名称';
  lbledtSubDir.EditLabel.Caption := '新建子目录';
  lbledtVideoDir.EditLabel.Caption := '视频子目录';
  lbledtImageExt.EditLabel.Caption := '图片扩展名过滤';
  lbledtVideoExt.EditLabel.Caption := '视频扩展名过滤';
  lbledtDestDir.EditLabel.Caption := '临时目录';
  lbledtDateFormat.EditLabel.Caption := '日期格式';
  lblStatus.Caption := '';
  pbProgress.Hide;

  m_ImageExtList := TStringList.Create;
  m_VideoExtList := TStringList.Create;
  m_FileList := TStringList.Create;
  m_SubDirList := TStringList.Create;

  LoadSettings;
end;

procedure TDateFolderForm.FormDestroy(Sender: TObject);
begin
  SaveSettings;

  m_ImageExtList.Free;
  m_VideoExtList.Free;
  m_FileList.Free;
  m_SubDirList.Free;
end;

function TDateFolderForm.GetFileDate(FileName: string): TDateTime;
var
  fad: TWin32FileAttributeData;
  LastWriteTime: TDateTime;
begin
  Result := 0;
  if not GetFileAttributesEx(PChar(FileName), GetFileExInfoStandard, @fad) then Exit;

  Result := FileTimeToDateTime(fad.ftLastWriteTime);
end;

function TDateFolderForm.GetJpgImageDate(FileName: string): TDateTime;
var
  ExifData: TExifDataPatcher;
  FileDate: TDateTime;
begin
  Result := 0;
  try
    try
      ExifData := TExifDataPatcher.Create(FileName);
    except
      on E: EInvalidJPEGHeader do begin
        //Application.ShowException(E);
        SetStatus(Format('%s is not jpg file', [FileName]), True);
        Exit;
      end
    else
      //raise;
      SetStatus(Format('%s read failed', [FileName]), True);
      Exit;
    end;

    // 如果没有Exif时间，则用文件时间替代
    FileDate := ExifData.DateTimeOriginal;
    if FileDate = 0 then FileDate := ExifData.FileDateTime;

    Result := FileDate;
  finally
    ExifData.Free;
  end;
end;

function TDateFolderForm.LoadSettings: Boolean;
var
  IniFile: TIniFile;
  FileName: string;
begin
  FileName := StringReplace(ParamStr(0), '.exe', '.ini', [rfIgnoreCase]);
  IniFile := TIniFile.Create(FileName);
  try
    Self.Caption := IniFile.ReadString('UI', 'Title', '按拍摄日期整理照片及视频');
    Self.Caption := Format('%s [%s]', [Self.Caption, VERSION]);
    lbledtPhotoDir.EditLabel.Caption := IniFile.ReadString('UI', 'PhotoDir', '照片目录');
    lbledtCamera.EditLabel.Caption := IniFile.ReadString('UI', 'Camera', '相机名称');
    lbledtSubDir.EditLabel.Caption := IniFile.ReadString('UI', 'SubDir', '新建子目录');
    lbledtVideoDir.EditLabel.Caption := IniFile.ReadString('UI', 'VideoDir', '视频子目录');
    lbledtImageExt.EditLabel.Caption := IniFile.ReadString('UI', 'ImageExt', '图片扩展名过滤');
    lbledtVideoExt.EditLabel.Caption := IniFile.ReadString('UI', 'VideoExt', '视频扩展名过滤');
    lbledtDestDir.EditLabel.Caption := IniFile.ReadString('UI', 'DestDir', '临时目录');
    lbledtDateFormat.EditLabel.Caption := IniFile.ReadString('UI', 'DateFormat', '日期格式');
    chkMove.Caption := IniFile.ReadString('UI', 'IsMove', '移动照片和视频');
    btnButtons.CaptionOk := IniFile.ReadString('UI', 'OK', '处理(&P)');
    btnButtons.CaptionHelp := IniFile.ReadString('UI', 'Quit', '退出(&X)');
    btnButtons.CaptionCancel := IniFile.ReadString('UI', 'About', '关于(&A)');

    m_AboutString := IniFile.ReadString('Other', 'About', '本软件用来将目录内的照片按拍照日期放入相应的目录。作者:ET民工，项目主页:https://github.com/etworker/DateFolder');

    lbledtPhotoDir.Text := IniFile.ReadString('Config', 'PhotoDir', '');
    lbledtCamera.Text := IniFile.ReadString('Config', 'Camera', 'iPhone 6s');
    lbledtSubDir.Text := IniFile.ReadString('Config', 'SubDir', '');
    lbledtVideoDir.Text := IniFile.ReadString('Config', 'VideoDir', 'Video');
    lbledtImageExt.Text := IniFile.ReadString('Config', 'ImageExt', 'jpg');
    lbledtVideoExt.Text := IniFile.ReadString('Config', 'VideoExt', 'mp4,mov');
    lbledtDestDir.Text := IniFile.ReadString('Config', 'DestDir', '');
    lbledtDateFormat.Text := IniFile.ReadString('Config', 'DateFormat', 'yyyy_mm_dd');
    chkMove.Checked := IniFile.ReadBool('Config', 'IsMove', True);
  finally
    IniFile.Free;
  end;
end;

function TDateFolderForm.SaveSettings: Boolean;
var
  IniFile: TIniFile;
  FileName: string;
begin
  FileName := StringReplace(ParamStr(0), '.exe', '.ini', [rfIgnoreCase]);
  IniFile := TIniFile.Create(FileName);
  try
    IniFile.WriteString('Config', 'PhotoDir', lbledtPhotoDir.Text);
    IniFile.WriteString('Config', 'Camera', lbledtCamera.Text);
    IniFile.WriteString('Config', 'SubDir', lbledtSubDir.Text);
    IniFile.WriteString('Config', 'ImageExt', lbledtImageExt.Text);
    IniFile.WriteString('Config', 'VideoExt', lbledtVideoExt.Text);
    IniFile.WriteString('Config', 'DestDir', lbledtDestDir.Text);
    IniFile.WriteString('Config', 'DateFormat', lbledtDateFormat.Text);
    IniFile.WriteBool('Config', 'IsMove', chkMove.Checked);
  finally
    IniFile.Free;
  end;
end;

procedure TDateFolderForm.SetStatus(str: string; IsWarning: Boolean);
begin
  with lblStatus do begin
    Layout := tlCenter;
    if IsWarning then
      Font.Color := clRed
    else
      Font.Color := clBlack;

    Caption := str;
  end;
end;

procedure TDateFolderForm.SplitParams(str: string; var List: TStringList);
const
  SPLIT_CHARS: string = ',;|/';
var
  i: Cardinal;
begin
  for i := 0 to Length(SPLIT_CHARS) - 1 do begin
    if Pos(SPLIT_CHARS[i], str) > 0 then begin
      SplitString(str, SPLIT_CHARS[i], List);
      Exit;
    end;
  end;

  List.Add(str);
end;

end.

