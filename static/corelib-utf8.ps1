#RF Powershell依赖lib
#感谢: BartJolling/ps-steam-cmd
#感谢: api.leafone.cn

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

#退出脚本递归，但必须在各ps脚本手动定义
function Exit-IScript {
  Read-Host "您现在可以关闭窗口了 Now you can close this window";
  Exit;
  Exit-IScript;
}

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
    	if ($parsedVdf."$num".apps.636480 -ne $null) { return $parsedVdf."$num".path.Replace('\\','\'); }
      }
      #错误处理
      Write-Warning "方式1无法获取游戏安装路径或未安装游戏 Method1 fail";
    }
    else  #错误处理
    {
      Write-Warning "方式1无法获取Libraryfolders Method1 fail";
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
    	if ($parsedVdf."$num".apps.636480 -ne $null) { return $parsedVdf."$num".path.Replace('\\','\'); }
      }
      #错误处理
    	Write-Warning "方式2无法获取游戏安装路径或未安装游戏 Method2 fail";
    }
    else  #错误处理
    {
      Write-Warning "方式2无法获取Libraryfolders Method2 fail";
    }
  }
  
  #使用方式3
  if ( (Test-Path -Path "$steamPath\steamapps\common\Ravenfield") -eq $true ) #如果存在
  {
    return "$steamPath"
  }
  else
  {
	Write-Warning "方式3无法获取Libraryfolders Method3 fail";
  }	  
  
  #使用方式4
  Write-Host "使用方式4 Using Method4 ..." 
  $temp_ = Read-Host -Prompt "请在手动启动游戏后，按 回车键 After start game, press Enter>";
  $result_ = Split-Path -Path (Get-Process ravenfield | Select-Object Path)[0].Path;
  if ( (Test-Path $result_) -eq $true )
  {
	$global:gamePath = result_;  #游戏本体位置
	return "$result_\..\..\..";
  }
  Write-Warning "方式4无法获取Libraryfolders Method4 fail";
  return $null;
}


###主程序
Write-Host "初始化环境 Initing env ...";

#32位检测
if ([Environment]::Is32BitOperatingSystem) { Write-Warning "可能不支持本机的32位系统，需要手动安装 The script may not support 32-bit system!"; }

#获取下载路径
$global:downloadPath = "$((Get-ChildItem Env:appdata).Value)\RavenfieldCommunityCN";
#如果下载路径不存在则新建
if ( (Test-Path -Path $downloadPath) -ne $true) { $result_ = mkdir $downloadPath; } 
#测试与打印下载目录
Write-Host "下载目录 Download path: $downloadPath";

#初始化变量
#仅需要再次读写的变量才加上Global标志
$vdf = [VdfDeserializer]::new();  #初始化VDF解析器
$global:RFCCoreLibInited = $true; #是否加载了此远程ps脚本
$global:gameLibPath = ""; #游戏安装的steam库的位置
if ($global:gamePath -eq $null) { $global:gamePath = ""; }  #游戏本体位置

#获取steam安装路径
$global:steamPath = "$((Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath)".Replace('/','\');
if ($? -eq $true) {
  Write-Host "Steam安装路径 Steam path: $($global:steamPath)"

  #获取游戏库位置
  $global:gameLibPath = Get-GameLibPath
  if ($global:gameLibPath -eq $null){ Exit-IScript }
  Write-Host "游戏所在Steam库路径 Game library path: $($global:gameLibPath)";

  #计算游戏安装位置
  if ($global:gamePath -eq "") { $global:gamePath = "$($global:gameLibPath)\steamapps\common\Ravenfield"; }
  Write-Host "游戏所在安装路径 Game path: $($global:gamePath)";
  Write-Host "";
}
else  #错误处理
{
  Write-Host "无法获取Steam安装路径 Cannot get steam path";
  Exit-IScript
}