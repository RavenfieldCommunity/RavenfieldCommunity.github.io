#RF RavenM联机插件 直接安装脚本
#感谢: api.leafone.cn

#初始化依赖lib
$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
$global:corelibSrc = $null
$global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1'); 
if ( $global:corelibSrc -eq $null ) {
  $global:corelibSrc = $w.DownloadString('http://ghproxy.net/https://raw.githubusercontent.com/ravenfieldcommunity/ravenfieldcommunity.github.io/main/static/corelib-utf8.ps1'); 
}
if ( $global:corelibSrc -eq $null ) {
  Write-Warning "无法初始化依赖库";
  Exit-IScript;
}
else { iex $global:corelibSrc; }

function Apply-RavenMCN {
  $ravenmCNDownloadPath = "$global:downloadPath\RavenMCN.zip"  #RavenMCN下载到的本地文件
  
  #创建session并使用直链api请求文件
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36 Edg/131.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("user_locale", "zh-CN", "/", ".gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("oschina_new_user", "false", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("remote_way", "http", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("sensorsdata2015jssdkchannel", "", "/", ".gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("Hm_lvt_000", "000", "/", ".gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("sensorsdata2015jssdkcross", "", "/", ".gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("slide_id", "10", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("visit-gitee--000", "1", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("sl-session", "000", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("BEC", "000", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("tz", "Asia%2FShanghai", "/", "gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("HMACCOUNT", "000", "/", ".gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("Hm_lpvt_000", "000", "/", ".gitee.com")))
  $session.Cookies.Add((New-Object System.Net.Cookie("gitee-session-n", "", "/", ".gitee.com")))
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://gitee.com/api/v5/repos/RedQieMei/Raven-M/releases/372833" `
  -WebSession $session `
  -Headers @{
    "Accept"="application/json, text/plain, */*"
    "Accept-Encoding"="gzip, deflate, br, zstd"
    "Accept-Language"="zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
    "DNT"="1"
    "Referer"="https://gitee.com/api/v5/swagger"
    "Sec-Fetch-Dest"="empty"
    "Sec-Fetch-Mode"="cors"
    "Sec-Fetch-Site"="same-origin"
     "sec-ch-ua"="`"Microsoft Edge`";v=`"131`", `"Chromium`";v=`"131`", `"Not_A Brand`";v=`"24`""
    "sec-ch-ua-mobile"="?0"
    "sec-ch-ua-platform"="`"Windows`""
  } `
  -ContentType "application/json;charset=utf-8"
  if ($? -eq $true) {
  $json_ = $request_.Content | ConvertFrom-Json
  Write-Host "正在下载 RavenMCN ($($json_.name)) ..."
  $request2_ = Invoke-WebRequest -UseBasicParsing -Uri $json_.assets[0].browser_download_url `
  -WebSession $session `
  -OutFile $ravenmCNDownloadPath `
  -Headers @{
    "Accept"="gzip, deflate, br, zstd"
    "Accept-Encoding"="gzip, deflate, br, zstd"
    "Accept-Language"="zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
    "DNT"="1"
    "Referer"="https://gitee.com/api/v5/swagger"
    "Sec-Fetch-Dest"="document"
    "Sec-Fetch-Mode"="cors"
    "Sec-Fetch-Site"="same-origin"
    "sec-ch-ua"="`"Microsoft Edge`";v=`"131`", `"Chromium`";v=`"131`", `"Not_A Brand`";v=`"24`""
    "sec-ch-ua-mobile"="?0"
    "sec-ch-ua-platform"="`"Windows`""
  } `
  -ContentType "application/zip"
  if ($? -eq $true) {
  Write-Host "RavenMCN 已下载"   
		if ( $(tasklist | findstr "ravenfield") -ne $null ) { 
	  Read-Host "更新需要关闭游戏，请按 回车键 继续:>"
		taskkill /f /im ravenfield.exe
  Wait-Process -Name "ravenfield" -Timeout 10
  }	
  Expand-Archive -Path $ravenmCNDownloadPath -DestinationPath "$global:gamePath\BepInEx\plugins" -Force
  if ($? -eq $true) {
    Write-Host "RavenMCN 已安装"     
    return $true 
  }
  else {
    Write-Warning "RavenMCN 安装失败"
    return $false 
  }
  }
  else 
  { 
    Write-Warning "RavenMCN 下载失败或向服务器请求过快, 请反馈或稍后重新下载(重新运行脚本)"
    return $false
  }   
  }
  else {
  Write-Warning "无法获取 RavenMCN 信息或向服务器请求过快, 请反馈或稍后重新下载(重新运行脚本)"
  return $false 
  }
}

#退出脚本递归
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了"
  Exit
  Exit-IScript
}


###主程序
Write-Host "# RavenM联机插件 直接安装脚本
# RavenM国内版 由 Ravenfield贴吧@Aya 维护
# 安装脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/ravenm.html

# 提示: 在已安装插件的情况下重新安装插件 => 等价于更新
# 提示: 本地的安装文件会自动从服务器获取新的插件
# 提示: 本安装脚本不适用类Unix
"
if ( (Apply-BepInEXCN) -ne $true) { Exit-IScript }  #如果失败就exit
$temp_ = Apply-RavenMCN