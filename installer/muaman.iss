; MUAMAN-13O deterministic Windows installer definition.
;
; This script is compiled exclusively by tools/release/package_windows_installer.ps1
; against a VERIFIED release payload staged from the canonical deterministic ZIP
; (produced by tools/release/package_windows_release.ps1). The script itself
; never runs a build; it consumes only the verified 16-file release payload.
;
; Determinism: the same compiler binary (ISCC.exe 6.7.3, SHA-256 pinned in
; tools/muaman13o/installer_contract.json) plus the same verified payload
; produces a byte-identical installer. No timestamp, GUID, or random value is
; introduced by this script. AppId is a single frozen GUID.

#ifndef AppSourceDir
  #define AppSourceDir "."
#endif

#ifndef OutDir
  #define OutDir "."
#endif

#ifndef OutName
  #define OutName "muaman-windows-installer"
#endif

[Setup]
; Stable, frozen Application ID - created once during MUAMAN-13O development and
; NEVER regenerated. Drives the per-user uninstall registry key and upgrade identity.
AppId={{299ADF2A-0E9E-4A25-916C-1CB8328D0E5E}

AppName=I-TECH للتكنولوجيا
AppVersion=1.0.0
AppPublisher=I-TECH للتكنولوجيا
AppCopyright=Copyright (C) 2026 I-TECH للتكنولوجيا. All rights reserved.
AppVerName=I-TECH للتكنولوجيا 1.0.0

; Per-user installation, no administrator requirement, no elevation.
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=

; x64-only application (verified PE machine 0x8664).
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

; Canonical per-user default location: %LOCALAPPDATA%\Programs\muaman_store.
DefaultDirName={localappdata}\Programs\muaman_store
DefaultGroupName=I-TECH للتكنولوجيا
DisableProgramGroupPage=yes

; Single flat Start Menu shortcut (no group folder).
; No Startup shortcut is created.
UninstallDisplayIcon={app}\muaman_store.exe
UninstallDisplayName=I-TECH للتكنولوجيا

; No restart requests, no close-app interference, no run-after-install.
CloseApplications=no
RestartApplications=no

; Deterministic compression settings.
Compression=lzma2/max
SolidCompression=yes
LZMAUseSeparateProcess=no

; No wizard at silent install; no post-install launch.
WizardStyle=modern

OutputDir={#OutDir}
OutputBaseFilename={#OutName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
; Desktop shortcut is an explicit OPTIONAL task, not created by default.
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Files]
; The 16 canonical release files, mapped explicitly from the verified staging
; root. No wildcards: the packaging entrypoint rejects any staging tree that
; does not exactly match the legal release manifest.
Source: "{#AppSourceDir}\muaman_store.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppSourceDir}\flutter_windows.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppSourceDir}\pdfium.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppSourceDir}\printing_plugin.dll"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\app.so"; DestDir: "{app}\data"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\icudtl.dat"; DestDir: "{app}\data"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\AssetManifest.bin"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\AssetManifest.json"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\FontManifest.json"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\NOTICES.Z"; DestDir: "{app}\data\flutter_assets"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\assets\fonts\NotoSansArabic-Bold.ttf"; DestDir: "{app}\data\flutter_assets\assets\fonts"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\assets\fonts\NotoSansArabic-Regular.ttf"; DestDir: "{app}\data\flutter_assets\assets\fonts"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\assets\fonts\THIRD_PARTY_NOTICES.txt"; DestDir: "{app}\data\flutter_assets\assets\fonts"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\fonts\MaterialIcons-Regular.otf"; DestDir: "{app}\data\flutter_assets\fonts"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\packages\cupertino_icons\assets\CupertinoIcons.ttf"; DestDir: "{app}\data\flutter_assets\packages\cupertino_icons\assets"; Flags: ignoreversion
Source: "{#AppSourceDir}\data\flutter_assets\shaders\ink_sparkle.frag"; DestDir: "{app}\data\flutter_assets\shaders"; Flags: ignoreversion

[Icons]
; Inno Setup appends the .lnk extension itself, so the names are given WITHOUT
; an extension (specifying one explicitly produces "<name>.lnk.lnk").
Name: "{autoprograms}\I-TECH للتكنولوجيا"; Filename: "{app}\muaman_store.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\I-TECH للتكنولوجيا"; Filename: "{app}\muaman_store.exe"; WorkingDir: "{app}"; Tasks: desktopicon

; No [Run] section: the application is never launched automatically at install time.

; The uninstaller removes every installed file and subdirectory but leaves the
; (now empty) top-level application directory behind. This rule deletes {app}
; ONLY when it is empty; any user business data left in {app} makes the directory
; non-empty and it is therefore preserved. Never deletes files itself.
[UninstallDelete]
Type: dirifempty; Name: "{app}"
