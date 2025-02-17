#RF HavenM 安装脚本
#感谢: BartJolling/ps-steam-cmd

#退出脚本递归，但必须在各ps脚本手动定义
function Exit-IScript {
  Read-Host "Now you can close this window";
  Exit;
  Exit-IScript;
}

#初始化依赖lib
$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
try { iex($w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1')); }
catch { 
    iex($w.DownloadString('http://ghproxy.net/https://raw.githubusercontent.com/ravenfieldcommunity/ravenfieldcommunity.github.io/main/static/corelib-utf8.ps1')); 
	if ($? -eq $true)
	{
		Write-Warning "Cannot init corelib";
		Exit-IScript;
	}
}

#创建session
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
$session.Cookies.Add((New-Object System.Net.Cookie("user_session", "000-", "/", "github.com")))

function Apply-HavenM {
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.github.com/repos/RavenfieldCommunity/HavenM/releases/latest" `
        -WebSession $session `
        -Headers @{
          "Accept"="application/json, text/plain, */*"
          "Accept-Encoding"="gzip, deflate, br, zstd"
        } `
        -ContentType "application/json;charset=utf-8"
  if ($? -eq $true)
  {
    $json_ = $request_.Content | ConvertFrom-Json
	Write-Host "Latest update's publish date: $($json_.assets[0].updated_at)"
	Write-Host "Update Note: 
$($json_.body)
	"
  }
  #下载
  $havenMDownloadPath = "$global:downloadPath\HavenM.zip"
  Write-Host "Downloading HavenM ..." 
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/RavenfieldCommunity/HavenM/releases/latest/download/Assembly-CSharp.dll" `
    -WebSession $session `
    -OutFile $havenMDownloadPath `
    -Headers @{
    "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    "accept-encoding"="gzip, deflate, br, zstd"
   }
    if ($? -eq $true)  #无报错就apply
    {
      if ( $(tasklist | findstr "ravenfield") -ne $null ) { 
        Write-Host "Waiting for game, close the game plz! (20s)..."
        Wait-Process -Name "ravenfield" -Timeout 20
      }	
	  Write-Host "Installing HavenM..."
      Copy-Item -Path $havenMDownloadPath -Destination "$global:gamePath\ravenfield_Data\Managed\Assembly-CSharp.dll" -Force
      if ($? -ne $true) {
        Write-Warning "Install HavenM failed" 
      } else  { Write-Host "HavenM installed" }
    }
    else #错误处理
    {
      Write-Warning "Download HavenM failed"        
    }
}

function Apply-Updater {
  Write-Host "Creating shortcut for updater in Desktop ..."        
  $shortcutPath = [System.Environment]::GetFolderPath('Desktop') + "`\HavenM Updater.lnk"
  $target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
  $shell = New-Object -ComObject WScript.Shell 
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $target
  $shortcut.Arguments = " -nop -c `"$w=(New-Object System.Net.WebClient);$w.Encoding=[System.Text.Encoding]::UTF8;iex($w.DownloadString('http://ravenfieldcommunity.github.io/static/get_havenm-utf8.ps1'));Read-Host;`""
  $shortcut.WorkingDirectory = [System.Environment]::GetFolderPath('Desktop')
  $shortcut.Save()
  if ($? -eq $false)
  {
    Write-Warning "Create shortcut in Desktop fail, plz check your Windows Denfender's log and allow this action (if there is already a shortcut in Desktop, INGORE this warning)"
	Write-Warning "You can copy the command in website and right click desktop to create shortcut by yourself"
	Write-Host "Creating shortcut for website in Desktop ..."
	$shortcutPath = [System.Environment]::GetFolderPath('Desktop') + "`\HavenM.lnk"
    $target = "https://github.com/RavenfieldCommunity/HavenM"
    $shell = New-Object -ComObject WScript.Shell 
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $target
    $shortcut.IconLocation = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe,0"
    $shortcut.WorkingDirectory = [System.Environment]::GetFolderPath('Desktop')
    $shortcut.Save()
  }
}

function Apply-BepInEX {
  if ( (Test-Path -Path "$global:gamePath\winhttp.dll") -eq $true )  #如果已经安装就跳过
  {
    Write-Host "BepInEX is already installed, skip"
  }
  else
  {
    Write-Host "Downloading BepInEX (5.4.22 for x64)..." 
	$bepInEXDownloadPath = "$global:downloadPath\BepInEX.zip"
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/BepInEx/BepInEx/releases/download/v5.4.22/BepInEx_x64_5.4.22.0.zip" `
      -WebSession $session `
      -OutFile $bepInEXDownloadPath `
      -Headers @{
        "method"="GET"
        "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
        "accept-encoding"="gzip, deflate, br, zstd"
      }
      if ($? -eq $true)  #无报错就校验并解压
      {
	    Write-Host "BepInEX downloaded"  
        Expand-Archive -Path $bepInEXDownloadPath -DestinationPath $global:gamePath -Forc
        if ($? -eq $true) {
            Write-Host "BepInEX installed"           
        }
        else { 
           Write-Warning "BepInEX install failed"
        }
      }
      else #错误处理
      { 
        Write-Warning "BepInEX install failed"
      }
    }
}

function Apply-ACUpdater {
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.github.com/repos/RavenfieldCommunity/HavenM/releases/latest" `
    -WebSession $session `
    -Headers @{
      "Accept"="application/json, text/plain, */*"
      "Accept-Encoding"="gzip, deflate, br, zstd"
    } `
    -ContentType "application/json;charset=utf-8"
  if ($? -eq $true)
  {
    $json_ = $request_.Content | ConvertFrom-Json
	if (  (Test-Path -Path "$global:gamePath\Ravenfield\BepInEx\plugins\HavenM.ACUpdater.dll") -eq $true )
	{
      temp_ = Get-Date (Get-Item "$global:gamePath\BepInEx\plugins\HavenM.ACUpdater.dll").LastWriteTime
      if ( $temp_ -gt (Get-Date $json_.assets[0].updated_at))
	  {
		Write-Host "ACUpdater is no update";
        return;		
	  }
	}
  }
  
  Write-Host "Downloading ACUpdater ..." 
	$acUpdaterDownloadPath = "$global:downloadPath\HavenM.ACUpdater.zip"
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/RavenfieldCommunity/HavenM/releases/download/ACUpdaterRelease/HavenM.ACUpdater.dll" `
        -WebSession $session `
		-OutFile $acUpdaterDownloadPath `
        -Headers @{
        "method"="GET"
        "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
        "accept-encoding"="gzip, deflate, br, zstd"
      }
    if ($? -eq $true) {
      Write-Host "Installing ACUpdater ..."   		
      Copy-Item $acUpdaterDownloadPath  "$global:gamePath\BepInEx\plugins\HavenM.ACUpdater.dll" -Force
      if ($? -eq $true) {
        Write-Host "ACUpdater installed"           
      }
      else {
        Write-Warning "Install ACUpdater failed"
      }
    }
}


###主程序
Write-Host "# HavenM Installation script
# The project is made by Stand_Up
# Installation script is made by Github@RavenfieldCommunity
# Discord server: ?
# Refer: https://github.com/RavenfieldCommunity/HavenM

#Tip: Re-installing enquals updating
#Tip: This script will create a updater shortcut in your desktop and install updater plugin!
"
if ( $isUpdate -eq $true ) { Write-Host "Updating HavenM ..." }
Apply-HavenM
Apply-BepInEX
Apply-ACUpdater
Apply-Updater
if ( $isUpdate -eq $ture ) { 
  if ( $(tasklist | findstr "steam.exe") -ne $null ) { 
    Write-Host "Relaunch game ..."
    start "steam://launch/636480/dialog"
  }
}	
Exit-IScript