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
    m_AboutString: string;                                  // ����
    m_PhotoDir: string;                                     // ��ƬĿ¼
    m_VideoDir: string;                                     // ��ƵĿ¼
    m_DestDir: string;                                      // ��ʱĿ¼
    m_Camera: string;                                       // ��Ƭ����
    m_SubDir: string;                                       // �½���Ŀ¼
    m_ImageExt: string;                                     // ͼƬ��չ��
    m_ImageExtList: TStringList;                            // ͼƬ��չ���б�
    m_VideoExt: string;                                     // ��Ƶ��չ��
    m_VideoExtList: TStringList;                            // ��Ƶ��չ���б�
    m_FileList: TStringList;                                // �ļ��б�
    m_SubDirList: TStringList;                              // ��Ŀ¼�б�
    m_DateFormat: string;                                   // ���ڸ�ʽ
    m_IsMove: Boolean;                                      // �Ƿ��ƶ�

    // ����״̬��Ϣ
    procedure SetStatus(str: string; IsWarning: Boolean = False);

    // �������
    procedure SplitParams(str: string; var List: TStringList);

    // ��ȡJPGͼƬ����ʱ��
    function GetJpgImageDate(FileName: string): TDateTime;

    // �ļ�ʱ��ת����ʱ��
    function FileTimeToDateTime(FT: TFileTime): TDateTime;

    // ��ȡ�ļ�ʱ��
    function GetFileDate(FileName: string): TDateTime;

    // װ������
    function LoadSettings: Boolean;

    // ��������
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
  TotalFileNum: Integer;                                    // �ļ�����
  TodoFileNum: Integer;                                     // ��Ҫ������ļ���
  ProcessFileNum: Integer;                                  // �����˵��ļ���
  i, j: Cardinal;
  strExt: string;
  FileDate: TDateTime;
  DateDir: string;
  OutputDir, ImageDir, VideoDir: string;                    // ���Ŀ¼
  SubDir: string;                                           // �½���Ŀ¼
  FileName, FileExt: string;
  DstFileName: string;
begin
  // ��ȡ����
  m_PhotoDir := Trim(lbledtPhotoDir.Text);
  m_Camera := Trim(lbledtCamera.Text);
  m_SubDir := Trim(lbledtSubDir.Text);
  m_VideoDir := Trim(lbledtVideoDir.Text);
  m_ImageExt := Trim(lbledtImageExt.Text);
  m_VideoExt := Trim(lbledtVideoExt.Text);
  m_DestDir := Trim(lbledtDestDir.Text);
  m_DateFormat := Trim(lbledtDateFormat.Text);
  m_IsMove := chkMove.Checked;

  // ��ȡ��ƬĿ¼���ļ��б�
  if not GetFileListInDir(m_FileList, m_PhotoDir, true) then begin
    SetStatus('��ƬĿ¼�����ڣ�����', True);
    lbledtPhotoDir.SetFocus;
    Exit;
  end;

  // ������Ƭ����
  if m_Camera = '' then begin
    SetStatus('��Ƭ���Ͳ���Ϊ�գ�����', True);
    lbledtCamera.SetFocus;
    Exit;
  end;

  // �������ڸ�ʽ�����Ϊ�գ�Ĭ��Ϊ yyyy_mm_dd
  if m_DateFormat = '' then m_DateFormat := 'yyyy_mm_dd';

  // ��ȡͼƬ��չ���б�����Ĭ��Ϊjpg
  m_ImageExtList.Clear;
  if m_ImageExt = '' then begin
    lbledtImageExt.Text := 'jpg';
    m_ImageExtList.Add('jpg');
  end
  else begin
    SplitParams(m_ImageExt, m_ImageExtList);

    // Ϊ����Ӧ ExtractFileExt() �õ��Ľ������ .��������ǰ������ .
    for i := 0 to m_ImageExtList.Count - 1 do
      m_ImageExtList.Strings[i] := '.' + Trim(m_ImageExtList.Strings[i]);
  end;

  // ��ȡ��Ƶ��չ���б�����Ĭ��Ϊmp4,mov
  m_VideoExtList.Clear;
  if m_VideoExt = '' then begin
    lbledtVideoExt.Text := 'mp4,mov';
    m_VideoExtList.Add('.mp4');
    m_VideoExtList.Add('.mov');
  end
  else begin
    SplitParams(m_VideoExt, m_VideoExtList);

    // Ϊ����Ӧ ExtractFileExt() �õ��Ľ������ .��������ǰ������ .
    for i := 0 to m_VideoExtList.Count - 1 do
      m_VideoExtList.Strings[i] := '.' + Trim(m_VideoExtList.Strings[i]);
  end;

  // �����ƬĿ¼�µ��ļ�����
  if m_FileList.Count = 0 then begin
    SetStatus('��ƬĿ¼��û���ļ�������', True);
    Exit;
  end;

  // ������չ��
  TotalFileNum := m_FileList.Count;

  for i := m_FileList.Count - 1 downto 0 do begin
    // ȡ��Сд��չ��
    strExt := LowerCase(ExtractFileExt(m_FileList.Strings[i]));

    // ���������չ���б��У������ɾ��
    if (m_ImageExtList.IndexOf(strExt) < 0) and (m_VideoExtList.IndexOf(strExt) < 0) then m_FileList.Delete(i);
  end;

  // ���û��ʣ�µ��ļ������˳�
  TodoFileNum := m_FileList.Count;

  if m_FileList.Count = 0 then begin
    SetStatus('��ƬĿ¼��û���ʺϵ��ļ�������', True);
    lbledtImageExt.SetFocus;
    Exit;
  end;

  // ��ȡ��Ŀ¼�б�
  m_SubDirList.Clear;
  if m_SubDir <> '' then begin
    SplitParams(m_SubDir, m_SubDirList);
    for i := 0 to m_SubDirList.Count - 1 do
      m_SubDirList.Strings[i] := Trim(m_SubDirList.Strings[i]);
  end;

  // ������ʱĿ¼�����û�оͽ������������û�С�\���ͼ���
  if not DirectoryExists(m_DestDir) then ForceDirectories(m_DestDir);
  if RightStr(m_DestDir, 1) <> '\' then m_DestDir := m_DestDir + '\';

  // �����ļ����������ý����������ֵ
  pbProgress.Position := 0;
  pbProgress.Min := 0;
  pbProgress.Max := TodoFileNum;
  pbProgress.Show;

  // �����ÿ���ļ����д���
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
      Application.MessageBox(PChar(Format('�ļ�"%s"��ȡ����ʧ��', [FileName])),
        'ע��', MB_OK + MB_ICONINFORMATION + MB_TOPMOST);
      Continue;
    end;

    // �������
    DateDir := FormatDateTime(m_DateFormat, FileDate);

    // ������Ŀ¼
    if m_SubDirList.Count > 0 then
      for j := 0 to m_SubDirList.Count - 1 do
        ForceDirectories(m_DestDir + DateDir + '\' + m_SubDirList.Strings[j]);

    // ���ļ�������ȥ
    if m_VideoExtList.IndexOf(FileExt) >= 0 then
      OutputDir := Format('%s%s\%s\', [m_DestDir, DateDir, m_VideoDir])
    else
      OutputDir := Format('%s%s\%s\', [m_DestDir, DateDir, m_Camera]);

    if not DirectoryExists(OutputDir) then ForceDirectories(OutputDir);
    if CopyFile(PChar(FileName), PChar(OutputDir + ExtractFileName(FileName)), False) then begin
      Inc(ProcessFileNum);

      // ����ɹ�����Ҫ�ƶ�����ɾ�����ص��ļ�
      if m_IsMove then DeleteFile(FileName);
    end;
  end;

  // ���ؽ�����
  pbProgress.Hide;

  // ��ʾ״̬
  SetStatus(Format('��ƬĿ¼�¹����ļ� %d ����������չ���Ĺ��� %d ����%s�ɹ������� %d ��',
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
  lbledtPhotoDir.EditLabel.Caption := '��ƬĿ¼';
  lbledtCamera.EditLabel.Caption := '�������';
  lbledtSubDir.EditLabel.Caption := '�½���Ŀ¼';
  lbledtVideoDir.EditLabel.Caption := '��Ƶ��Ŀ¼';
  lbledtImageExt.EditLabel.Caption := 'ͼƬ��չ������';
  lbledtVideoExt.EditLabel.Caption := '��Ƶ��չ������';
  lbledtDestDir.EditLabel.Caption := '��ʱĿ¼';
  lbledtDateFormat.EditLabel.Caption := '���ڸ�ʽ';
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

    // ���û��Exifʱ�䣬�����ļ�ʱ�����
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
    Self.Caption := IniFile.ReadString('UI', 'Title', '����������������Ƭ����Ƶ');
    Self.Caption := Format('%s [%s]', [Self.Caption, VERSION]);
    lbledtPhotoDir.EditLabel.Caption := IniFile.ReadString('UI', 'PhotoDir', '��ƬĿ¼');
    lbledtCamera.EditLabel.Caption := IniFile.ReadString('UI', 'Camera', '�������');
    lbledtSubDir.EditLabel.Caption := IniFile.ReadString('UI', 'SubDir', '�½���Ŀ¼');
    lbledtVideoDir.EditLabel.Caption := IniFile.ReadString('UI', 'VideoDir', '��Ƶ��Ŀ¼');
    lbledtImageExt.EditLabel.Caption := IniFile.ReadString('UI', 'ImageExt', 'ͼƬ��չ������');
    lbledtVideoExt.EditLabel.Caption := IniFile.ReadString('UI', 'VideoExt', '��Ƶ��չ������');
    lbledtDestDir.EditLabel.Caption := IniFile.ReadString('UI', 'DestDir', '��ʱĿ¼');
    lbledtDateFormat.EditLabel.Caption := IniFile.ReadString('UI', 'DateFormat', '���ڸ�ʽ');
    chkMove.Caption := IniFile.ReadString('UI', 'IsMove', '�ƶ���Ƭ����Ƶ');
    btnButtons.CaptionOk := IniFile.ReadString('UI', 'OK', '����(&P)');
    btnButtons.CaptionHelp := IniFile.ReadString('UI', 'Quit', '�˳�(&X)');
    btnButtons.CaptionCancel := IniFile.ReadString('UI', 'About', '����(&A)');

    m_AboutString := IniFile.ReadString('Other', 'About', '�����������Ŀ¼�ڵ���Ƭ���������ڷ�����Ӧ��Ŀ¼������:ET�񹤣���Ŀ��ҳ:https://github.com/etworker/DateFolder');

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

