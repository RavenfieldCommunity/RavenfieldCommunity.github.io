#RF HavenM 安装脚本
#感谢: BartJolling/ps-steam-cmd

function MLangWrite-Output ([string]$cn, [string]$en) {
	if ((Get-Culture).Name -eq "zh-CN") { Write-Output $cn }
	else { Write-Output $en }
}

function MLangWrite-Warning ([string]$cn, [string]$en) {
	if ((Get-Culture).Name -eq "zh-CN") { Write-Warning $cn }
	else { Write-Warning $en }
}

#退出脚本递归，但必须在各ps脚本手动定义
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了" "Now you can close this window";
  Exit;
  Exit-IScript;
}

#初始化依赖lib
$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
$global:corelibSrc = $null
$global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1'); 
if ( $global:corelibSrc -eq $null ) {
  $global:corelibSrc = $w.DownloadString('https://ravenfieldcommunity-static.netlify.app/corelib-utf8.ps1'); 
}
if ( $global:corelibSrc -eq $null ) {
  Write-Warning "无法初始化依赖库";
  Exit-IScript;
}
else { iex $global:corelibSrc; }

$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"

function Apply-HavenM {
  Write-Host "更新日志请至Github查看"
  #下载
  $havenMDownloadPath = "$global:downloadPath\HavenM.zip"
  Write-Host "正在下载 HavenM (约3600000B或3.6MB) ..." 
  $global:downloadUrl = $null
  Write-Host "是否使用KGithub加速?"
  $yesRun = Read-Host -Prompt "按 任意键并回车 确定，直接回车取消使用加速:>"
  if ($yesRun  -eq "1") { $global:downloadUrl = "https://gh.llkk.cc/https://github.com/RavenfieldCommunity/HavenM/releases/latest/download/Assembly-CSharp.dll" }
  else { $global:downloadUrl = "https://github.com/RavenfieldCommunity/HavenM/releases/latest/download/Assembly-CSharp.dll" }
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri $global:downloadUrl `
    -WebSession $session `
    -OutFile $havenMDownloadPath `
    -Headers @{
    "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
    "accept-encoding"="gzip, deflate, br, zstd"
   }
    if ($? -eq $true) {
      if ( $(tasklist | findstr "ravenfield") -ne $null ) { 
	    Read-Host "更新需要关闭游戏，请按 回车键 继续:>"
		taskkill /f /im ravenfield.exe
        Wait-Process -Name "ravenfield" -Timeout 10
      }	
	  Write-Host "正在安装 HavenM ..."
      Copy-Item -Path $havenMDownloadPath -Destination "$global:gamePath\ravenfield_Data\Managed\Assembly-CSharp.dll" -Force
      if ($? -ne $true) {
        Write-Warning "HavenM 安装失败" 
      } else  { Write-Host "HavenM 安装成功" }
    }
	#错误处理
    else  {
      Write-Warning "HavenM 下载失败"        
    }
}

###主程序
Write-Host "# HavenM 安装脚本
# HavenM 由 Stand_Up 维护
# 安装脚本 由 Github@RavenfieldCommunity 维护
# Discord 服务器: 非公开
# 参见: https://github.com/RavenfieldCommunity/HavenM
# 参见: https://ravenfieldcommunity.github.io/docs/en/Projects/havenm.html

# 提示：在已安装插件的情况下重新安装插件 => 等价于更新
# 提示: 此脚本不会安装自动更新插件!
"

Write-Warning "注意: 中国大陆玩家请自行手动启用Steamcommunity 302 或Watt toolkit的Github代理, 出于安全性考虑与基本没有稳定可用的镜像源, 脚本不自带加速功能, 直接继续可能无法下载HavenM
因为大部分时候下载速度极慢, 你可以一边玩游戏一边让脚本下载, 空闲的时候再回来看看下没下完和确认安装" 
if ( $(tasklist | findstr "Steamcommunity_302.exe") -eq $null ) { 
  if ( $(tasklist | findstr "watt") -eq $null ) {
    Write-Warning "疑似未启用反代加速工具"
  }
  if ( $(tasklist | findstr "v2ray") -eq $null ) {
    if ( $(tasklist | findstr "clash") -eq $null ) {
      Write-Warning "疑似真的东西什么也没开"
    }
  }
}
if ( $isUpdate -ne $null ) { Write-Host "正在更新 HavenM ..." }
Apply-HavenM
if ( $isUpdate -ne $null ) { 
  if ( $(tasklist | findstr "steam.exe") -ne $null ) { 
    Write-Host "正在重新启动游戏 ..."
    start "steam://launch/636480/dialog"
  }
}	
Exit-IScript