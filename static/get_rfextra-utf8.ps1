#RFExtra 安装脚本
#感谢: BartJolling/ps-steam-cmd
#感谢: api.leafone.cn

###module: VdfDeserializer 
##src: https://github.com/BartJolling/ps-steam-cmd
###start module
Enum State
{Start = 0; Property = 1; Object = 2; Conditional = 3; Finished = 4; Closed = 5;
};

Class VdfDeserializer
{
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
Class VdfTextReader
{
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


#初始化变量
#仅需要再次读写的变量才加上Global标志
$vdf = [VdfDeserializer]::new()  #初始化VDF解析器
#获取Steam安装路径
$global:steamPath = "$((Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath)".Replace('/','\')
$errorWhenGetPath_ = $?  #保存错误
$global:gameLibPath = "" #游戏安装的steam库的位置
$global:gamePath = ""  #游戏本体位置
$global:libraryfolders = ""  #文件libraryfolders.vdf的位置
#获取下载路径
$appdataPath = (Get-ChildItem Env:appdata).Value
$downloadPath = "$appdataPath\RavenfieldCommunityCN"   
$bepInEXDownloadPath = "$downloadPath\BepInEX.zip"   #BepInEX下载到的本地文件
$translatorDownloadPath = "$downloadPath\Translator.zip"  #Autotranslator下载到的本地文件
#定义下载链接与文件hash
$bepInEXUrlID = "iMcD41xbcqgf"
$bepInEXInfo = "5.4.22 for x64"
$bepInEXHash = "4C149960673F0A387BA7C016C837096AB3A41309D9140F88590BB507C59EDA3F"
$translatorUrlID = "iyEcT2jmyqxc"
$translatorInfo = "5.3.0"
$translatorHash = "050828AA574AA8A6BC25B5E34D01DBF8B2C7DC0E5020959CD492EEDCDC055654"

if ( (Test-Path -Path $downloadPath) -ne $true) { $result_ = mkdir $downloadPath } #如果下载路径不存在则新建

#获取并解析libraryfolders
function Get-Libraryfolders {
  if ( (Test-Path -Path "$steamPath\config\libraryfolders.vdf") -eq $true ) #如果存在就获取并解析
  {
    $result_ = $vdf.Deserialize( "$(Get-Content("$steamPath\config\libraryfolders.vdf"))" );
    if ($? -eq $true) { return $result_.libraryfolders }
    else  #错误处理
    {
      Write-Warning "无法获取Libraryfolders"
      return ""
    }
  }
  else  #错误处理
  {
    Write-Warning "无法获取Libraryfolders"
    return ""
  }
}

#获取并解析libraryfolders的备用方式
function Get-LibraryfoldersSecond {
  if ( (Test-Path -Path "$steamPath\steamapps\libraryfolders.vdf") -eq $true ) #如果存在就获取并解析
  {
    $result_ = $vdf.Deserialize( "$(Get-Content("$steamPath\steamapps\libraryfolders.vdf"))" );
    if ($? -eq $true) { return $result_.libraryfolders }
    else  #错误处理
    {
      Write-Warning "无法获取Libraryfolders"
      return ""
    }
  }
  else  #错误处理
  {
    Write-Warning "无法获取Libraryfolders"
    return ""
  }
}

#通过解析的libraryfolders获取游戏安装的库位置
function Get-GamePath {
  $lowCount = ($global:libraryfolders | Get-Member -MemberType NoteProperty).Count - 1
  $count = 0..$lowCount
  foreach ($num in $count)  #手动递归
  {
    if ($global:libraryfolders."$num".apps.636480 -ne $null) { return $global:libraryfolders."$num".path.Replace('\\','\'); }
  }
  #错误处理
  Write-Warning "方式1无法获取游戏安装路径或未安装游戏"
  Get-LibraryfoldersSecond #使用方式2
  $lowCount = ($global:libraryfolders | Get-Member -MemberType NoteProperty).Count - 1
  $count = 0..$lowCount
  foreach ($num in $count)  #手动递归
  {
    if ($global:libraryfolders."$num".apps.636480 -ne $null) { return $global:libraryfolders."$num".path.Replace('\\','\'); }
  }
  Write-Warning "方式2无法获取游戏安装路径或未安装游戏"
  return ""
}

function DownloadAndApply-BepInEX {
  if ( (Test-Path -Path "$gamePath\winhttp.dll") -eq $true )  #如果已经安装就跳过
  {
    Write-Host "已经安装BepInEX，跳过"
    return $true 
  }
  else
  {
    Write-Host "正在下载BepInEX ($($bepInEXInfo))..." 
    #创建session并使用直链api请求文件
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
    $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/$($bepInEXUrlID)&type=down" `
      -WebSession $session `
      -OutFile $bepInEXDownloadPath `
      -Headers @{
        "authority"="api.leafone.cn"
        "method"="GET"
        "path"="/api/lanzou?url=https://www.lanzouj.com/$($bepInEXUrlID)&type=down"
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
      if ($? -eq $true)  #无报错就校验并解压
      {
        $hash_ = (Get-FileHash $bepInEXDownloadPath -Algorithm SHA256).Hash
        Write-Host "下载的BepInEX的Hash: $hash_"
        if ($hash_ -eq $bepInEXHash) 
        { 
          Expand-Archive -Path $bepInEXDownloadPath -DestinationPath $gamePath -Force  #强制覆盖
          if ($_ -eq $null) {
            Write-Host "BepInEX已安装"           
            return $true 
          }
          else { #错误处理
           Write-Warning "BepInEX安装失败"
           return $false 
          }
        }
        else #错误处理
        { 
          Write-Warning "下载的BepInEX校验不通过，请反馈或重新下载或向服务器请求过快，请反馈或稍后重新下载（重新运行脚本），或更换网络环境"
          return $false
        }
      }
      else #错误处理
      {
          Write-Warning "BepInEX下载失败，请反馈或重新下载"        
        retrun $false
      }
   }
}

function DownloadAndApply-RFExtra {
  if ( $false ) { #?
  }
  else
  {
	
    Write-Host "正在下载RFExtra..." 
	Start-Sleep -Seconds 10  #api只能10s调用一次，下载太快了
    #创建session并使用直链api请求文件
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
    $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/$($translatorUrlID)&type=down&pwd=3z1i" `
      -WebSession $session `
      -OutFile $translatorDownloadPath `
      -Headers @{
        "authority"="api.leafone.cn"
        "method"="GET"
        "path"="/api/lanzou?url=https://www.lanzouj.com/$($translatorUrlID)&type=down&pwd=3z1i"
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
      if ($? -eq $true)
      {
        $hash_ = (Get-FileHash $translatorDownloadPath -Algorithm SHA256).Hash
        Write-Host "下载的RFExtra的Hash: $hash_"
        if ($hash_ -eq $translatorHash) 
        { 
          Expand-Archive -Path "$translatorDownloadPath" -DestinationPath "$gamePath" -Force
          if ($_ -eq $null) {
            Write-Host "RFExtra已安装"           
            return $true 
          }
          else {
           Write-Warning "RFExtra安装失败"
           return $false 
          }
        }
        else 
        { 
          Write-Warning "下载的RFExtra校验不通过或向服务器请求过快，请反馈或稍后重新下载（重新运行脚本），或更换网络环境"
          return $false
        }
      }
      else
      {
          Write-Warning "RFExtra下载失败，请反馈或重新下载"        
        retrun $false
      }
   }
}

#退出脚本递归
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了"
  Exit
  Exit-IScript
}


###主程序
Write-Host "# RFExtra 安装脚本
# 安装脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html

# 提示：在已安装插件的情况下重新安装插件 => 等价于更新
# 提示：本插件仍相当早期，可能会造成莫名其妙的bug?
# 提示：请随时记得检查更新!
# 提示：任何Bug可在Steam评论区或百度贴吧、RavenfieldCommunity提出
# 当前最新版为 Update Beta 1
"

if ([Environment]::Is32BitOperatingSystem) 
{
  Write-Host ""
  Write-Warning "可能不支持本机的32位系统，需要手动安装!"
  Write-Host ""
}

#打印下载目录
Write-Host "下载目录：$downloadPath"

#如果获取steam安装目录没报错
if ($errorWhenGetPath_ -eq $true)
{
  Write-Host "Steam安装路径：$($global:steamPath)"

  #获取libraryfolders
  $global:libraryfolders = Get-Libraryfolders
  if ($global:libraryfolders -eq ""){ Exit-IScript }

  #获取游戏库位置
  $global:gameLibPath = Get-GamePath
  if ($global:gameLibPath -eq ""){ Exit-IScript }
  Write-Host "游戏所在Steam库路径：$($global:gameLibPath)"

  #计算游戏安装位置
  $global:gamePath = "$($global:gameLibPath)\steamapps\common\Ravenfield"
  Write-Host "游戏所在安装路径：$($global:gamePath)"
 
  if ( (DownloadAndApply-BepInEX) -ne $true) { Exit-IScript }  #如果失败就exit
  if ( (DownloadAndApply-RFExtra) -ne $true) { Exit-IScript }  #如果失败就exit
  Exit-IScript
}
else  #错误处理
{
  Write-Host "无法获取Steam安装路径"
  Exit-IScript
}