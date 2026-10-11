Option Explicit

Dim shell, fileSystem, packageDirectory, powerShell, installer, command, exitCode
Set shell = CreateObject("WScript.Shell")
Set fileSystem = CreateObject("Scripting.FileSystemObject")

packageDirectory = fileSystem.GetParentFolderName(WScript.ScriptFullName)
powerShell = shell.ExpandEnvironmentStrings("%SystemRoot%") & "\System32\WindowsPowerShell\v1.0\powershell.exe"
installer = fileSystem.BuildPath(packageDirectory, "Install.ps1")
command = """" & powerShell & """ -NoLogo -NoProfile -STA -WindowStyle Hidden -ExecutionPolicy Bypass -File """ & installer & """"

exitCode = shell.Run(command, 0, True)
If exitCode <> 0 Then
    MsgBox "安装程序未能正常完成（错误代码 " & exitCode & "）。请重新下载完整安装包后重试。", vbExclamation, "系统盘清理工具"
End If
