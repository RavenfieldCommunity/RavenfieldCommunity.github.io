#RavenMCN安装脚本

Write-Host "# RavenM 联机插件国内版 安装文件版 安装脚本
# RavenM国内版 由 Ravenfield贴吧吧主@Aya 维护
# 安装脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/ravenm.html

#提示：在已安装插件的情况下重新安装插件 => 等价于更新
#提示：本地的安装文件会自动从服务器获取新的插件
#提示：已知Windows Defender会误报安装文件，参考（安装后记得回复原来的WD设置，不建议使用链接中提供的工具！）：https://blog.csdn.net/qq_54780911/article/details/121993809
"

#定义变量
#获取本地路径
$path = (Get-ChildItem Env:appdata).Value
$folderPath = "$path\RavenfieldCommunityCN"
$zipPath = "$folderPath\RavenMCN.zip"
$tempPath = "$folderPath\RavenMCNTemp.zip"
$exePath = "$folderPath\RavenM一键安装工具.exe"

$ravenMCNUrlID = "ih1aS1z0ofne"
$ravenMCNUrlHash = "946539FC1FF3B99D148190AD04435FAF9CBDD7706DBE8159528B91D7ED556F78"

if ( (Test-Path -Path $folderPath)-ne $true) {$result_ = mkdir $folderPath}

#打印下载目录
Write-Host "下载目录：$folderPath"

#定义函数
function Download-RavenMCN {
  Write-Host "正在下载文件 ..." 
  #创建session并使用直链api请求文件
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
  $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/$($ravenMCNUrlID)&type=down" `
    -WebSession $session `
    -OutFile $tempPath `
    -Headers @{
      "authority"="api.leafone.cn"
      "method"="GET"
      "path"="/api/lanzou?url=https://www.lanzouj.com/$($ravenMCNUrlID)&type=down"
      "scheme"="https"
      "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      "accept-encoding"="gzip, deflate, br, zstd"
      "accept-language"="zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
      "priority"="u=0, i"
      "sec-ch-ua"="`"Microsoft Edge`";v=`"131`", `"Chromium`";v=`"125`", `"Not.A/Brand`";v=`"24`""
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"="`"Windows`""
      "sec-fetch-dest"="document"
      "sec-fetch-mode"="navigate"
      "sec-fetch-site"="none"
      "sec-fetch-user"="?1"
      "upgrade-insecure-requests"="1"
    }
    $error_ = $_
    if ($error_ -eq $null)
    {
      if ( CheckAndApplyTemp-RavenMCN ) { return $true }
      else { retrun $false }
    }
    else
    {
      retrun $false
    }
    
}

function CheckAndApplyTemp-RavenMCN {
  #校验hash
  $hash = (Get-FileHash $tempPath -Algorithm SHA256).Hash
  Write-Host "下载的安装文件的Hash: $hash"
  if ($hash -eq $ravenMCNUrlHash) 
  { 
    Copy-Item -Path $tempPath -Destination $zipPath
    if ($_ -eq $null) { return $true }
    else { return $false }
  }
  else 
  { 
    Write-Host "下载的安装文件校验不通过，请反馈或重新下载"
    return $false
  }
}

function CheckAndRunLocal-RavenMCN {
  #校验hash
  $hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash
  Write-Host "安装文件Hash: $hash"
  if ($hash -eq $ravenMCNUrlHash) 
  { 
    #解压
    Write-Host "正在启动文件 ..."
    Expand-Archive $zipPath -DestinationPath $folderPath -Force
    #运行   
    if ($_ -eq $null) { Start-Process $exePath } else { return $false }
    Write-Host "提示：运行安装文件不需要管理员权限"
    $result_ = Read-Host -Prompt "请等待安装工具出现时再关闭本窗口"
    return $true
  }
  else 
  { 
    Write-Host "安装文件校验不通过，请反馈或重新下载"
    UpdateLocal-RavenMCN
    return $false
  }
}

function UpdateLocal-RavenMCN {
  Write-Host "重新下载安装文件，下次启动时生效 ..."
  Download-RavenMCN
}

function MainGet-RavenMCN {
  if (Download-RavenMCN -eq $true)
  {
    Write-Host "安装文件下载并应用成功"
    $result_ = CheckAndRunLocal-RavenMCN
  }
  else
  {
    Write-Host "安装文件下载或应用失败，请检查网络或反馈"
  }
}

function Exit-IScript
{
  Read-Host "您现在可以关闭窗口了"
  exit
  Exit-IScript
}

#主代码
if ( (Test-Path -Path $zipPath) -eq $true)
{
  Write-Host "本地存在安装文件, 是否直接运行？" 
  $yesRun = Read-Host -Prompt "按 回车键 则直接运行本地安装文件，按 任意键并回车 则重新下载:>"
  if ($yesRun  -eq "")
  {
    $result_ = CheckAndRunLocal-RavenMCN
    Exit-IScript
  }
  else
  {
    MainGet-RavenMCN
    Exit-IScript
  }
}
else
{ 
  MainGet-RavenMCN
  Exit-IScript
}