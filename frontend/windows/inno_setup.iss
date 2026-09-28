; Inno Setup Script for DeskAI Operations (AI Office IT Help Desk)
; Creates a single standalone setup installer EXE for Windows Desktop

#define MyAppName "DeskAI Operations"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "AI Office IT Solutions"
#define MyAppURL "https://github.com/aidesk"
#define MyAppExeName "ai_office_it_help_desk.exe"
#define MyAppAssocName MyAppName + " File"
#define MyAppAssocExt ".deskai"
#define MyAppAssocKey StringChange(MyAppAssocName, " ", "") + MyAppAssocExt

[Setup]
AppId={{9C15578F-8547-4C3D-9A6D-E5F69F8B2E10}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
ChangesAssociations=yes
DisableProgramGroupPage=yes
OutputBaseFilename=DeskAI_Operations_Setup_v1.0
Compression=lzma
SolidCompression=yes
WizardStyle=modern
OutputDir=..\build\installer

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; Package all files from the Flutter Windows Release output
Source: "..\build\windows\x64\runner\Release\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
