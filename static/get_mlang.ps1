#RF���������� ���� ��װ�ű�
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
#��ȡ����·��
$appdataPath = (Get-ChildItem Env:appdata).Value
$downloadPath = "$appdataPath\MLangCN"   
$BepDownloadPath = "$downloadPath\Bep.zip"   #BepInEX���ص��ı����ļ�
$ATransDownloadPath = "$downloadPath\ATrans.zip"  #Autotranslator���ص��ı����ļ�

if ( (Test-Path -Path $downloadPath) -ne $true) { $result_ = mkdir $downloadPath } #�������·�����������½�

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

function DownloadAndApply-BepInEX {
  if ( (Test-Path -Path "$gamePath\winhttp.dll") -eq $true )  #����Ѿ���װ������
  {
    Write-Host "�Ѿ���װBepInEX������"
    return $true 
  }
  else
  {
    Write-Host "��������BepInEX (5.4.22 for x64)..." 
    #����session��ʹ��ֱ��api�����ļ�
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
    $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/iMcD41xbcqgf&type=down" `
      -WebSession $session `
      -OutFile $BepDownloadPath `
      -Headers @{
        "authority"="api.leafone.cn"
        "method"="GET"
        "path"="/api/lanzou?url=https://www.lanzouj.com/iMcD41xbcqgf&type=down"
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
      if ($? -eq $true)  #�ޱ����У�鲢��ѹ
      {
        $hash_ = (Get-FileHash $BepDownloadPath -Algorithm SHA256).Hash
        Write-Host "���ص�BepInEX��Hash: $hash_"
        if ($hash_ -eq "4C149960673F0A387BA7C016C837096AB3A41309D9140F88590BB507C59EDA3F") 
        { 
          Expand-Archive -Path $BepDownloadPath -DestinationPath $gamePath -Force  #ǿ�Ƹ���
          if ($_ -eq $null) {
            Write-Host "BepInEX�Ѱ�װ"           
            return $true 
          }
          else { #������
           Write-Warning "BepInEX��װʧ��"
           return $false 
          }
        }
        else #������
        { 
          Write-Warning "���ص�BepInEXУ�鲻ͨ�����뷴������������"
          return $false
        }
      }
      else #������
      {
          Write-Warning "BepInEX����ʧ�ܣ��뷴������������"        
        retrun $false
      }
   }
}

function DownloadAndApply-ATrans {
  if ( (Test-Path -Path "$gamePath\BepInEx\core\XUnity.Common.dll") -eq $true )
  {
    Write-Host "�Ѿ���װXUnity.AutoTranslator������"
    return $true 
  }
  else
  {
    Write-Host "��������XUnity.AutoTranslator (5.3.0)..." 
    Start-Sleep -Seconds 10  #apiֻ��10s����һ�Σ�����̫����
    #����session��ʹ��ֱ��api�����ļ�
    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
    $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
    $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
    $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/iNKGb1xbf8ze&type=down" `
      -WebSession $session `
      -OutFile $ATransDownloadPath `
      -Headers @{
        "authority"="api.leafone.cn"
        "method"="GET"
        "path"="/api/lanzou?url=https://www.lanzouj.com/iNKGb1xbf8ze&type=down"
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
        $hash_ = (Get-FileHash $ATransDownloadPath -Algorithm SHA256).Hash
        Write-Host "���ص�XUnity.AutoTranslator��Hash: $hash_"
        if ($hash_ -eq "E9D2C514408833D516533BCC96E64C246140F6A8579A5BC4591697BB8D16DEE3") 
        { 
          Expand-Archive -Path $ATransDownloadPath -DestinationPath $gamePath -Force
          if ($_ -eq $null) {
            Write-Host "XUnity.AutoTranslator�Ѱ�װ"           
            return $true 
          }
          else {
           Write-Warning "XUnity.AutoTranslator��װʧ��"
           return $false 
          }
        }
        else 
        { 
          Write-Warning "���ص�XUnity.AutoTranslatorУ�鲻ͨ�����������������죬�뷴�����Ժ��������أ��������нű���"
          return $false
        }
      }
      else
      {
          Write-Warning "XUnity.AutoTranslator����ʧ�ܣ��뷴������������"        
        retrun $false
      }
   }
}

function Apply-MLang {
  #�����ļ�λ��
  $file1 = "$gameLibPath\steamapps\workshop\content\636480\3237432182\main_extra-sch.txt"
  $file2 = "$gameLibPath\steamapps\workshop\content\636480\3237432182\main-sch.txt"
  $targetPath = "$gamePath\BepInEX\Translation\en\Text"
  if ( (Test-Path -Path $file1) -eq $true ) #����ļ�����
  {
    Write-Host "�Ѿ����ķ����ļ�"
    if ( (Test-Path -Path $targetPath) -ne $true ) { mkdir $targetPath }  #���Ŀ��Ŀ¼���������½�

    if ($? -eq $true)  #���Ŀ¼�����ɹ�
    {
      #1
      Copy-Item -Path $file1 -Destination $targetPath -Force
      if ($? -ne $true) { Write-Warning "���뷭���ļ� main_extra-sch ʧ��" } else { Write-Host "���뷭���ļ� main_extra-sch �ɹ�" }


      #2
      Copy-Item -Path $file2 -Destination $targetPath -Force
      if ($? -ne $true) {
        Write-Warning "���뷭���ļ� main-sch ʧ��" 
        return $false
      } else  { Write-Host "���뷭���ļ� main-sch �ɹ�" }
      #�ޱ����ִ�е�����
      Write-Host "���뷭���ļ��ɹ�" 
      return $true
    }
    else  #������
    {
      Write-Warning "����Ŀ¼ʧ��"      
    }
  }
  else  #������
  {
    Write-Warning "δ���� �� Steamδ���ط����ļ������أ�Steam�Ƿ��Ѿ�������Steam�ں�̨ʱ�ŻὫ������Ŀ���ص����أ�"
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
Write-Host "# RF���������� �������� ��װ�ű�
# ��װ�ű� �� Github@RavenfieldCommunity ά��
# �μ�: https://ravenfieldcommunity.github.io/docs/cn/Project/mlang.html
# �μ�: https://steamcommunity.com/sharedfiles/filedetails/?id=3237432182

# ��ʾ�����Ѱ�װ��������������°�װ���� => �ȼ��ڸ���
# ��ʾ���κ�Bug����Steam��������ٶ����ɡ�RavenfieldCommunity���
# ��ǰ���°�Ϊ Update 1 (202408301700)
"

#��ӡ����Ŀ¼
Write-Host "����Ŀ¼��$downloadPath"

#�����ȡsteam��װĿ¼û����
if ($errorWhenGetPath_ -eq $true)
{
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
 
  if ( (DownloadAndApply-BepInEX) -ne $true) { Exit-IScript }  #���ʧ�ܾ�exit
  if ( (DownloadAndApply-ATrans) -ne $true) { Exit-IScript }  #���ʧ�ܾ�exit
  $result_ = Apply-MLang  #����Ͳ����ж���
  Exit-IScript
}
else  #������
{
  Write-Host "�޷���ȡSteam��װ·��"
  Exit-IScript
}