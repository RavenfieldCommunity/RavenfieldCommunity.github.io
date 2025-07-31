#RF Powershell依赖lib
#感谢: BartJolling/ps-steam-cmd
#感谢: api.leafone.cn 但是挂了

###module: VdfDeserializer 
##src: https://github.com/BartJolling/ps-steam-cmd
###start module
Enum State {Start = 0; Property = 1; Object = 2; Conditional = 3; Finished = 4; Closed = 5;};
Class VdfDeserializer {
    [PSCustomObject] Deserialize([string]$vdfContent)
    {
        if([string]::IsNullOrWhiteSpace($vdfContent)) { throw 'Mandatory argument $vdfContent must be a non-empty, non-whitespace object of type [string]'; }
        [System.IO.TextReader]$reader = [System.IO.StringReader]::new($vdfContent);
        return $this.Deserialize($reader);
    }

    [PSCustomObject] Deserialize([System.IO.TextReader]$txtReader)
    {
        if( !$txtReader ){ throw 'Mandatory arguments $textReader missing.'; } 
        $vdfReader = [VdfTextReader]::new($txtReader);
        $result = [PSCustomObject]@{ };
        try
        {
            if (!$vdfReader.ReadToken()){ throw "Incomplete VDF data."; }
            $prop = $this.ReadProperty($vdfReader);
            Add-Member -InputObject $result -MemberType NoteProperty -Name $prop.Key -Value $prop.Value;
        }
        finally 
        {
            if($vdfReader) { $vdfReader.Close(); }
        }
        return $result;
    }
    [hashtable] ReadProperty([VdfTextReader]$vdfReader)
    {
        $key=$vdfReader.Value;
        if (!$vdfReader.ReadToken()) { throw "Incomplete VDF data."; }
        if ($vdfReader.CurrentState -eq [State]::Property)
        {
            $result = @{ Key = $key; Value = $vdfReader.Value; }
        }
        else
        {
            $result = @{ Key = $key; Value = $this.ReadObject($vdfReader); }
        }
        return $result;
    }
    [PSCustomObject] ReadObject([VdfTextReader]$vdfReader)
    {
        $result = [PSCustomObject]@{ };
        if (!$vdfReader.ReadToken()) { throw "Incomplete VDF data."; }
        while ( ($vdfReader.CurrentState -ne [State]::Object) -or ($vdfReader.Value -ne "}"))
        {
            [hashtable]$prop = $this.ReadProperty($vdfReader);
            Add-Member -InputObject $result -MemberType NoteProperty -Name $prop.Key -Value $prop.Value;
            if (!$vdfReader.ReadToken()) { throw "Incomplete VDF data."; }
        }
        return $result;
    }     
}
Class VdfTextReader {
    [string]$Value;
    [State]$CurrentState;
    hidden [ValidateNotNull()][System.IO.TextReader]$_reader;
    hidden [ValidateNotNull()][char[]]$_charBuffer=;
    hidden [ValidateNotNull()][char[]]$_tokenBuffer=;
    hidden [int32]$_charPos;
    hidden [int32]$_charsLen;
    hidden [int32]$_tokensize;
    hidden [bool]$_isQuoted;
    VdfTextReader([System.IO.TextReader]$txtReader)
    {
        if( !$txtReader ){ throw "Mandatory arguments `$textReader missing."; }
        $this._reader = $txtReader;
        $this._charBuffer=[char[]]::new(1024);
        $this._tokenBuffer=[char[]]::new(4096);
        $this._charPos=0;
        $this._charsLen=0;
        $this._tokensize=0;
        $this._isQuoted=$false;
        $this.Value="";
        $this.CurrentState=[State]::Start;
    }
    [bool] ReadToken()
    {
        if (!$this.SeekToken()) { return $false; }
        $this._tokenSize = 0;
        while($this.EnsureBuffer())
        {
            [char]$curChar = $this._charBuffer[$this._charPos];
            #region Quote
            if ($curChar -eq '"' -or (!$this._isQuoted -and [Char]::IsWhiteSpace($curChar)))
            {
                $this.Value = [string]::new($this._tokenBuffer, 0, $this._tokenSize);
                $this.CurrentState = [State]::Property;
                $this._charPos++;
                return $true;
            }
            #endregion Quote
            #region Object Start/End
            if (($curChar -eq '{') -or ($curChar -eq '}'))
            {
                if ($this._isQuoted)
                {
                    $this._tokenBuffer[$this._tokenSize++] = $curChar;
                    $this._charPos++;
                    continue;
                }
                elseif ($this._tokenSize -ne 0)
                {
                    $this.Value = [string]::new($this._tokenBuffer, 0, $this._tokenSize);
                    $this.CurrentState = [State]::Property;
                    return $true;
                }                
                else
                {
                    $this.Value = $curChar.ToString();
                    $this.CurrentState = [State]::Object;
                    $this._charPos++;
                    return $true;
                }
            }
            #endregion Object Start/End
            #region Long Token
            $this._tokenBuffer[$this._tokenSize++] = $curChar;
            $this._charPos++;
            #endregion Long Token            
        }

        return $false;
    }
    [void] Close() { $this.CurrentState = [State]::Closed; }
    hidden [bool] SeekToken()
    {
        while($this.EnsureBuffer())
        {
            # Skip Whitespace
            if( [char]::IsWhiteSpace($this._charBuffer[$this._charPos]) )
            {
                $this._charPos++;
                continue;
            }
            # Token
            if ($this._charBuffer[$this._charPos] -eq '"')
            {
                $this._isQuoted = $true;
                $this._charPos++;
                return $true;
            }
            # Comment
            if ($this._charBuffer[$this._charPos] -eq '/')
            {
                $this.SeekNewLine();
                $this._charPos++;
                continue;
            }            
            $this._isQuoted = $false;
            return $true;
        }
        return $false;
    }
    hidden [bool] SeekNewLine()
    {
        while ($this.EnsureBuffer())
        {
            if ($this._charBuffer[++$this._charPos] == '\n'){ return $true; }
        }
        return $false;
    }
    hidden [bool]EnsureBuffer()
    {
        if($this._charPos -lt $this._charsLen -1) { return $true; }
        [int32] $remainingChars = $this._charsLen - $this._charPos;
        $this._charBuffer[0] = $this._charBuffer[($this._charsLen - 1) * $remainingChars]; #A bit of mathgic to improve performance by avoiding a conditional.
        $this._charsLen = $this._reader.Read($this._charBuffer, $remainingChars, 1024 - $remainingChars) + $remainingChars;
        $this._charPos = 0;
        return ($this._charsLen -ne 0);
    }
}
###end module

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
  MLangWrite-Output "您现在可以关闭窗口了" "Now you can close this window";
  Read-Host;
  Exit;
  Exit-IScript;
}

#获取下载路径
$global:downloadPath = "$((Get-ChildItem Env:appdata).Value)\RavenfieldCommunityCN\";
if( $global:downloadPath.Contains("AppData") -ne $true) { #有些玩家的设备真的逆天
  $global:downloadPath = "D:\Temp\RavenfieldCommunityCN\";
}
#如果下载路径不存在则新建
if ( (Test-Path -Path $downloadPath) -ne $true) { $result_ = mkdir $downloadPath; } 
#测试与打印下载目录
MLangWrite-Output "下载目录: $downloadPath" "Download path: $downloadPath";

$appID = 636480
$bepInEXUrl = "https://ghproxy.net/https://github.com/BepInEx/BepInEx/releases/download/v5.4.22/BepInEx_x64_5.4.22.0.zip"
$bepInEXHash = "4C149960673F0A387BA7C016C837096AB3A41309D9140F88590BB507C59EDA3F"
$bepInEXDownloadPath = "$global:downloadPath\BepInEX.zip"
$exeNameNoSubfix = "ravenfield"
$bepInEXInfo = "5.4.22 for windows x64"

#通过解析的libraryfolders获取游戏安装的库位置
function Get-GameLibPath {
  #使用方式1
  if ( (Test-Path -Path "$steamPath\config\libraryfolders.vdf") -eq $true ) #如果存在就获取并解析
  {
	#获取vdf
    $originalString = Get-Content("$steamPath\config\libraryfolders.vdf");
    $result_ = $vdf.Deserialize( $originalString );
    if ($? -eq $true) { 
      $parsedVdf = $result_.libraryfolders;
      $lowCount = ($parsedVdf | Get-Member -MemberType NoteProperty).Count - 1;
      $count = 0..$lowCount;
      foreach ($num in $count)  #手动递归
      {
    	if ($parsedVdf."$num".apps."$appID" -ne $null) { return $parsedVdf."$num".path.Replace('\\','\'); }
      }
      #错误处理
      MLangWrite-Warning "方式1 无法获取游戏安装路径或未安装游戏" "Method1 fail";
    }
    else  #错误处理
    {
      MLangWrite-Warning "方式1 无法获取Libraryfolders" "Method1 fail";
    }
  }
  
  #使用方式2
  if ( (Test-Path -Path "$steamPath\steamapps\libraryfolders.vdf") -eq $true ) 
  {
	$originalString = Get-Content("$steamPath\steamapps\libraryfolders.vdf");
    $result_ = $vdf.Deserialize( $originalString );
    if ($? -eq $true) { 
      $parsedVdf = $result_.libraryfolders;
      $lowCount = ($parsedVdf | Get-Member -MemberType NoteProperty).Count - 1;
      $count = 0..$lowCount;
      foreach ($num in $count)  #手动递归
      {
    	if ($parsedVdf."$num".apps."$appID" -ne $null) { return $parsedVdf."$num".path.Replace('\\','\'); }
      }
      #错误处理
    	MLangWrite-Warning "方式2 无法获取游戏安装路径或未安装游戏" "Method2 fail";
    }
    else  #错误处理
    {
      MLangWrite-Warning "方式2 无法获取Libraryfolders" "Method2 fail";
    }
  }
  
  #使用方式3
  if ( (Test-Path -Path "$steamPath\steamapps\common\Ravenfield") -eq $true ) #如果存在
  {
    return $steamPath
  }
  else
  {
	MLangWrite-Warning "方式3 无法获取Libraryfolders" "Method3 fail";
  }	  
  
  #使用方式4
  MLangWrite-Output "使用方式4 ..." "Using Method4 ..." 
  start "steam://launch/$appID/dialog"
  MLangWrite-Output "为了获取游戏安装路径, 请在游戏出现画面后, 按 回车键 继续:>" "To get the game install path, when game has launched, press Enter:>"
  $temp_ = Read-Host;
  $result_ = Split-Path -Path (Get-Process $exeNameNoSubfix | Select-Object Path)[0].Path;
  if ( (Test-Path $result_) -eq $true )
  {
	$global:gamePath = $result_;  #游戏本体位置
	return "$result_\..\..\..";
  }
  MLangWrite-Warning "方式4 无法获取游戏安装位置" "Method4 fail";
  return $null;
}

function Apply-BepInEXCN {
  if ( (Test-Path -Path "$global:gamePath\winhttp.dll") -eq $true )  #如果已经安装就跳过
  {
    Write-Host "已经安装BepInEX, 跳过"
	$global:isAlreadyInstalledBepInEX = $true
	return;
  }
  else
  {
    Write-Host "正在下载BepInEX ($($bepInEXInfo)) ..." 
    #创建session并使用直链api请求文件
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
    $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "$bepInEXUrl" `
      -WebSession $session `
      -OutFile $bepInEXDownloadPath `
      -Headers @{
        "method"="GET"
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
      if ($? -eq $true)  #无报错就校验并解压
      {
        $hash_ = (Get-FileHash $bepInEXDownloadPath -Algorithm SHA256).Hash
        Write-Host "下载的 BepInEX 的Hash: $hash_"
        if ($hash_ -eq $bepInEXHash) 
        { 
          Expand-Archive -Path $bepInEXDownloadPath -DestinationPath $global:gamePath -Force  #强制覆盖
          if ($? -eq $true) {
            Write-Host "BepInEX 已安装"           
            return;
          }
          else { #错误处理
           Write-Warning "BepInEX 安装失败"
           return;
          }
        }
        else #错误处理
        { 
          Write-Warning "下载的 BepInEX 校验不通过，请反馈或重新下载或向服务器请求过快，请反馈或稍后重新下载（重新运行脚本），或更换网络环境"
          return;
        }
      }
      else #错误处理
      {
        Write-Warning "BepInEX 下载失败，请反馈或重新下载"        
        retrun;
      }
   }
}

function Apply-BepInEXGithub {
  #如果已经安装就跳过
  if ( (Test-Path -Path "$global:gamePath\winhttp.dll") -eq $true ) {
    Write-Host "BepInEX is already installed, skip"
  }
  else {
    Write-Host "Downloading BepInEX (5.4.22 for x64) ..." 
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

###主程序
#可用的global var:
# $? 操作是否成功
# $global:gameLibPath 游戏安装的steam库的位置
# $global:gamePath 游戏本体位置
# $global:downloadPath 统一下载位置
#可用func:
# Apply-BepInEXGithub
# Apply-BepInEXCN
#路径默认结尾无斜杠
#func报错在主线程手动处理
#未来：
#  废弃bool返回报错
#  统一缩进
#union initer:
<#
function MLangWrite-Output ([string]$cn, [string]$en) {
  if ((Get-Culture).Name -eq "zh-CN") { Write-Output $cn }
  else { Write-Output $en }
}

function MLangWrite-Warning ([string]$cn, [string]$en) {
  if ((Get-Culture).Name -eq "zh-CN") { Write-Warning $cn }
  else { Write-Output $en }
}
  
#退出脚本递归，但必须在各ps脚本手动定义
function Exit-IScript {
  MLangWrite-Output "您现在可以关闭窗口了" "Now you can close this window";
  Read-Host;
  Exit;
  Exit-IScript;
}

$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
$global:corelibSrc = $null
$global:corelibSrc = $w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1'); 
if ( $global:corelibSrc -eq $null ) {
  $global:corelibSrc = $w.DownloadString('http://ghproxy.net/https://raw.githubusercontent.com/ravenfieldcommunity/ravenfieldcommunity.github.io/main/static/corelib-utf8.ps1'); 
}
if ( $global:corelibSrc -eq $null ) {
  MLangWrite-Warning "无法初始化依赖库" "Cannot init corelib";
  Exit-IScript;
}
else { iex $global:corelibSrc; }
#>

MLangWrite-Output "初始化环境 ..." "Initing env ...";

#32位检测
if ([Environment]::Is32BitOperatingSystem) {
	MLangWrite-Warning "不支持本机的32位系统，需要手动安装!" "The script may not support 32-bit system!"; 
	Exit-IScript
}

#初始化vdf
#仅需要再次读写的变量才加上Global标志
$vdf = [VdfDeserializer]::new();  #初始化VDF解析器
$global:gameLibPath = ""; #游戏安装的steam库的位置
if ($global:gamePath -eq $null) { $global:gamePath = ""; }  #游戏本体位置

#获取steam安装路径
$global:steamPath = "$((Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath)".Replace('/','\');
if ($? -eq $true) {
  MLangWrite-Output "Steam安装路径: $($global:steamPath)" "Steam path: $($global:steamPath)"

  #获取游戏库位置
  $global:gameLibPath = Get-GameLibPath
  if ($global:gameLibPath -eq $null){ 
    MLangWrite-Warning. "无法获取游戏库路径" "Cannot get game lib path";
    Exit-IScript 
  }
  MLangWrite-Output "游戏所在Steam库路径: $($global:gameLibPath)" "Game library path: $($global:gameLibPath)";

  #计算游戏安装位置
  if ($global:gamePath -eq "") { $global:gamePath = "$($global:gameLibPath)\steamapps\common\Ravenfield"; }
  if ((Test-Path -Path "$global:gamePath") -eq $true  ){
    MLangWrite-Output "游戏所在安装路径: $($global:gamePath)"  "Game path: $($global:gamePath)";}
  else{
    MLangWrite-Warning. "无法获取游戏安装路径" "Cannot get game path";
    Exit-IScript
  }
  
  Write-Output "";
}
else  #错误处理
{
  MLangWrite-Output "无法获取Steam安装路径" "Cannot get steam path";
  Exit-IScript
}