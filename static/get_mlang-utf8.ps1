#RF社区多语言 简中 安装脚本
#感谢: BartJolling/ps-steam-cmd
#感谢: api.leafone.cn

#退出脚本递归
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了"
  Exit
  Exit-IScript
}

#初始化依赖lib
$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
$global:corelibSrc = $null
$global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1'); 
if ( $global:corelibSrc -eq $null ) {
  $global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity-static.netlify.app/corelib-utf8.ps1'); 
}
if ( $global:corelibSrc -eq $null ) {
  Write-Warning "无法初始化依赖库";
  Exit-IScript;
}
else { iex $global:corelibSrc; }

#定义下载链接与文件hash
$translatorUrl = "https://ghproxy.net/https://github.com/bbepis/XUnity.AutoTranslator/releases/download/v5.4.5/XUnity.AutoTranslator-BepInEx-5.4.5.zip"
$translatorInfo = "5.4.5"
$translatorHash = "1A037CB25159B9775D63284E73C5096F16490D4D627E2AB32F8F3D5C00F822AE"
$translatorDownloadPath = "$global:downloadPath\Translator.zip"  #Autotranslator下载到的本地文件
$itemId=3237432182

function Apply-TMFont {
  if ( (Test-Path -Path "$global:gamePath\wenquanyi_bitmap_song_12px_sdf") )
  { 
	$global:fontName="wenquanyi_bitmap_song_12px_sdf"	 
  }
  elseif ( (Test-Path -Path "$global:gamePath\arialuni_sdf_u2019")) 
  { 
	$global:fontName="arialuni_sdf_u2019"	 
  } 
  elseif ( (Test-Path -Path "$global:gamePath\tmpchinesefont")) 
  {
	$global:fontName="tmpchinesefont"	 
  }
  if ( $global:fontName -ne $null ) 
  { 
    Write-Host "字体补丁已安装, 跳过"
    return; 
  }
  
  Write-Host "是否安装用于EA32及以后的字体补丁? 可用字体:
1. 文泉驿点阵 12px (推荐, 最小体积)
2. Noto CJK
3. 微软雅黑"
  $yesRun = Read-Host -Prompt "按 对应序号数字键 并按 回车Enter 以确定，直接回车 或任意键 默认使用第一项:>"
  if ($yesRun  -eq "2") { 
    $global:downloadUrl = "https://ghproxy.net/github.com/RavenfieldCommunity/RavenfieldCommunity.github.io/releases/download/resources/arialuni_sdf_u2019" 
    $global:fontName="arialuni_sdf_u2019"
  }
  elseif ($yesRun  -eq "3") {
	$global:downloadUrl = "https://ghproxy.net/github.com/RavenfieldCommunity/RavenfieldCommunity.github.io/releases/download/resources/tmpchinesefont"
    $global:fontName="tmpchinesefont"	  
  }
  else {
    $global:downloadUrl = "https://ghproxy.net/github.com/RavenfieldCommunity/RavenfieldCommunity.github.io/releases/download/resources/wenquanyi_bitmap_song_12px_sdf" 
    $global:fontName="wenquanyi_bitmap_song_12px_sdf"	 
  }
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  Write-Host "正在下载 字体补丁 ($($global:fontName)) ..." 
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "$global:downloadUrl" `
    -WebSession $session `
    -OutFile "$global:gamePath/$global:fontName"
}

function Apply-TConfig {
  Write-Host "正在应用配置 ..."
  $configPath="$global:gamePath/BepInEx/config/AutoTranslatorConfig.ini"
  if (Test-Path -Path $configPath){
    (Get-Content -Path $configPath) -Replace 'OverrideFontTextMeshPro', "Override_OLD_FontTextMeshPro" | Set-Content -Path $configPath
    (Get-Content -Path $configPath) -Replace '\[Behaviour]', "[Behaviour]
OverrideFontTextMeshPro=$global:fontName
" | Set-Content -Path $configPath
    (Get-Content -Path $configPath) -Replace 'Endpoint', "End_OLD_point" | Set-Content -Path $configPath
    $resdult_ = (Get-Content -Path $configPath) -Replace '\[Service]', "[Service]
Endpoint=
" | Set-Content -Path $configPath
  }
  else{
    $targetDirectory="$global:gamePath/BepInEx/config"
    if ( (Test-Path -Path $targetDirectory) -ne $true) { $result_ = mkdir $targetDirectory; } 
    $resdult_ = New-Item -Path $targetDirectory -Name "AutoTranslatorConfig.ini" -ItemType "file" -Value "[Service]
Endpoint=
[Behaviour]
OverrideFontTextMeshPro=$global:fontName"
  }
}

function Apply-Translator {
  if ( (Test-Path -Path "$global:gamePath\BepInEx\core\XUnity.Common.dll") -eq $true ) {
    Write-Host "已经安装 XUnity.AutoTranslator, 跳过"
    return;
  }
  else {
    Write-Host "正在下载 XUnity.AutoTranslator ($($translatorInfo)) ..." 
    #创建session
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
    $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "$translatorUrl" `
      -WebSession $session `
      -OutFile $translatorDownloadPath `
      -Headers @{
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
      if ($? -eq $true) {
        $hash_ = (Get-FileHash $translatorDownloadPath -Algorithm SHA256).Hash
        Write-Host "下载的 XUnity.AutoTranslator 的Hash: $hash_"
        if ($hash_ -eq $translatorHash){ 
          Expand-Archive -Path $translatorDownloadPath -DestinationPath $global:gamePath -Force
          if ($_ -eq $null) {
            Write-Host "XUnity.AutoTranslator 已安装"           
            return;
          }
          else {
           Write-Warning "XUnity.AutoTranslator 安装失败"
           Exit-IScript
           return;
          }
        }
        else { 
          Write-Warning "下载的 XUnity.AutoTranslator 校验不通过或向服务器请求过快，请反馈或稍后重新下载（重新运行脚本），或更换网络环境"
          Exit-IScript
          return ;
        }
      }
      else {
          Write-Warning "XUnity.AutoTranslator 下载失败，请反馈或重新下载"        
        Exit-IScript
        return;
      }
   }
}

function Apply-MLang {
  #定义文件位置
  $file1 = "$global:gameLibPath\steamapps\workshop\content\$appID\$itemId\main_extra-sch.txt"
  $file2 = "$global:gameLibPath\steamapps\workshop\content\$appID\$itemId\main-sch.txt"
  $targetDirectoryPath = "$global:gamePath\BepInEX\Translation\en\Text"
  #如果文件存在
  if ( (Test-Path -Path $file1) -eq $true ) {
    Write-Host "已经订阅翻译文件"
    if ( (Test-Path -Path $targetDirectoryPath) -ne $true ) { $resdult_ = mkdir $targetDirectoryPath }  #如果目标目录不存在则新建
    #如果目录创建成功
    if ($? -eq $true) {
      #1
      Copy-Item -Path $file1 -Destination $targetDirectoryPath -Force
      if ($? -ne $true) { Write-Warning "导入翻译文件 main_extra-sch 失败" } else { Write-Host "导入翻译文件 main_extra-sch 成功" }

      #2
      Copy-Item -Path $file2 -Destination $targetDirectoryPath -Force
      if ($? -ne $true) {
        Write-Warning "导入翻译文件 main-sch 失败" 
        Exit-IScript
        return;
      } else  { Write-Host "导入翻译文件 main-sch 成功" }
      #无报错就执行到这里
      Write-Host "导入翻译文件成功" 
      return;
    } else {
      Write-Warning "创建目录失败"
  }}
  else {
    Write-Warning "未订阅 或 Steam未下载翻译文件到本地（Steam是否已经启动？Steam在后台时才会将工坊项目下载到本地）"
    Exit-IScript
    return;
  }
}


###主程序
Write-Host "# RF社区多语言 简体中文 安装脚本
# 安装脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html
# 参见: https://steamcommunity.com/sharedfiles/filedetails/?id=3237432182

# 提示：在已安装汉化的情况下重新安装汉化 => 等价于更新
# 提示：任何Bug可在Steam评论区或百度贴吧、RavenfieldCommunity提出
# 当前最新版为 Update 3 (202506131940)
"

if ( $(tasklist | findstr "msedge") -ne $null -or $(tasklist | findstr "chrome") -ne $null ) {
  if($(tasklist | findstr "ravenfield") -eq $null) {
    start "https://ravenfieldcommunity.github.io/docs/cn/Projects/mlang.html#%E6%8F%90%E7%A4%BA"
  }
}

Apply-BepInEXCN
Apply-Translator
Apply-MLang
Apply-TMFont
Apply-TConfig
Exit-IScript