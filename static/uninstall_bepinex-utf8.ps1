#RF BepInEX卸载工具

#退出脚本递归
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了"
  Exit
  Exit-IScript
}	


$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
$global:corelibSrc = $null
$global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1'); 
if ( $global:corelibSrc -eq $null ) {
  $global:corelibSrc = $w.DownloadString('http://ghproxy.net/https://raw.githubusercontent.com/ravenfieldcommunity/ravenfieldcommunity.github.io/main/static/corelib-utf8.ps1'); 
}
if ( $global:corelibSrc -eq $null ) {
  Write-Warning "无法初始化依赖库 Cannot init corelib";
  Exit-IScript;
}
else { iex $global:corelibSrc; }

function Remove-BepInEX {
  #定义文件位置
  $file1 = "$global:gamePath\BepInEX"
  $file2 = "$global:gamePath\winhttp.dll"
  $file3 = "$global:gamePath\doorstop_config.ini"
  if ( (Test-Path -Path $file2) -eq $true ) #如果文件存在
  {
    Write-Host "删除 BepInEX文件夹 (1/3) ..."
	rm $file1 -Recurse
	Write-Host "删除 winhttp.dll (2/3) ..."
	rm $file2
	Write-Host "删除 doorstop_config.ini (3/3) ..."
	rm $file3
  }
  else  #错误处理
  {
    Write-Warning "未安装"
    return $false
  }
}

function Remove-MLang {
  #定义文件位置
  $file1 = "$global:gamePath\BepInEX\plugins\XUnity.AutoTranslator"
  $file2 = "$global:gamePath\BepInEX\plugins\XUnity.ResourceRedirector"
  $file3 = "$global:gamePath\BepInEx\core\XUnity.Common.dll"
  $file4 = "$global:gamePath\BepInEx\Translation"
  if ( (Test-Path -Path $file1) -eq $true ) #如果文件存在
  {
    Write-Host "删除 XUnity.AutoTranslator文件夹 (1/4) ..."
	rm $file1 -Recurse
	Write-Host "删除 XUnity.ResourceRedirector (2/4) ..."
	rm $file2 -Recurse
	Write-Host "删除 XUnity.Common.dll (3/4) ..."
	rm $file3
	Write-Host "删除 翻译文件 (4/4) ..."
	rm $file4 -Recurse
  }
  else  #错误处理
  {
    Write-Warning "未安装"
    return $false
  }
}

function Remove-RavenMCN {
  #定义文件位置
  $file1 = "$global:gamePath\BepInEx\plugins\RavenM.dll"   #如果文件存在
  if ( (Test-Path -Path $file1) -eq $true )  {
    Write-Host "删除 联机插件 (1/1) ..."
	rm $file1
  }
  else {
    Write-Warning "未安装"
    return $false
  }
}

function Remove-HavenM {
  #定义文件位置
  $file1 = "$global:gamePath\BepInEx\plugins\HavenM.ACUpdater.dll"   #如果文件存在
  if ( (Test-Path -Path $file1) -eq $true )  {
    Write-Host "删除 自动更新服务 (1/1) ..."
	rm $file1
  }
  else {
    Write-Warning "未安装 自动更新服务"
    return $false
  }
}

###主程序
Write-Host "# RF BepInEX插件 卸载脚本
# 卸载脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html

# 提示：报错请反馈！
"
Write-Host "请选择操作:
  1. 删除多语言
  2. 删除多人联机
  3. 删除HavenM
  4. 完全删除BepInEX框架及其附属插件
" 
$yesRun = Read-Host -Prompt "直接按 回车键 则取消执行，按 对应数字序号 并回车 执行对应操作:>"
if ($yesRun  -eq "1") { $temp_ = Remove-MLang }
if ($yesRun  -eq "2") { $temp_ = Remove-RavenMCN }
if ($yesRun  -eq "3") { 
  $temp_ = Remove-HavenM
  Write-Output "正在调用Steam修补游戏文件 ..." 
  start "steam://validate/636480"
}
elseif ($yesRun  -eq "4") { $temp_ = Remove-BepInEX }
Exit-IScript