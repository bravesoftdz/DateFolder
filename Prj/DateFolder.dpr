program DateFolder;

uses
  Forms,
  frmDateFolder in '..\Form\frmDateFolder.pas' {DateFolderForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TDateFolderForm, DateFolderForm);
  Application.CreateForm(TDateFolderForm, DateFolderForm);
  Application.Run;
end.
