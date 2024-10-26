#define MyAppName "RetroTetris"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Wildy Sheverando"
#define MyAppURL "https://github.com/shiwildy/RetroTetris"
#define MyAppExeName "retrotetris.exe"

[Setup]
AppId={{527E0227-F3E6-4C74-861F-3A64C85AF584}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName=C:\Program Files\{#MyAppName}
DisableProgramGroupPage=yes
OutputDir="output\"
OutputBaseFilename=RetroTetris
SetupIconFile="path\RetroTetris-main\bin\image\retrotetris.ico"
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
Source: "\bin\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "\bin\image\*"; DestDir: "{app}\image"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "\bin\sound\*"; DestDir: "{app}\sound"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent