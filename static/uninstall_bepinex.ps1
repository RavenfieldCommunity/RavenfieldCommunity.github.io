#RF BepInEX卸载工具
#感谢: BartJolling/ps-steam-cmd
#感谢: api.leafone.cn

###module: VdfDeserializer 
##src: https://github.com/BartJolling/ps-steam-cmd
###start module
Enum State
{
    Start = 0
    Property = 1
    Object = 2
    Conditional = 3
    Finished = 4
    Closed = 5
};
Class VdfDeserializer
{
    [PSCustomObject] Deserialize([string]$vdfContent)
    {
        if([string]::IsNullOrWhiteSpace($vdfContent)) {
            throw 'Mandatory argument $vdfContent must be a non-empty, non-whitespace object of type [string]';
        }

        [System.IO.TextReader]$reader = [System.IO.StringReader]::new($vdfContent);
        return $this.Deserialize($reader);
    }

    [PSCustomObject] Deserialize([System.IO.TextReader]$txtReader)
    {
        if( !$txtReader ){
            throw 'Mandatory arguments $textReader missing.';
        }
        
        $vdfReader = [VdfTextReader]::new($txtReader);
        $result = [PSCustomObject]@{ };

        try
        {
            if (!$vdfReader.ReadToken())
            {
                throw "Incomplete VDF data.";
            }

            $prop = $this.ReadProperty($vdfReader);
            Add-Member -InputObject $result -MemberType NoteProperty -Name $prop.Key -Value $prop.Value;
        }
        finally 
        {
            if($vdfReader)
            {
                $vdfReader.Close();
            }
        }
        return $result;
    }

    [hashtable] ReadProperty([VdfTextReader]$vdfReader)
    {
        $key=$vdfReader.Value;

        if (!$vdfReader.ReadToken())
        {
            throw "Incomplete VDF data.";
        }

        if ($vdfReader.CurrentState -eq [State]::Property)
        {
            $result = @{
                Key = $key
                Value = $vdfReader.Value
            }
        }
        else
        {
            $result = @{
                Key = $key
                Value = $this.ReadObject($vdfReader);
            }
        }
        return $result;
    }

    [PSCustomObject] ReadObject([VdfTextReader]$vdfReader)
    {
        $result = [PSCustomObject]@{ };

        if (!$vdfReader.ReadToken())
        {
            throw "Incomplete VDF data.";
        }

        while ( ($vdfReader.CurrentState -ne [State]::Object) -or ($vdfReader.Value -ne "}"))
        {
            [hashtable]$prop = $this.ReadProperty($vdfReader);
            
            Add-Member -InputObject $result -MemberType NoteProperty -Name $prop.Key -Value $prop.Value;

            if (!$vdfReader.ReadToken())
            {
                throw "Incomplete VDF data.";
            }
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
        if( !$txtReader ){
            throw "Mandatory arguments `$textReader missing.";
        }

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

    <#
    .SYNOPSIS
        Reads a single token. The value is stored in the $Value property

    .DESCRIPTION
        Returns $true if a token was read, $false otherwise.
    #>
    [bool] ReadToken()
    {
        if (!$this.SeekToken())
        {
            return $false;
        }

        $this._tokenSize = 0;

        while($this.EnsureBuffer())
        {
            [char]$curChar = $this._charBuffer[$this._charPos];

            #No special treatment for escape characters

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

    [void] Close()
    {
        $this.CurrentState = [State]::Closed;
    }

    <#
    .SYNOPSIS
        Seeks the next token in the buffer.

    .DESCRIPTION
        Returns $true if a token was found, $false otherwise.
    #>
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

    <#
    .SYNOPSIS
        Seeks the next newline in the buffer.

    .DESCRIPTION
        Returns $true if \n was found, $false otherwise.
    #>
    hidden [bool] SeekNewLine()
    {
        while ($this.EnsureBuffer())
        {
            if ($this._charBuffer[++$this._charPos] == '\n')
            {
                return $true;
            }
        }
        return $false;
    }
    
    <#
    .SYNOPSIS
        Refills the buffer if we're at the end.

    .DESCRIPTION
        Returns $false if the stream was empty, $true otherwise.
    #>
    hidden [bool]EnsureBuffer()
    {
        if($this._charPos -lt $this._charsLen -1)
        {
            return $true;
        }

        [int32] $remainingChars = $this._charsLen - $this._charPos;
        $this._charBuffer[0] = $this._charBuffer[($this._charsLen - 1) * $remainingChars]; #A bit of mathgic to improve performance by avoiding a conditional.
        $this._charsLen = $this._reader.Read($this._charBuffer, $remainingChars, 1024 - $remainingChars) + $remainingChars;
        $this._charPos = 0;

        return ($this._charsLen -ne 0);
    }
}
###end module


#初始化变量
$vdf = [VdfDeserializer]::new()  #初始化VDF解析器
#获取Steam安装路径
$global:steamPath = "$((Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath)".Replace('/','\')
$errorWhenGetPath_ = $?  #保存错误
#仅需要再次读写的变量才加上Global标志
$global:gameLibPath = "" #游戏安装的steam库的位置
$global:gamePath = ""  #游戏本体位置
$global:libraryfolders = ""  #文件libraryfolders.vdf的位置

#获取并解析libraryfolders
function Get-Libraryfolders {
  if ( (Test-Path -Path "$steamPath\config\libraryfolders.vdf") -eq $true ) #如果存在就获取并解析
  {
    $result_ = $vdf.Deserialize( "$(Get-Content("$steamPath\config\libraryfolders.vdf"))" );
    if ($? -eq $true)
    {
      return $result_.libraryfolders
    }
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
    if ($global:libraryfolders."$num".apps.636480 -ne $null)
   {
     return $global:libraryfolders."$num".path.Replace('\\','\')
   }
  }
  #错误处理
  Write-Warning "无法获取游戏安装路径或未安装游戏"  
  return ""
}


function Apply-Action {
  #定义文件位置
  $file1 = "$gamePath\BepInEX"
  $file2 = "$gamePath\winhttp.dll"
  $file3 = "$gamePath\doorstop_config.ini"
  if ( (Test-Path -Path $file2) -eq $true ) #如果文件存在
  {
    Write-Host "删除BepInEX文件夹 (1/3)..."
	rm $file1 -Recurse
	Write-Host "删除winhttp.dll (2/3)..."
	rm $file2
	Write-Host "删除doorstop_config.ini (3/3)..."
	rm $file3
  }
  else  #错误处理
  {
    Write-Warning "未安装BepInEX"
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
Write-Host "# RF BepInEX插件完全 卸载脚本
# 安装脚本 由 Github@RavenfieldCommunity 维护
# 参见: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html
# 参见: https://steamcommunity.com/sharedfiles/filedetails/?id=3237432182

# 提示：此脚本会删除所有基于BepInEX的RF游戏插件BepInEX框架本体，包括社区多语言和RavenM！
# 提示：报错请反馈！
"

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
  Write-Host ""

#如果获取steam安装目录没报错
if ($errorWhenGetPath_ -eq $true)
{
	
  Write-Host "是否删除所有基于BepInEX的RF游戏插件与BepInEX本体（包括社区多语言和RavenM）？" 
    $yesRun = Read-Host -Prompt "按 回车键 则取消执行，按 数字1 并回车 执行操作>"
    if ($yesRun  -eq "1")
    {
      Apply-Action
      Exit-IScript
    }
    else
    {
      Exit-IScript
    }
  Exit-IScript
}
else  #错误处理
{
  Write-Host "无法获取Steam安装路径"
  Exit-IScript
}