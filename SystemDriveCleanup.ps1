Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = '系统盘大文件检查与清理'
$form.Size = New-Object System.Drawing.Size(1050, 650)
$form.MinimumSize = New-Object System.Drawing.Size(850, 500)
$form.StartPosition = 'CenterScreen'

$intro = New-Object System.Windows.Forms.Label
$intro.Text = '扫描系统盘中的大文件候选。大文件不一定是垃圾，请核对路径和用途后再勾选清理。'
$intro.Location = New-Object System.Drawing.Point(16, 14)
$intro.Size = New-Object System.Drawing.Size(990, 24)
$form.Controls.Add($intro)

$thresholdLabel = New-Object System.Windows.Forms.Label
$thresholdLabel.Text = '最小文件大小（MB）：'
$thresholdLabel.Location = New-Object System.Drawing.Point(16, 50)
$thresholdLabel.Size = New-Object System.Drawing.Size(135, 24)
$form.Controls.Add($thresholdLabel)

$thresholdInput = New-Object System.Windows.Forms.NumericUpDown
$thresholdInput.Minimum = 1
$thresholdInput.Maximum = 1048576
$thresholdInput.Value = 100
$thresholdInput.Location = New-Object System.Drawing.Point(155, 48)
$thresholdInput.Size = New-Object System.Drawing.Size(100, 24)
$form.Controls.Add($thresholdInput)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = '扫描系统盘'
$scanButton.Location = New-Object System.Drawing.Point(270, 46)
$scanButton.Size = New-Object System.Drawing.Size(110, 30)
$form.Controls.Add($scanButton)

$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Text = '删除勾选项'
$deleteButton.Location = New-Object System.Drawing.Point(390, 46)
$deleteButton.Size = New-Object System.Drawing.Size(110, 30)
$deleteButton.Enabled = $false
$form.Controls.Add($deleteButton)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = '尚未扫描。'
$statusLabel.Location = New-Object System.Drawing.Point(515, 50)
$statusLabel.Size = New-Object System.Drawing.Size(490, 24)
$form.Controls.Add($statusLabel)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(16, 90)
$grid.Size = New-Object System.Drawing.Size(1000, 480)
$grid.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.AllowUserToResizeRows = $false
$grid.AutoGenerateColumns = $false
$grid.RowHeadersVisible = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.MultiSelect = $false
$grid.BackgroundColor = [System.Drawing.SystemColors]::Window

$checkColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$checkColumn.Name = 'Selected'
$checkColumn.HeaderText = '清理'
$checkColumn.Width = 48
$checkColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($checkColumn)

$pathColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$pathColumn.Name = 'Path'
$pathColumn.HeaderText = '文件路径'
$pathColumn.Width = 600
$pathColumn.ReadOnly = $true
$pathColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($pathColumn)

$sizeColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$sizeColumn.Name = 'Size'
$sizeColumn.HeaderText = '大小'
$sizeColumn.Width = 110
$sizeColumn.ReadOnly = $true
$sizeColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($sizeColumn)

$modifiedColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$modifiedColumn.Name = 'Modified'
$modifiedColumn.HeaderText = '最后修改时间'
$modifiedColumn.AutoSizeMode = 'Fill'
$modifiedColumn.ReadOnly = $true
$modifiedColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($modifiedColumn)

$form.Controls.Add($grid)

$scanInProgress = $false

$scanButton.Add_Click({
    if ($scanInProgress) {
        return
    }

    $grid.Rows.Clear()
    $deleteButton.Enabled = $false
    $scanButton.Enabled = $false
    $thresholdInput.Enabled = $false
    $statusLabel.Text = '正在扫描，请稍候……'
    $scanInProgress = $true

    $root = [System.IO.Path]::GetPathRoot($env:SystemDrive + '\')
    $minimumBytes = [int64]$thresholdInput.Value * 1MB
    $excludedRootNames = @(
        'Windows', 'Program Files', 'Program Files (x86)', 'ProgramData',
        '$Recycle.Bin', 'System Volume Information', 'Recovery',
        '$WinREAgent', 'Config.Msi', 'MSOCache'
    )
    $excludedSystemFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys')
    $results = New-Object 'System.Collections.Generic.List[object]'
    $errors = New-Object 'System.Collections.Generic.List[string]'
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($root)
    $errorCount = 0
    $processedEntries = 0

    try {
        while ($stack.Count -gt 0) {
            $directoryPath = $stack.Pop()
            try {
                $directory = New-Object System.IO.DirectoryInfo($directoryPath)
                foreach ($entry in $directory.EnumerateFileSystemInfos()) {
                    $processedEntries++
                    if (($processedEntries % 256) -eq 0) {
                        $statusLabel.Text = '正在扫描：已检查 {0:N0} 个文件和目录……' -f $processedEntries
                        [System.Windows.Forms.Application]::DoEvents()
                    }

                    try {
                        $attributes = $entry.Attributes
                        if (($attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                            continue
                        }

                        if (($attributes -band [System.IO.FileAttributes]::Directory) -ne 0) {
                            if ($directoryPath.TrimEnd('\') -eq $root.TrimEnd('\') -and
                                $excludedRootNames -contains $entry.Name) {
                                continue
                            }
                            if (($attributes -band [System.IO.FileAttributes]::System) -eq 0 -and
                                ($attributes -band [System.IO.FileAttributes]::Hidden) -eq 0) {
                                $stack.Push($entry.FullName)
                            }
                            continue
                        }

                        if (($attributes -band [System.IO.FileAttributes]::System) -ne 0 -or
                            ($attributes -band [System.IO.FileAttributes]::Hidden) -ne 0 -or
                            $excludedSystemFiles -contains $entry.Name) {
                            continue
                        }

                        $file = [System.IO.FileInfo]$entry
                        if ($file.Length -ge $minimumBytes) {
                            $results.Add([pscustomobject]@{
                                Path = $file.FullName
                                Length = $file.Length
                                Modified = $file.LastWriteTime
                            })
                        }
                    }
                    catch {
                        $errorCount++
                        if ($errors.Count -lt 5) {
                            $errors.Add(('{0}: {1}' -f $entry.FullName, $_.Exception.Message))
                        }
                    }
                }
            }
            catch {
                $errorCount++
                if ($errors.Count -lt 5) {
                    $errors.Add(('{0}: {1}' -f $directoryPath, $_.Exception.Message))
                }
            }
        }
    }
    catch {
        $scanButton.Enabled = $true
        $thresholdInput.Enabled = $true
        $scanInProgress = $false
        $statusLabel.Text = '扫描失败。'
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            $_.Exception.Message,
            '扫描失败',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return
    }

    $files = @($results | Sort-Object Length -Descending)
    foreach ($file in $files) {
        $sizeText = '{0:N1} MB' -f ($file.Length / 1MB)
        $rowIndex = $grid.Rows.Add($false, $file.Path, $sizeText, $file.Modified.ToString('yyyy-MM-dd HH:mm'))
        $grid.Rows[$rowIndex].Tag = $file.Path
    }

    $scanButton.Enabled = $true
    $thresholdInput.Enabled = $true
    $scanInProgress = $false
    $deleteButton.Enabled = $grid.Rows.Count -gt 0
    $summary = '找到 {0} 个候选文件。' -f $grid.Rows.Count
    if ($errorCount -gt 0) {
        $summary += ' 有 {0} 处无法读取。' -f $errorCount
        if ($errors.Count -gt 0) {
            $details = [string]::Join([Environment]::NewLine, $errors)
            [System.Windows.Forms.MessageBox]::Show(
                $form,
                ("部分位置无法读取（共 {0} 处）：{1}{2}{3}" -f
                    $errorCount, [Environment]::NewLine, $details,
                    $(if ($errorCount -gt $errors.Count) {
                        [Environment]::NewLine + '其余位置未逐条显示。'
                    } else { '' })),
                '扫描完成（有未读取位置）',
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }
    $statusLabel.Text = $summary
})

$deleteButton.Add_Click({
    $grid.EndEdit()
    $selectedPaths = New-Object 'System.Collections.Generic.List[string]'
    foreach ($row in $grid.Rows) {
        if ($row.Cells['Selected'].Value -eq $true) {
            $selectedPaths.Add([string]$row.Tag)
        }
    }

    if ($selectedPaths.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            '请先勾选要清理的文件。',
            '未选择文件',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
        return
    }

    $answer = [System.Windows.Forms.MessageBox]::Show(
        $form,
        ("确定将勾选的 {0} 个文件移入回收站吗？`r`n`r`n请确认这些文件不再需要。此操作不会永久删除文件。" -f $selectedPaths.Count),
        '确认清理',
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) {
        return
    }

    $deletedCount = 0
    $failures = New-Object 'System.Collections.Generic.List[string]'
    foreach ($path in $selectedPaths) {
        try {
            if (-not [System.IO.File]::Exists($path)) {
                throw '文件已不存在。'
            }
            [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile(
                $path,
                [Microsoft.VisualBasic.FileIO.UIOption]::OnlyErrorDialogs,
                [Microsoft.VisualBasic.FileIO.RecycleOption]::SendToRecycleBin
            )
            $deletedCount++
        }
        catch {
            $failures.Add(('{0}: {1}' -f $path, $_.Exception.Message))
        }
    }

    for ($index = $grid.Rows.Count - 1; $index -ge 0; $index--) {
        $row = $grid.Rows[$index]
        if ($row.Tag -and -not [System.IO.File]::Exists([string]$row.Tag)) {
            $grid.Rows.RemoveAt($index)
        }
    }

    $deleteButton.Enabled = $grid.Rows.Count -gt 0
    $statusLabel.Text = '已移入回收站 {0} 个文件；失败 {1} 个。' -f $deletedCount, $failures.Count
    if ($failures.Count -gt 0) {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            ("{0} 个文件未能移入回收站：`r`n`r`n{1}" -f
                $failures.Count, [string]::Join([Environment]::NewLine, $failures)),
            '部分清理失败',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
}
)

[void]$form.ShowDialog()
