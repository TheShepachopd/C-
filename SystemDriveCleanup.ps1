Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if (-not ('DiskCleanupUi.GridRedraw' -as [type])) {
    $gridRedrawReferences = @(
        [System.Windows.Forms.Control].Assembly.Location,
        [System.Drawing.Bitmap].Assembly.Location
    )
    Add-Type -ReferencedAssemblies $gridRedrawReferences -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace DiskCleanupUi {
    public static class GridRedraw {
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        private static extern IntPtr SendMessage(IntPtr handle, int message, IntPtr wParam, IntPtr lParam);

        public static void SetEnabled(Control control, bool enabled) {
            SendMessage(control.Handle, 0x000B, new IntPtr(enabled ? 1 : 0), IntPtr.Zero);
            if (enabled) {
                control.Invalidate(true);
                control.Update();
            }
        }
    }
}
'@
}

[System.Windows.Forms.Application]::EnableVisualStyles()

$colors = @{
    Background = [System.Drawing.Color]::FromArgb(251, 248, 250)
    Ink = [System.Drawing.Color]::FromArgb(83, 68, 86)
    Muted = [System.Drawing.Color]::FromArgb(139, 123, 141)
    Accent = [System.Drawing.Color]::FromArgb(166, 119, 159)
    AccentHover = [System.Drawing.Color]::FromArgb(149, 101, 144)
    Border = [System.Drawing.Color]::FromArgb(239, 229, 237)
    White = [System.Drawing.Color]::FromArgb(255, 254, 255)
    Selection = [System.Drawing.Color]::FromArgb(249, 239, 247)
}
$font = New-Object System.Drawing.Font('Segoe UI', 9)
$smallFont = New-Object System.Drawing.Font('Segoe UI', 8)
$headingFont = New-Object System.Drawing.Font('Segoe UI Semibold', 19)
$labelFont = New-Object System.Drawing.Font('Segoe UI Semibold', 9)

$form = New-Object System.Windows.Forms.Form
$form.Text = 'C-Clean'
$form.Size = New-Object System.Drawing.Size(1160, 760)
$form.MinimumSize = New-Object System.Drawing.Size(1020, 660)
$form.StartPosition = 'CenterScreen'
$form.BackColor = $colors.Background
$form.Font = $font
$form.Opacity = 1
$form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
$form.ShowInTaskbar = $true
$iconPath = Join-Path $PSScriptRoot 'NTL.ico'
if (Test-Path -LiteralPath $iconPath -PathType Leaf) {
    $form.Icon = New-Object System.Drawing.Icon($iconPath)
}

$header = New-Object System.Windows.Forms.Panel
$header.Dock = 'Top'
$header.Height = 112
$header.BackColor = [System.Drawing.Color]::FromArgb(183, 151, 196)
$header.Add_Paint({
    $bounds = $header.ClientRectangle
    if ($bounds.Width -gt 0 -and $bounds.Height -gt 0) {
        $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
            $bounds,
            [System.Drawing.Color]::FromArgb(158, 137, 190),
            [System.Drawing.Color]::FromArgb(219, 164, 181),
            [System.Drawing.Drawing2D.LinearGradientMode]::Horizontal
        )
        $eventArgs.Graphics.FillRectangle($brush, $bounds)
        $brush.Dispose()
    }
})
$form.Controls.Add($header)

$title = New-Object System.Windows.Forms.Label
$title.Text = 'C-Clean'
$title.ForeColor = $colors.White
$title.Font = $headingFont
$title.Location = New-Object System.Drawing.Point(26, 17)
$title.Size = New-Object System.Drawing.Size(460, 38)
$header.Controls.Add($title)

$intro = New-Object System.Windows.Forms.Label
$intro.Text = '选择一个储存器，快速检查大文件与临时缓存候选。所有清理操作都会先征求确认。'
$intro.ForeColor = [System.Drawing.Color]::FromArgb(255, 246, 250)
$intro.Location = New-Object System.Drawing.Point(29, 63)
$intro.Size = New-Object System.Drawing.Size(900, 25)
$header.Controls.Add($intro)

$body = New-Object System.Windows.Forms.Panel
$body.Location = New-Object System.Drawing.Point(0, 112)
$body.Size = New-Object System.Drawing.Size($form.ClientSize.Width, ($form.ClientSize.Height - 112))
$body.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$body.BackColor = $colors.Background
$body.Padding = New-Object System.Windows.Forms.Padding(22, 18, 22, 18)
$form.Controls.Add($body)

$controlsCard = New-Object System.Windows.Forms.Panel
$controlsCard.Location = New-Object System.Drawing.Point(22, 18)
$controlsCard.Size = New-Object System.Drawing.Size(($body.ClientSize.Width - 44), 130)
$controlsCard.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$controlsCard.BackColor = $colors.White
$body.Controls.Add($controlsCard)

$driveLabel = New-Object System.Windows.Forms.Label
$driveLabel.Text = '储存器'
$driveLabel.Font = $labelFont
$driveLabel.ForeColor = $colors.Ink
$driveLabel.Location = New-Object System.Drawing.Point(20, 14)
$driveLabel.Size = New-Object System.Drawing.Size(250, 20)
$controlsCard.Controls.Add($driveLabel)

$drivePicker = New-Object System.Windows.Forms.ComboBox
$drivePicker.DropDownStyle = 'DropDownList'
$drivePicker.Location = New-Object System.Drawing.Point(20, 39)
$drivePicker.Size = New-Object System.Drawing.Size(300, 30)
$drivePicker.Font = $font
$drivePicker.DisplayMember = 'Display'
$drivePicker.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left
$controlsCard.Controls.Add($drivePicker)

$scanModeLabel = New-Object System.Windows.Forms.Label
$scanModeLabel.Text = '检查内容'
$scanModeLabel.Font = $labelFont
$scanModeLabel.ForeColor = $colors.Ink
$scanModeLabel.Location = New-Object System.Drawing.Point(344, 14)
$scanModeLabel.Size = New-Object System.Drawing.Size(250, 20)
$controlsCard.Controls.Add($scanModeLabel)

$scanModePicker = New-Object System.Windows.Forms.ComboBox
$scanModePicker.DropDownStyle = 'DropDownList'
$scanModePicker.Items.AddRange([object[]]@('大文件候选', '临时 / 缓存候选', '全部候选'))
$scanModePicker.SelectedIndex = 0
$scanModePicker.Location = New-Object System.Drawing.Point(344, 39)
$scanModePicker.Size = New-Object System.Drawing.Size(220, 30)
$scanModePicker.Font = $font
$controlsCard.Controls.Add($scanModePicker)
$scanModePicker.Add_SelectedIndexChanged({
    $thresholdInput.Enabled = $scanModePicker.SelectedIndex -ne 1
})

$thresholdLabel = New-Object System.Windows.Forms.Label
$thresholdLabel.Text = '大文件门槛（MB）'
$thresholdLabel.Font = $labelFont
$thresholdLabel.ForeColor = $colors.Ink
$thresholdLabel.Location = New-Object System.Drawing.Point(590, 14)
$thresholdLabel.Size = New-Object System.Drawing.Size(160, 20)
$controlsCard.Controls.Add($thresholdLabel)

$thresholdInput = New-Object System.Windows.Forms.NumericUpDown
$thresholdInput.Minimum = 1
$thresholdInput.Maximum = 1048576
$thresholdInput.Value = 100
$thresholdInput.Location = New-Object System.Drawing.Point(590, 39)
$thresholdInput.Size = New-Object System.Drawing.Size(135, 30)
$thresholdInput.Font = $font
$controlsCard.Controls.Add($thresholdInput)

$refreshButton = New-Object System.Windows.Forms.Button
$refreshButton.Text = '刷新'
$refreshButton.Location = New-Object System.Drawing.Point(750, 37)
$refreshButton.Size = New-Object System.Drawing.Size(76, 36)
$refreshButton.FlatStyle = 'Flat'
$refreshButton.FlatAppearance.BorderColor = $colors.Border
$refreshButton.BackColor = $colors.White
$refreshButton.ForeColor = $colors.Ink
$refreshButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$controlsCard.Controls.Add($refreshButton)

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = '开始扫描'
$scanButton.Location = New-Object System.Drawing.Point(838, 37)
$scanButton.Size = New-Object System.Drawing.Size(120, 36)
$scanButton.FlatStyle = 'Flat'
$scanButton.FlatAppearance.BorderSize = 0
$scanButton.BackColor = $colors.Accent
$scanButton.ForeColor = $colors.White
$scanButton.Font = $labelFont
$scanButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$scanButton.Add_MouseEnter({ $scanButton.BackColor = $colors.AccentHover })
$scanButton.Add_MouseLeave({ $scanButton.BackColor = $colors.Accent })
$scanButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$scanButton.Enabled = $false
$controlsCard.Controls.Add($scanButton)

$driveInfoLabel = New-Object System.Windows.Forms.Label
$driveInfoLabel.Text = '选择要检查的磁盘。'
$driveInfoLabel.Location = New-Object System.Drawing.Point(20, 87)
$driveInfoLabel.Size = New-Object System.Drawing.Size(650, 23)
$driveInfoLabel.ForeColor = $colors.Muted
$driveInfoLabel.Font = $smallFont
$driveInfoLabel.AutoEllipsis = $true
$controlsCard.Controls.Add($driveInfoLabel)

$deleteButton = New-Object System.Windows.Forms.Button
$deleteButton.Text = '移入回收站'
$deleteButton.Location = New-Object System.Drawing.Point(838, 81)
$deleteButton.Size = New-Object System.Drawing.Size(120, 34)
$deleteButton.FlatStyle = 'Flat'
$deleteButton.FlatAppearance.BorderColor = $colors.Border
$deleteButton.BackColor = $colors.White
$deleteButton.ForeColor = $colors.Ink
$deleteButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$deleteButton.Enabled = $false
$deleteButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$controlsCard.Controls.Add($deleteButton)

$resultsCard = New-Object System.Windows.Forms.Panel
$resultsCard.Location = New-Object System.Drawing.Point(22, 164)
$resultsCard.Size = New-Object System.Drawing.Size(
    ($body.ClientSize.Width - 44),
    [Math]::Max(300, ($body.ClientSize.Height - 201))
)
$resultsCard.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$resultsCard.BackColor = $colors.White
$body.Controls.Add($resultsCard)

$resultsTitle = New-Object System.Windows.Forms.Label
$resultsTitle.Text = '扫描结果'
$resultsTitle.Font = $labelFont
$resultsTitle.ForeColor = $colors.Ink
$resultsTitle.Location = New-Object System.Drawing.Point(18, 15)
$resultsTitle.Size = New-Object System.Drawing.Size(120, 22)
$resultsCard.Controls.Add($resultsTitle)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = '选择储存器后开始扫描。'
$statusLabel.Location = New-Object System.Drawing.Point(145, 16)
$statusLabel.Size = New-Object System.Drawing.Size(($resultsCard.Width - 320), 21)
$statusLabel.ForeColor = $colors.Muted
$statusLabel.AutoEllipsis = $true
$statusLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Left
$resultsCard.Controls.Add($statusLabel)

$selectAllButton = New-Object System.Windows.Forms.Button
$selectAllButton.Text = '全选结果'
$selectAllButton.Location = New-Object System.Drawing.Point(($resultsCard.Width - 150), 9)
$selectAllButton.Size = New-Object System.Drawing.Size(132, 30)
$selectAllButton.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Right
$selectAllButton.FlatStyle = 'Flat'
$selectAllButton.FlatAppearance.BorderColor = $colors.Border
$selectAllButton.BackColor = $colors.White
$selectAllButton.ForeColor = $colors.Ink
$selectAllButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$selectAllButton.Add_MouseEnter({ $selectAllButton.BackColor = $colors.Selection })
$selectAllButton.Add_MouseLeave({ $selectAllButton.BackColor = $colors.White })
$selectAllButton.Enabled = $false
$resultsCard.Controls.Add($selectAllButton)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(18, 43)
$progressBar.Size = New-Object System.Drawing.Size(($resultsCard.Width - 40), 5)
$progressBar.Style = 'Blocks'
$progressBar.Visible = $false
$progressBar.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$resultsCard.Controls.Add($progressBar)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.Location = New-Object System.Drawing.Point(18, 59)
$grid.Size = New-Object System.Drawing.Size(($resultsCard.Width - 40), ($resultsCard.Height - 154))
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
$grid.BackgroundColor = $colors.White
$grid.BorderStyle = 'None'
$grid.CellBorderStyle = 'SingleHorizontal'
$grid.GridColor = $colors.Border
$grid.EnableHeadersVisualStyles = $false
$grid.ColumnHeadersDefaultCellStyle.BackColor = [System.Drawing.Color]::FromArgb(247, 249, 252)
$grid.ColumnHeadersDefaultCellStyle.ForeColor = $colors.Muted
$grid.ColumnHeadersDefaultCellStyle.Font = $smallFont
$grid.ColumnHeadersHeight = 36
$grid.DefaultCellStyle.BackColor = $colors.White
$grid.DefaultCellStyle.ForeColor = $colors.Ink
$grid.DefaultCellStyle.SelectionBackColor = $colors.Selection
$grid.DefaultCellStyle.SelectionForeColor = $colors.Ink
$grid.DefaultCellStyle.Padding = New-Object System.Windows.Forms.Padding(5, 0, 5, 0)
$grid.RowTemplate.Height = 31

$checkColumn = New-Object System.Windows.Forms.DataGridViewCheckBoxColumn
$checkColumn.Name = 'Selected'
$checkColumn.HeaderText = '清理'
$checkColumn.Width = 52
$checkColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($checkColumn)

$pathColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$pathColumn.Name = 'Path'
$pathColumn.HeaderText = '文件位置'
$pathColumn.Width = 520
$pathColumn.ReadOnly = $true
$pathColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($pathColumn)

$typeColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$typeColumn.Name = 'Type'
$typeColumn.HeaderText = '候选类型'
$typeColumn.Width = 155
$typeColumn.ReadOnly = $true
$typeColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($typeColumn)

$sizeColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$sizeColumn.Name = 'Size'
$sizeColumn.HeaderText = '大小'
$sizeColumn.Width = 105
$sizeColumn.ReadOnly = $true
$sizeColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($sizeColumn)

$modifiedColumn = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$modifiedColumn.Name = 'Modified'
$modifiedColumn.HeaderText = '最后修改'
$modifiedColumn.AutoSizeMode = 'Fill'
$modifiedColumn.ReadOnly = $true
$modifiedColumn.SortMode = 'NotSortable'
[void]$grid.Columns.Add($modifiedColumn)

$resultsCard.Controls.Add($grid)

function Update-SelectAllButton {
    if ($grid.Rows.Count -eq 0) {
        $selectAllButton.Enabled = $false
        $selectAllButton.Text = '全选结果'
        return
    }

    $allSelected = $true
    foreach ($row in $grid.Rows) {
        if ($row.Cells['Selected'].Value -ne $true) {
            $allSelected = $false
            break
        }
    }
    $selectAllButton.Enabled = $true
    if ($allSelected) {
        $selectAllButton.Text = '取消全选'
    } else {
        $selectAllButton.Text = '全选结果'
    }
}

$selectionState = @{ IsBulkUpdating = $false }

$grid.Add_CurrentCellDirtyStateChanged({
    if ($grid.IsCurrentCellDirty -and
        $grid.CurrentCell -and
        $grid.CurrentCell.OwningColumn.Name -eq 'Selected') {
        $grid.CommitEdit([System.Windows.Forms.DataGridViewDataErrorContexts]::Commit)
    }
})
$grid.Add_CellValueChanged({
    param($sender, $eventArgs)
    if (-not $selectionState.IsBulkUpdating -and
        $eventArgs.RowIndex -ge 0 -and
        $sender.Columns[$eventArgs.ColumnIndex].Name -eq 'Selected') {
        Update-SelectAllButton
    }
})
$selectAllButton.Add_Click({
    $grid.EndEdit()
    $selectAll = $selectAllButton.Text -ne '取消全选'
    $selectionState.IsBulkUpdating = $true
    $grid.SuspendLayout()
    [DiskCleanupUi.GridRedraw]::SetEnabled($grid, $false)
    try {
        foreach ($row in $grid.Rows) {
            $row.Cells['Selected'].Value = $selectAll
        }
    }
    finally {
        $grid.ResumeLayout($false)
        [DiskCleanupUi.GridRedraw]::SetEnabled($grid, $true)
        $selectionState.IsBulkUpdating = $false
    }
    Update-SelectAllButton
})

$footnote = New-Object System.Windows.Forms.Label
$footnote.Text = '提示：候选文件不一定都是垃圾；清理前请核对路径。移入回收站后仍可恢复。'
$footnote.ForeColor = $colors.Muted
$footnote.Font = $smallFont
$footnote.Location = New-Object System.Drawing.Point(18, ($resultsCard.Height - 89))
$footnote.Size = New-Object System.Drawing.Size(($resultsCard.Width - 40), 18)
$footnote.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$resultsCard.Controls.Add($footnote)

$feedbackLabel = New-Object System.Windows.Forms.Label
$feedbackLabel.Text = '如有问题，请向zero1977.cc@foxmail.com反馈'
$feedbackLabel.ForeColor = $colors.Muted
$feedbackLabel.Font = $smallFont
$feedbackLabel.Location = New-Object System.Drawing.Point(18, ($resultsCard.Height - 63))
$feedbackLabel.Size = New-Object System.Drawing.Size(($resultsCard.Width - 40), 18)
$feedbackLabel.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$resultsCard.Controls.Add($feedbackLabel)

$downloadLink = New-Object System.Windows.Forms.LinkLabel
$downloadLink.Text = '官方下载：https://github.com/TheShepachopd/C-'
$downloadLink.LinkColor = $colors.Accent
$downloadLink.ActiveLinkColor = $colors.AccentHover
$downloadLink.VisitedLinkColor = $colors.Muted
$downloadLink.Font = $smallFont
$downloadLink.Location = New-Object System.Drawing.Point(18, ($resultsCard.Height - 37))
$downloadLink.Size = New-Object System.Drawing.Size(($resultsCard.Width - 40), 18)
$downloadLink.Anchor = [System.Windows.Forms.AnchorStyles]::Bottom -bor
    [System.Windows.Forms.AnchorStyles]::Left -bor
    [System.Windows.Forms.AnchorStyles]::Right
$downloadLink.Add_LinkClicked({
    try {
        Start-Process -FilePath 'https://github.com/TheShepachopd/C-' -ErrorAction Stop
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            $form,
            ('无法打开官方下载网址：{0}' -f $_.Exception.Message),
            '无法打开链接',
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
    }
})
$resultsCard.Controls.Add($downloadLink)

$form.Add_Shown({
    $form.ShowInTaskbar = $true
    $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
    $form.Opacity = 1
    $form.Visible = $true
    $form.TopMost = $true
    $form.Activate()
    $form.BringToFront()
    $form.TopMost = $false
    $driveLoadTimer.Start()
})

$driveLoadTimer = New-Object System.Windows.Forms.Timer
$driveLoadTimer.Interval = 250
$driveLoadTimer.Add_Tick({
    $driveLoadTimer.Stop()
    Update-DriveChoices
})

function Update-DriveChoices {
    $previousRoot = $null
    $driveErrors = New-Object 'System.Collections.Generic.List[string]'
    if ($drivePicker.SelectedItem) {
        $previousRoot = $drivePicker.SelectedItem.Root
    }

    $drivePicker.Items.Clear()
    foreach ($drive in [System.IO.DriveInfo]::GetDrives()) {
        try {
            if (-not $drive.IsReady) {
                continue
            }

            $label = $drive.VolumeLabel
            if ([string]::IsNullOrWhiteSpace($label)) {
                $label = '本地磁盘'
            }
            $display = '{0}  {1}  ·  {2:N1} GB 可用 / {3:N1} GB' -f
                $drive.Name.TrimEnd('\'), $label, ($drive.AvailableFreeSpace / 1GB), ($drive.TotalSize / 1GB)
            $drivePicker.Items.Add([pscustomobject]@{
                Root = $drive.RootDirectory.FullName
                Display = $display
            }) | Out-Null
        }
        catch {
            $driveErrors.Add(('{0}: {1}' -f $drive.Name, $_.Exception.Message))
        }
    }

    if ($drivePicker.Items.Count -eq 0) {
        if ($driveErrors.Count -gt 0) {
            $driveInfoLabel.Text = '读取储存器列表失败：{0}' -f $driveErrors[0]
        } else {
            $driveInfoLabel.Text = '没有检测到可读取的储存器。请连接磁盘后刷新。'
        }
        $scanButton.Enabled = $false
        return
    }

    if ($driveErrors.Count -gt 0) {
        $driveInfoLabel.Text = '部分储存器无法读取（{0} 个），列表已显示可用储存器。' -f $driveErrors.Count
    }

    $selectedIndex = -1
    for ($index = 0; $index -lt $drivePicker.Items.Count; $index++) {
        if ($drivePicker.Items[$index].Root -eq $previousRoot) {
            $selectedIndex = $index
            break
        }
        if ($drivePicker.Items[$index].Root.TrimEnd('\') -eq
            [System.IO.Path]::GetPathRoot($env:SystemDrive + '\').TrimEnd('\')) {
            $selectedIndex = $index
        }
    }
    if ($selectedIndex -lt 0) {
        $selectedIndex = 0
    }
    $drivePicker.SelectedIndex = $selectedIndex
    $scanButton.Enabled = $true
}

$drivePicker.Add_SelectedIndexChanged({
    if ($drivePicker.SelectedItem) {
        $driveInfoLabel.Text = '扫描范围：{0}' -f $drivePicker.SelectedItem.Root
    }
})
$refreshButton.Add_Click({ Update-DriveChoices })

$scanInProgress = $false

$scanButton.Add_Click({
    if ($scanInProgress -or -not $drivePicker.SelectedItem) {
        return
    }

    $grid.Rows.Clear()
    Update-SelectAllButton
    $deleteButton.Enabled = $false
    $scanButton.Enabled = $false
    $refreshButton.Enabled = $false
    $drivePicker.Enabled = $false
    $scanModePicker.Enabled = $false
    $thresholdInput.Enabled = $false
    $progressBar.Style = 'Marquee'
    $progressBar.MarqueeAnimationSpeed = 24
    $progressBar.Visible = $true
    $statusLabel.Text = '准备扫描 {0}……' -f $drivePicker.SelectedItem.Root
    $scanInProgress = $true

    $root = $drivePicker.SelectedItem.Root
    $minimumBytes = [int64]$thresholdInput.Value * 1MB
    $scanMode = $scanModePicker.SelectedIndex
    $excludedRootNames = @(
        'Windows', 'Program Files', 'Program Files (x86)', 'ProgramData',
        '$Recycle.Bin', 'System Volume Information', 'Recovery',
        '$WinREAgent', 'Config.Msi', 'MSOCache'
    )
    $temporaryExtensions = @('.tmp', '.temp', '.cache')
    $temporaryDirectoryNames = @('Temp', 'Tmp', 'Cache', 'Caches', 'Code Cache', 'GPUCache', 'CrashDumps')
    $excludedSystemFiles = @('pagefile.sys', 'hiberfil.sys', 'swapfile.sys')
    $results = New-Object 'System.Collections.Generic.List[object]'
    $errors = New-Object 'System.Collections.Generic.List[string]'
    $stack = New-Object 'System.Collections.Generic.Stack[string]'
    $stack.Push($root)
    $errorCount = 0
    $processedEntries = 0

    try {
        if (-not (Test-Path -LiteralPath $root -PathType Container)) {
            throw ('所选储存器已不可用：{0}。请刷新储存器列表后重试。' -f $root)
        }

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
                                (($attributes -band [System.IO.FileAttributes]::Hidden) -eq 0 -or $scanMode -ne 0)) {
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
                        $isLargeCandidate = $file.Length -ge $minimumBytes
                        $isTemporaryCandidate = $temporaryExtensions -contains $file.Extension
                        if (-not $isTemporaryCandidate) {
                            $segments = $file.DirectoryName.Split([char]'\')
                            foreach ($segment in $segments) {
                                if ($temporaryDirectoryNames -contains $segment) {
                                    $isTemporaryCandidate = $true
                                    break
                                }
                            }
                        }

                        $includeFile = switch ($scanMode) {
                            0 { $isLargeCandidate }
                            1 { $isTemporaryCandidate }
                            default { $isLargeCandidate -or $isTemporaryCandidate }
                        }
                        if ($includeFile) {
                            $results.Add([pscustomobject]@{
                                Path = $file.FullName
                                Length = $file.Length
                                Modified = $file.LastWriteTime
                                Type = if ($isLargeCandidate -and $isTemporaryCandidate) {
                                    '大文件 · 临时 / 缓存'
                                } elseif ($isTemporaryCandidate) {
                                    '临时 / 缓存'
                                } else {
                                    '大文件'
                                }
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
        $refreshButton.Enabled = $true
        $drivePicker.Enabled = $true
        $scanModePicker.Enabled = $true
        $thresholdInput.Enabled = $scanModePicker.SelectedIndex -ne 1
        $progressBar.Visible = $false
        $progressBar.Style = 'Blocks'
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
        $rowIndex = $grid.Rows.Add($false, $file.Path, $file.Type, $sizeText, $file.Modified.ToString('yyyy-MM-dd HH:mm'))
        $grid.Rows[$rowIndex].Tag = $file.Path
    }

    $scanButton.Enabled = $true
    $refreshButton.Enabled = $true
    $drivePicker.Enabled = $true
    $scanModePicker.Enabled = $true
    $thresholdInput.Enabled = $scanModePicker.SelectedIndex -ne 1
    $progressBar.Visible = $false
    $progressBar.Style = 'Blocks'
    $scanInProgress = $false
    $deleteButton.Enabled = $grid.Rows.Count -gt 0
    Update-SelectAllButton
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
    Update-SelectAllButton
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
