Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$appName = 'C-Clean'
$displayName = 'C-Clean'
$sourceApp = Join-Path $PSScriptRoot 'SystemDriveCleanup.ps1'
$sourceIcon = Join-Path $PSScriptRoot 'NTL.ico'
$systemDriveRoot = [System.IO.Path]::GetPathRoot($env:SystemDrive + '\')
$nonSystemDrive = $null

function Show-InstallError {
    param([string]$Message)

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        '安装失败',
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
}

try {
    if (-not (Test-Path -LiteralPath $sourceApp -PathType Leaf)) {
        throw '安装包中缺少 C-Clean 程序文件。请重新下载完整安装包。'
    }
    if (-not (Test-Path -LiteralPath $sourceIcon -PathType Leaf)) {
        throw '安装包中缺少 NTL.ico 图标文件。请重新下载完整安装包。'
    }

    foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
        if (-not $drive.IsReady -or
            $drive.DriveType -notin @(
                [System.IO.DriveType]::Fixed,
                [System.IO.DriveType]::Removable
            )) {
            continue
        }
        if (-not $drive.RootDirectory.FullName.Equals(
                $systemDriveRoot,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
            $nonSystemDrive = $drive
            break
        }
    }

    if (-not $nonSystemDrive) {
        throw '没有检测到可用的非系统磁盘。请连接或挂载 D:、E: 等其他磁盘后再安装。程序不会安装到系统盘。'
    }

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = '请选择非系统磁盘上的安装位置。程序将安装到所选目录下的 C-Clean 文件夹。系统盘位置不可用于安装。'
    $folderDialog.SelectedPath = $nonSystemDrive.RootDirectory.FullName
    $folderDialog.ShowNewFolderButton = $true
    $dialogResult = $folderDialog.ShowDialog()
    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        return
    }

    $selectedRoot = [System.IO.Path]::GetPathRoot($folderDialog.SelectedPath)
    if ($selectedRoot.Equals($systemDriveRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        [System.Windows.Forms.MessageBox]::Show(
            '请选择非系统磁盘上的文件夹。本程序不会安装到系统盘。',
            '安装位置无效',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }

    $installDirectory = Join-Path $folderDialog.SelectedPath $appName
    $appPath = Join-Path $installDirectory 'SystemDriveCleanup.ps1'
    if (Test-Path -LiteralPath $installDirectory -PathType Container) {
        $overwrite = [System.Windows.Forms.MessageBox]::Show(
            ("安装目录已存在：`r`n{0}`r`n`r`n是否继续并更新程序文件？" -f $installDirectory),
            '确认安装位置',
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($overwrite -ne [System.Windows.Forms.DialogResult]::Yes) {
            return
        }
    }

    New-Item -ItemType Directory -Path $installDirectory -Force -ErrorAction Stop | Out-Null
    Copy-Item -LiteralPath $sourceApp -Destination $appPath -Force -ErrorAction Stop
    $iconPath = Join-Path $installDirectory 'NTL.ico'
    Copy-Item -LiteralPath $sourceIcon -Destination $iconPath -Force -ErrorAction Stop

    $shell = New-Object -ComObject WScript.Shell
    $powerShellPath = Join-Path $PSHOME 'powershell.exe'
    $arguments = '-NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File "' + $appPath + '"'
    $desktopShortcutPath = Join-Path ([Environment]::GetFolderPath('DesktopDirectory')) ($displayName + '.lnk')
    $startMenuDirectory = Join-Path ([Environment]::GetFolderPath('Programs')) $displayName
    New-Item -ItemType Directory -Path $startMenuDirectory -Force -ErrorAction Stop | Out-Null

    foreach ($shortcutPath in @(
        $desktopShortcutPath,
        (Join-Path $startMenuDirectory ($displayName + '.lnk'))
    )) {
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $powerShellPath
        $shortcut.Arguments = $arguments
        $shortcut.WorkingDirectory = $installDirectory
        $shortcut.Description = $displayName
        $shortcut.WindowStyle = 1
        $shortcut.IconLocation = "$iconPath,0"
        $shortcut.Save()
    }

    $launchNow = [System.Windows.Forms.MessageBox]::Show(
        ("安装完成。`r`n`r`n程序位置：{0}`r`n已创建桌面和开始菜单快捷方式。`r`n`r`n现在启动程序吗？" -f $appPath),
        'C-Clean 安装完成',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($launchNow -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Process -FilePath $powerShellPath -ArgumentList $arguments -WorkingDirectory $installDirectory -WindowStyle Hidden -ErrorAction Stop
    }
}
catch {
    Show-InstallError -Message $_.Exception.Message
    exit 1
}
