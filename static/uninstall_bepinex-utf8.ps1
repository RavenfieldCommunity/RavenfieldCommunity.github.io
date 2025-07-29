#RF BepInEX卸载工具

#退出脚本递归
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了"
  Exit
  Exit-IScript
}	

function MLangWrite-Output ([string]$cn, [string]$en) {
  if ((Get-Culture).Name -eq "zh-CN") { Write-Output $cn }
  else { Write-Output $en }
}

function MLangWrite-Warning ([string]$cn, [string]$en) {
  if ((Get-Culture).Name -eq "zh-CN") { Write-Warning $cn }
  else { Write-Output $en }
}

$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
$global:corelibSrc = $null
$global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1'); 
if ( $global:corelibSrc -eq $null ) {
  $global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity-static.netlify.app/corelib-utf8.ps1'); 
}
if ( $global:corelibSrc -eq $null ) {
  MLangWrite-Warning "无法初始化依赖库" "Cannot init corelib";
  Exit-IScript;
}
else { iex $global:corelibSrc; }

function Remove-BepInEX {
  #定义文件位置
  MLangWrite-Output "将要执行的操作:
  删除 BepInEX 文件夹
  删除 hook (winhttp.dll)
  删除 doorstop配置" "Steps to do:
  Delete BepInEX folder
  Delete hook (winhttp.dll)
  Delete doorstop config"
  $file1 = "$global:gamePath\BepInEX"
  $file2 = "$global:gamePath\winhttp.dll"
  $file3 = "$global:gamePath\doorstop_config.ini"
  if ( (Test-Path -Path $file1) -eq $true ){
    MLangWrite-Output "删除 BepInEX 文件夹 ..." "Deleting BepInEX folder ..."
    rm $file1 -Recurse }
  if ( (Test-Path -Path $file2) -eq $true ){
	  MLangWrite-Output "删除 hook ..." "Deleting hook ..."
    rm $file2 }
  if ( (Test-Path -Path $file3) -eq $true ){
	  MLangWrite-Output "删除 doorstop配置 ..." "Deleting doorstop config (2/3) ..."
    rm $file3}
}

function Remove-MLang {
  #定义文件位置
  $file1 = "$global:gamePath\BepInEX\plugins\XUnity.AutoTranslator"
  $file2 = "$global:gamePath\BepInEX\plugins\XUnity.ResourceRedirector"
  $file3 = "$global:gamePath\BepInEx\core\XUnity.Common.dll"
  $file4 = "$global:gamePath\BepInEx\Translation"
  $file5 = "$global:gamePath\BepInEx\config\AutoTranslatorConfig.ini"
  $file6 = "$global:gamePath\tmpchinesefont"
  $file7 = "$global:gamePath\arialuni_sdf_u2019"
  $file8 = "$global:gamePath\wenquanyi_bitmap_song_12px_sdf"
  Write-Output "将要执行的操作:
  删除 XUnity.AutoTranslator
  删除 XUnity.ResourceRedirector
  删除 XUnity.Common
  删除 配置文件
  删除 翻译文件
  删除 字体补丁"
  if ( (Test-Path -Path $file1) -eq $true ) 
  {
    Write-Host "删除 XUnity.AutoTranslator文件夹 ..."
    rm $file1 -Recurse}
  if ( (Test-Path -Path $file2) -eq $true ) 
  {
	Write-Host "删除 XUnity.ResourceRedirector ..."
    rm $file2 -Recurse}
  if ( (Test-Path -Path $file3) -eq $true ) 
  {
	Write-Host "删除 XUnity.Common ..."
    rm $file3}
  if ( (Test-Path -Path $file5) -eq $true ) 
  {
	Write-Host "删除 配置文件 ..."
    rm $file5}
  if ( (Test-Path -Path $file4) -eq $true ) 
  {
	Write-Host "删除 翻译文件 ..."
  rm $file4 -Recurse}
  if ( (Test-Path -Path $file6) -eq $true ){
    Write-Host "删除 字体补丁 ..."
    rm $file6 -Recurse
  }
  if ( (Test-Path -Path $file7) -eq $true ){
    Write-Host "删除 字体补丁 ..."
    rm $file7 -Recurse
  }
  if ( (Test-Path -Path $file8) -eq $true ){
    Write-Host "删除 字体补丁 ..."
    rm $file8 -Recurse
  }
}

function Remove-RavenMCN {
  #定义文件位置
  $file1 = "$global:gamePath\BepInEx\plugins\RavenM.dll"   #如果文件存在
  $file2 = "$global:gamePath\BepInEx\plugins\RavenM0.dll"   #如果文件存在
  $file3 = "$global:gamePath\BepInEx\config\RavenM.cfg"   #如果文件存在
  Write-Output "将要执行的操作:
  删除 联机插件
  删除 配置文件"
  if ( (Test-Path -Path $file1) -eq $true )  {
    Write-Host "删除 联机插件 ..."
	rm $file1
  }
  if ( (Test-Path -Path $file2) -eq $true )  {
    Write-Host "删除 联机插件 ..."
	rm $file2
  }
  if ( (Test-Path -Path $file3) -eq $true )  {
    Write-Host "删除 配置文件 ..."
	rm $file3
  }
}

function Remove-HavenM {
  #定义文件位置
  MLangWrite-Output "将要执行的操作:
  删除 更新服务
  替换已修改的文件至原版" "Steps to do:
  Delete ACUpdater
  Replace the changed file to orignal one"
  $file1 = "$global:gamePath\BepInEX\plugins\HavenM.ACUpdater.dll"
  $file2 = "$global:gamePath\BepInEX\plugins\HavenM.ACUpdater0.dll"
  if ( (Test-Path -Path $file1) -eq $true )  {
    MLangWrite-Output "删除 自动更新服务 ..." "Deleting ACUpdater ..."
	rm $file1
  }
  if ( (Test-Path -Path $file2) -eq $true )  {
    MLangWrite-Output "删除 自动更新服务 ..." "Deleting ACUpdater ..."
	rm $file2
  }
  $temp_ = Remove-HavenM
  MLangWrite-Output "正在调用 Steam 修补游戏文件 ..." "Using Steam validate the game ..."
  start "steam://validate/636480"
}

###主程序
MLangWrite-Output "# RF BepInEX插件 卸载脚本
# 卸载脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html

# 提示：报错请反馈！
" "# RF BepInEX plugins uninstallation script
# The script is made by Github@RavenfieldCommunity
# Refer: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html

# Tip: if buggy, please feedback!
"
MLangWrite-Output "请选择操作:
  1. 删除多语言
  2. 删除多人联机国内版
  3. 删除HavenM
  4. 完全删除BepInEX框架及其附属插件
直接按 回车键 则取消执行，按 对应数字序号 并回车 执行对应操作" "Choose an action:
  1. Delete MLang
  2. Deletw RavenMCN
  3. Delete HavenM
  4. Competely detele BepInEX and plugins inside
Press Enter only to do nothing, press corresponding number and Enter to run the action" 
$yesRun = Read-Host -Prompt ":>"
if ($yesRun  -eq "1") { $temp_ = Remove-MLang }
elseif ($yesRun  -eq "2") { $temp_ = Remove-RavenMCN }
elseif ($yesRun  -eq "3") { $temp_ = Remove-HavenM }
elseif ($yesRun  -eq "4") { $temp_ = Remove-BepInEX }
MLangWrite-Output "操作结束" "Finished"
Exit-IScript