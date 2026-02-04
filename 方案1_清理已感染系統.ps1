# ============================================
# 捷徑病毒清理腳本 - 方案1：清理已感染系統
# ============================================
# 說明：如果已經點擊了 USB 上的 TRANSCEND.lnk
#       此腳本將清理系統中的病毒檔案
# 
# 使用方式：以管理員身份執行此腳本
# ============================================

Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  捷徑病毒清理工具 v1.0" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# 檢查管理員權限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "[錯誤] 此腳本需要管理員權限！" -ForegroundColor Red
    Write-Host "請以滑鼠右鍵點擊此檔案，選擇「以系統管理員身分執行」" -ForegroundColor Yellow
    pause
    exit 1
}

Write-Host "[1/5] 檢查 Windows Defender 排除清單..." -ForegroundColor Yellow

# 移除病毒加入的排除路徑
$exclusions = @("C:\Windows\System32", "E:\sysvolume", "F:\sysvolume", "G:\sysvolume", "H:\sysvolume")
foreach ($path in $exclusions) {
    try {
        $currentExclusions = (Get-MpPreference).ExclusionPath
        if ($currentExclusions -contains $path) {
            Remove-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
            Write-Host "   已移除排除路徑: $path" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ! 無法移除排除路徑: $path" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "[2/5] 搜尋系統中的病毒檔案..." -ForegroundColor Yellow

# 搜尋病毒 DLL 檔案 (格式: u數字.dll)
$virusFiles = Get-ChildItem -Path "C:\Windows\System32\" -Filter "u*.dll" -ErrorAction SilentlyContinue | Where-Object {
    $_.Name -match "^u\d+\.dll$"
}

if ($virusFiles) {
    Write-Host "  發現可疑檔案:" -ForegroundColor Red
    foreach ($file in $virusFiles) {
        Write-Host "    - $($file.FullName)" -ForegroundColor Red
        Write-Host "      建立時間: $($file.CreationTime)" -ForegroundColor Gray
        Write-Host "      大小: $([math]::Round($file.Length/1KB, 2)) KB" -ForegroundColor Gray
    }
} else {
    Write-Host "   未發現可疑的病毒檔案" -ForegroundColor Green
}

Write-Host ""
Write-Host "[3/5] 檢查執行中的病毒程序..." -ForegroundColor Yellow

# 檢查是否有 rundll32.exe 在執行病毒 DLL
$suspiciousProcesses = Get-Process -Name "rundll32" -ErrorAction SilentlyContinue | Where-Object {
    $_.CommandLine -like "*u*.dll*"
}

if ($suspiciousProcesses) {
    Write-Host "  發現可疑程序，正在終止..." -ForegroundColor Red
    foreach ($proc in $suspiciousProcesses) {
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        Write-Host "   已終止 PID: $($proc.Id)" -ForegroundColor Green
    }
} else {
    Write-Host "   未發現可疑程序" -ForegroundColor Green
}

Write-Host ""
Write-Host "[4/5] 刪除病毒檔案..." -ForegroundColor Yellow

if ($virusFiles) {
    foreach ($file in $virusFiles) {
        try {
            # 取消唯讀屬性
            $file.Attributes = "Normal"
            Remove-Item -Path $file.FullName -Force -ErrorAction Stop
            Write-Host "   已刪除: $($file.Name)" -ForegroundColor Green
        } catch {
            Write-Host "   無法刪除: $($file.Name)" -ForegroundColor Red
            Write-Host "    錯誤: $($_.Exception.Message)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "   無需刪除檔案" -ForegroundColor Green
}

Write-Host ""
Write-Host "[5/5] 執行 Windows Defender 掃描..." -ForegroundColor Yellow

# 啟動快速掃描
try {
    Start-MpScan -ScanType QuickScan
    Write-Host "   Windows Defender 掃描已啟動" -ForegroundColor Green
    Write-Host "    請稍後檢查掃描結果" -ForegroundColor Gray
} catch {
    Write-Host "  ! 無法啟動 Windows Defender 掃描" -ForegroundColor Yellow
    Write-Host "    請手動開啟 Windows 安全性執行掃描" -ForegroundColor Gray
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  清理完成！" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "後續步驟：" -ForegroundColor Yellow
Write-Host "  1. 重新啟動電腦" -ForegroundColor White
Write-Host "  2. 檢查 Windows Defender 掃描結果" -ForegroundColor White
Write-Host "  3. 使用「方案2」清理 USB 隨身碟" -ForegroundColor White
Write-Host ""

pause
