#RF BepInEXж�ع���
#��л: BartJolling/ps-steam-cmd
#��л: api.leafone.cn

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


#��ʼ������
$vdf = [VdfDeserializer]::new()  #��ʼ��VDF������
#��ȡSteam��װ·��
$global:steamPath = "$((Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath)".Replace('/','\')
$errorWhenGetPath_ = $?  #�������
#����Ҫ�ٴζ�д�ı����ż���Global��־
$global:gameLibPath = "" #��Ϸ��װ��steam���λ��
$global:gamePath = ""  #��Ϸ����λ��
$global:libraryfolders = ""  #�ļ�libraryfolders.vdf��λ��

#��ȡ������libraryfolders
function Get-Libraryfolders {
  if ( (Test-Path -Path "$steamPath\config\libraryfolders.vdf") -eq $true ) #������ھͻ�ȡ������
  {
    $result_ = $vdf.Deserialize( "$(Get-Content("$steamPath\config\libraryfolders.vdf"))" );
    if ($? -eq $true)
    {
      return $result_.libraryfolders
    }
    else  #������
    {
      Write-Warning "�޷���ȡLibraryfolders"
      return ""
    }
  }
  else  #������
  {
    Write-Warning "�޷���ȡLibraryfolders"
    return ""
  }
}

#ͨ��������libraryfolders��ȡ��Ϸ��װ�Ŀ�λ��
function Get-GamePath {
  $lowCount = ($global:libraryfolders | Get-Member -MemberType NoteProperty).Count - 1
  $count = 0..$lowCount
  foreach ($num in $count)  #�ֶ��ݹ�
  {
    if ($global:libraryfolders."$num".apps.636480 -ne $null)
   {
     return $global:libraryfolders."$num".path.Replace('\\','\')
   }
  }
  #������
  Write-Warning "�޷���ȡ��Ϸ��װ·����δ��װ��Ϸ"  
  return ""
}


function Apply-Action {
  #�����ļ�λ��
  $file1 = "$gamePath\BepInEX"
  $file2 = "$gamePath\winhttp.dll"
  $file3 = "$gamePath\doorstop_config.ini"
  if ( (Test-Path -Path $file2) -eq $true ) #����ļ�����
  {
    Write-Host "ɾ��BepInEX�ļ��� (1/3)..."
	rm $file1 -Recurse
	Write-Host "ɾ��winhttp.dll (2/3)..."
	rm $file2
	Write-Host "ɾ��doorstop_config.ini (3/3)..."
	rm $file3
  }
  else  #������
  {
    Write-Warning "δ��װBepInEX"
    return $false
  }
}

#�˳��ű��ݹ�
function Exit-IScript {
  Read-Host "�����ڿ��Թرմ�����"
  Exit
  Exit-IScript
}	


###������
Write-Host "# RF BepInEX�����ȫ ж�ؽű�
# ��װ�ű� �� Github@RavenfieldCommunity ά��
# �μ�: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html
# �μ�: https://steamcommunity.com/sharedfiles/filedetails/?id=3237432182

# ��ʾ���˽ű���ɾ�����л���BepInEX��RF��Ϸ���BepInEX��ܱ��壬�������������Ժ�RavenM��
# ��ʾ�������뷴����
"

Write-Host "Steam��װ·����$($global:steamPath)"

  #��ȡlibraryfolders
  $global:libraryfolders = Get-Libraryfolders
  if ($global:libraryfolders -eq ""){ Exit-IScript }

  #��ȡ��Ϸ��λ��
  $global:gameLibPath = Get-GamePath
  if ($global:gameLibPath -eq ""){ Exit-IScript }
  Write-Host "��Ϸ����Steam��·����$($global:gameLibPath)"

  #������Ϸ��װλ��
  $global:gamePath = "$($global:gameLibPath)\steamapps\common\Ravenfield"
  Write-Host "��Ϸ���ڰ�װ·����$($global:gamePath)"
  Write-Host ""

#�����ȡsteam��װĿ¼û����
if ($errorWhenGetPath_ -eq $true)
{
	
  Write-Host "�Ƿ�ɾ�����л���BepInEX��RF��Ϸ�����BepInEX���壨�������������Ժ�RavenM����" 
    $yesRun = Read-Host -Prompt "�� �س��� ��ȡ��ִ�У��� ����1 ���س� ִ�в���>"
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
else  #������
{
  Write-Host "�޷���ȡSteam��װ·��"
  Exit-IScript
}