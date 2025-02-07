#RF HavenM 安装脚本
#感谢: BartJolling/ps-steam-cmd

#退出脚本递归，但必须在各ps脚本手动定义
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了 Now you can close this window";
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
		Write-Warning "无法初始化依赖库";
		Exit-IScript;
	}
}

function Apply-HavenM {
  $havenMDownloadPath = "$global:downloadPath\HavenM.zip"
  Write-Host "Downloading HavenM ..." 
  #创建session并使用直链api请求文件
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("_octo", "o", "/", ".github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("_device_id", "o", "/", "github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("user_session", "000-", "/", "github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("__Host-user_session_same_site", "000-", "/", "github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("logged_in", "no", "/", ".github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("dotcom_user", "null", "/", ".github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("color_mode", "null", "/", ".github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("cpu_bucket", "xlg", "/", ".github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("preferred_color_mode", "light", "/", ".github.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("_gh_sess", "null", "/", "github.com")))
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/RavenfieldCommunity/HavenM/releases/latest/download/Assembly-CSharp.dll" `
    -WebSession $session `
    -OutFile $havenMDownloadPath `
    -Headers @{
     "authority"="github.com"
     "method"="GET"
    "path"="/RavenfieldCommunity/HavenM/releases/download/Release/Assembly-CSharp.dll"
    "scheme"="https"
    "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    "accept-encoding"="gzip, deflate, br, zstd"
    "accept-language"="zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
    "dnt"="1"
    "priority"="u=0, i"
    "referer"="https://github.com/RavenfieldCommunity/HavenM/releases"
    "sec-ch-ua"="`"Not A(Brand`";v=`"8`", `"Chromium`";v=`"132`", `"Microsoft Edge`";v=`"132`""
    "sec-ch-ua-mobile"="?0"
    "sec-ch-ua-platform"="`"Windows`""
    "sec-fetch-dest"="document"
    "sec-fetch-mode"="navigate"
    "sec-fetch-site"="same-origin"
    "sec-fetch-user"="?1"
    "upgrade-insecure-requests"="1"
    }
    if ($? -eq $true)  #无报错就apply
    {
      Copy-Item -Path $havenMDownloadPath -Destination "$global:gamePath\ravenfield_Data\Managed\Assembly-CSharp.dll" -Force
      if ($? -ne $true) {
        Write-Warning "Fail" 
      } else  { Write-Host "Success" }
      #无报错就执行到这里
    }
    else #错误处理
    {
      Write-Warning "Download HavenM fail"        
    }
}

function Apply-Updater {
  $shortcutPath = [System.Environment]::GetFolderPath('Desktop') + "\\HavenM Updater.lnk"
  $target = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
  $shell = New-Object -ComObject WScript.Shell 
  $shortcut = $shell.CreateShortcut($shortcutPath)
  $shortcut.TargetPath = $target
  $shortcut.Arguments = " -nop -c `"$w=(New-Object System.Net.WebClient);$w.Encoding=[System.Text.Encoding]::UTF8;iex($w.DownloadString('http://ravenfieldcommunity.github.io/static/get_havenm-utf8.ps1'));Read-Host;`""
  $shortcut.WorkingDirectory = [System.Environment]::GetFolderPath('Desktop')
  $shortcut.Save()
}

###主程序
Write-Host "# HavenM Installation script
# The project is made by Stand_Up
# Installation script is made by Github@RavenfieldCommunity
# Discord server: ?

#Tip：Re-installing enquals updating
#Tip：This script will create a updater shortcut in your desktop!
"

Apply-HavenM
Exit-IScript
Apply-Updater