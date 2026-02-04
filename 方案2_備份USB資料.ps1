# ============================================
# USB 資料備份腳本
# ============================================

# 設定 USB 磁碟機代號（請根據實際情況修改）
$USBDrive = "E:"

# 設定備份目標資料夾
$BackupPath = "D:\USB_備份_$(Get-Date -Format 'yyyyMMdd_HHmmss')"

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  USB 資料備份工具" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "USB 磁碟機: $USBDrive" -ForegroundColor Yellow
Write-Host "備份位置: $BackupPath" -ForegroundColor Yellow
Write-Host ""

# 檢查 USB 是否存在
if (-not (Test-Path $USBDrive)) {
    Write-Host "[錯誤] 找不到 USB 磁碟機 $USBDrive" -ForegroundColor Red
    Write-Host "請確認 USB 已正確連接，並修改腳本中的磁碟機代號" -ForegroundColor Yellow
    pause
    exit 1
}

# 建立備份資料夾
New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null

# 顯示 USB 中的真實資料夾
Write-Host "[1/3] 顯示隱藏的資料夾..." -ForegroundColor Yellow
$transcendFolder = Join-Path $USBDrive "TRANSCEND"
if (Test-Path $transcendFolder) {
    attrib -h -s "$transcendFolder" /s /d
    Write-Host "   已顯示 TRANSCEND 資料夾" -ForegroundColor Green
} else {
    Write-Host "  ! 找不到 TRANSCEND 資料夾" -ForegroundColor Red
}

# 列出所有資料夾（排除病毒資料夾）
Write-Host ""
Write-Host "[2/3] 掃描可備份的資料..." -ForegroundColor Yellow
$folders = Get-ChildItem -Path $USBDrive -Directory -Force | Where-Object {
    $_.Name -notin @("sysvolume", "System Volume Information", "`$RECYCLE.BIN")
}

if ($folders) {
    Write-Host "  發現以下資料夾：" -ForegroundColor Green
    foreach ($folder in $folders) {
        $size = (Get-ChildItem -Path $folder.FullName -Recurse -File -ErrorAction SilentlyContinue | 
                 Measure-Object -Property Length -Sum).Sum
        $sizeInMB = [math]::Round($size / 1MB, 2)
        Write-Host "    - $($folder.Name) ($sizeInMB MB)" -ForegroundColor Cyan
    }
    
    Write-Host ""
    Write-Host "[3/3] 開始備份..." -ForegroundColor Yellow
    
    foreach ($folder in $folders) {
        $destPath = Join-Path $BackupPath $folder.Name
        Write-Host "  正在備份: $($folder.Name)..." -ForegroundColor Gray
        
        try {
            Copy-Item -Path $folder.FullName -Destination $destPath -Recurse -Force
            Write-Host "   已備份: $($folder.Name)" -ForegroundColor Green
        } catch {
            Write-Host "   備份失敗: $($folder.Name)" -ForegroundColor Red
            Write-Host "    錯誤: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
    
    # 備份根目錄的檔案（排除病毒檔案）
    $rootFiles = Get-ChildItem -Path $USBDrive -File -Force | Where-Object {
        $_.Extension -notin @(".lnk", ".vbs", ".bat", ".bin", ".dat") -or
        $_.Name -notmatch "^u\d+"
    }
    
    if ($rootFiles) {
        Write-Host "  正在備份根目錄檔案..." -ForegroundColor Gray
        foreach ($file in $rootFiles) {
            try {
                Copy-Item -Path $file.FullName -Destination $BackupPath -Force
                Write-Host "   已備份: $($file.Name)" -ForegroundColor Green
            } catch {
                Write-Host "   備份失敗: $($file.Name)" -ForegroundColor Red
            }
        }
    }
    
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  備份完成！" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "備份位置: $BackupPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "請檢查備份檔案是否完整，確認無誤後即可格式化 USB" -ForegroundColor White
    
    # 開啟備份資料夾
    explorer $BackupPath
    
} else {
    Write-Host "  ! 未發現可備份的資料夾" -ForegroundColor Yellow
}

Write-Host ""
pause
