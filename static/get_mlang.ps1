#���������� ���� ��װ�ű�

$vdf = [VdfDeserializer]::new()
$steamPath = ""

Write-Host "# ���������� �������� ��װ�ű�
# ��װ�ű� �� Github@RavenfieldCommunity ά��
# �μ�: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html

#��ʾ�����Ѱ�װ�������������°�װ��� => �ȼ��ڸ���
"

$steamPath = "$((Get-ItemProperty HKCU:\Software\Valve\Steam).SteamPath)".Replace('/','\')
if ($_ -eq $null)
{
  Write-Host "Steam��װ·����$steamInstallPath"
  Analyic-LibFolder
}
else
{
  Write-Host "�Ҳ���Steam"
}

function Analyic-LibFolder {
  if ( (Test-Path -Path "E:\program\steam\steamapps\libraryfolders.vdf") -eq $true )
  {
    return $vdf.Deserialize( "$(Get-Content("E:\Program\Steam\steamapps\libraryfolders.vdf"))" );
  }
}

function Exit-IScpipt {
  
}





































#�������
#��ȡ����·��
$path = (Get-ChildItem Env:appdata).Value
$folderPath = "$path\RavenMCN"
$zipPath = "$folderPath\RavenMCN.zip"
$tempPath = "$folderPath\Temp.zip"
$exePath = "$folderPath\RavenMһ����װ����.exe"

if ( (Test-Path -Path $folderPath) -eq $true) {}
else {$result_ = mkdir $folderPath}

#��ӡ����Ŀ¼
#Write-Host "����Ŀ¼��$folderPath"

#���庯��
function Download-RavenMCN {
  Write-Host "���������ļ�..." 
  #����session��ʹ��ֱ��api�����ļ�
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
  $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/ih1aS1z0ofne&type=down" `
    -WebSession $session `
    -OutFile $tempPath `
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
  #У��hash
  $hash = (Get-FileHash $tempPath -Algorithm SHA256).Hash
  Write-Host "���صİ�װ�ļ���Hash: $hash"
  if ($hash -eq "946539FC1FF3B99D148190AD04435FAF9CBDD7706DBE8159528B91D7ED556F78") 
  { 
    Copy-Item -Path $tempPath -Destination $zipPath
    if ($_ -eq $null) { return $true }
    else { return $false }
  }
  else 
  { 
    Write-Host "���صİ�װ�ļ�У�鲻ͨ�����뷴���������������������"
    return $false
  }
}

function CheckAndRunLocal-RavenMCN {
  #У��hash
  $hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash
  Write-Host "��װ�ļ�Hash: $hash"
  if ($hash -eq "946539FC1FF3B99D148190AD04435FAF9CBDD7706DBE8159528B91D7ED556F78") 
  { 
    #��ѹ
    Write-Host "���������ļ�..."
    Expand-Archive $zipPath -DestinationPath $folderPath -Force
    #����   
    if ($_ -eq $null) { Start-Process $exePath } else { return $false }
    Write-Host "��ʾ�����а�װ�ļ�����Ҫ����ԱȨ��"
    $result_ = Read-Host -Prompt "��ȴ���װ���߳���ʱ�ٹرձ�����"
    return $true
  }
  else 
  { 
    Write-Host "��װ�ļ�У�鲻ͨ�����뷴���������������������"
    UpdateLocal-RavenMCN
    return $false
  }
}

function UpdateLocal-RavenMCN {
  Write-Host "�������ذ�װ�ļ����´�����ʱ��Ч..."
  Download-RavenMCN
}

function MainGet-RavenMCN {
  if (Download-RavenMCN -eq $true)
  {
    Write-Host "��װ�ļ����ز�Ӧ�óɹ�"
    $result_ = CheckAndRunLocal-RavenMCN
  }
  else
  {
    Write-Host "��װ�ļ����ػ�Ӧ��ʧ�ܣ����������������������"
  }
}

function Exit-IScript
{
  $result_ = Read-Host "�����ڿ��Թرմ�����"
}

#������
if ( (Test-Path -Path $zipPath) -eq $false)
{
  Write-Host "���ش��ڰ�װ�ļ����Ƿ�ֱ�����У�" 
  $yesRun = Read-Host -Prompt "�� �س��� ��ֱ�����б��ذ�װ�ļ����� ��������س� ����������>"
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
elseif ($false)
{ 
  MainGet-RavenMCN
  Exit-IScript
}




###start of module
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

###end of module