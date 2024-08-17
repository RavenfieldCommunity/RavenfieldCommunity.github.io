#RavenMCN安装脚本

Out-String -InputObject "# RavenM国内版安装脚本
# 由RavenfieldCommunity维护"

#定义变量
$isOldFileExist = $false

#获取本地路径
$envVar = Get-ChildItem Env:appdata
$path = $envVar.Value
$folderPath = $path + "\RavenmCN"
$zipPath = $folderPath + "\RavenMCN.zip"
$exePath = $folderPath + "\RavenM一键安装工具.exe"

$isPathExist = Test-Path -Path $folderPath
if ($isPathExist -eq $true) {}
else {$result_ = mkdir $folderPath}

$isOldFileExist = Test-Path -Path $zipPath

#打印下载目录
$tipText = "下载目录：" + $folderPath
Out-String -InputObject $tipText

#定义函数
function Download-RavenMCN {
  Out-String -InputObject "正在下载文件..." 
  #创建session并使用直链api请求文件
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
  $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/ih1aS1z0ofne&type=down" `
    -WebSession $session `
    -OutFile $zipPath `
    -Headers @{
      "authority"="api.leafone.cn"
      "method"="GET"
      "path"="/api/lanzou?url=https://www.lanzouj.com/ih1aS1z0ofne&type=down"
      "scheme"="https"
      "accept"="text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7"
      "accept-encoding"="gzip, deflate, br, zstd"
      "accept-language"="zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6"
      "priority"="u=0, i"
      "sec-ch-ua"="`"Microsoft Edge`";v=`"125`", `"Chromium`";v=`"125`", `"Not.A/Brand`";v=`"24`""
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"="`"Windows`""
      "sec-fetch-dest"="document"
      "sec-fetch-mode"="navigate"
      "sec-fetch-site"="none"
      "sec-fetch-user"="?1"
      "upgrade-insecure-requests"="1"
    }
    if ($_ -eq $null) {} else { Write-Warning $_ }
}

function CheckAndRun-RavenMCN {
  #校验hash
  $hash1 = Get-FileHash $zipPath -Algorithm SHA256
  $hash2 = $hash1.Hash
  Out-String -InputObject "安装文件Hash: $hash2"
  if ($hash2 -eq "946539FC1FF3B99D148190AD04435FAF9CBDD7706DBE8159528B91D7ED556F78") 
  { 
    Run-RavenMCN
  }
  else 
  { 
    Out-String -InputObject "安装文件校验不通过，请反馈给社区管理或重新下载"
    Read-Host -prompt "您现在可以关闭窗口了" 
  }
}

function Run-RavenMCN {
  #解压
  Out-String -InputObject "正在启动文件..."
  Expand-Archive $zipPath -DestinationPath $folderPath -Force
  #运行   
  Start-Process $exePath
  Out-String -InputObject "注意，运行安装文件不需要管理员权限"
  Read-Host -prompt "请手动安装完RavenM后再关闭本窗口"
  Read-Host -prompt "请手动安装完RavenM后再关闭本窗口"
}

function MainGet-RavenMCN {
  Download-RavenMCN
  $result_ = Test-Path -Path $zipPath
  if ($result_ -eq $true)
  {
    CheckAndRun-RavenMCN
  }
  else
  {
    Out-String -InputObject "安装文件下载失败，请检查网络或反馈给社区管理"
    Read-Host -prompt "您现在可以关闭窗口了"
  }
}


#主代码
if ($isOldFileExist -eq $true)
{
  Out-String -InputObject "本地存在安装文件，是否直接运行？" 
  $yesRun = Read-Host -Prompt "是请输入'1'，否则重新下载安装文件"
  Out-String -InputObject "" 
  if ($yesRun  -eq "1")
  {
    CheckAndRun-RavenMCN
  }
  else { MainGet-RavenMCN }
}
else { MainGet-RavenMCN }