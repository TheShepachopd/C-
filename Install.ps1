Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

$appName = 'SystemDriveCleanup'
$displayName = '系统盘清理工具'
$sourceApp = Join-Path $PSScriptRoot 'SystemDriveCleanup.ps1'
$defaultParent = Join-Path $env:LOCALAPPDATA 'Programs'

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
        throw '安装包中缺少程序文件 SystemDriveCleanup.ps1。请重新下载完整安装包。'
    }

    if (-not (Test-Path -LiteralPath $defaultParent -PathType Container)) {
        New-Item -ItemType Directory -Path $defaultParent -Force -ErrorAction Stop | Out-Null
    }

    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = '选择安装位置。程序将安装到所选目录下的 SystemDriveCleanup 文件夹。'
    $folderDialog.SelectedPath = $defaultParent
    $folderDialog.ShowNewFolderButton = $true
    $dialogResult = $folderDialog.ShowDialog()
    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
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

    $shell = New-Object -ComObject WScript.Shell
    $powerShellPath = Join-Path $PSHOME 'powershell.exe'
    $arguments = '-NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "' + $appPath + '"'
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
        $shortcut.IconLocation = "$powerShellPath,0"
        $shortcut.Save()
    }

    $launchNow = [System.Windows.Forms.MessageBox]::Show(
        ("安装完成。`r`n`r`n程序位置：{0}`r`n已创建桌面和开始菜单快捷方式。`r`n`r`n现在启动程序吗？" -f $appPath),
        '安装完成',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    if ($launchNow -eq [System.Windows.Forms.DialogResult]::Yes) {
        Start-Process -FilePath $powerShellPath -ArgumentList $arguments -WorkingDirectory $installDirectory -ErrorAction Stop
    }
}
catch {
    Show-InstallError -Message $_.Exception.Message
    exit 1
}
