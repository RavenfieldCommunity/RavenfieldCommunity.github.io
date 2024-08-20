#RavenMCN��װ�ű�

Write-Host "# RavenM������ڰ� ��װ�ű�
# RavenM���ڰ� �� Ravenfield���ɰ���@Aya ά��
# ��װ�ű� �� Github@RavenfieldCommunity ά��
# �μ�: https://ravenfieldcommunity.github.io/docs/cn/Project/ravenm.html

#��ʾ�����Ѱ�װ�������������°�װ��� => �ȼ��ڸ���
#��ʾ�����صİ�װ�ļ����Զ��ӷ�������ȡ�µĲ��
"

#�������
#��ȡ����·��
$path = (Get-ChildItem Env:appdata).Value
$folderPath = "$path\RavenMCN"
$zipPath = "$folderPath\RavenMCN.zip"
$tempPath = "$folderPath\Temp.zip"
$exePath = "$folderPath\RavenMһ����װ����.exe"

if ( (Test-Path -Path $folderPath)-ne $true) {$result_ = mkdir $folderPath}

#��ӡ����Ŀ¼
Write-Host "����Ŀ¼��$folderPath"

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
    Write-Host "���صİ�װ�ļ�У�鲻ͨ�����뷴������������"
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
    Write-Host "��װ�ļ�У�鲻ͨ�����뷴������������"
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
    Write-Host "��װ�ļ����ػ�Ӧ��ʧ�ܣ������������"
  }
}

function Exit-IScript
{
  $result_ = Read-Host "�����ڿ��Թرմ�����"
}

#������
if ( (Test-Path -Path $zipPath) -eq $true)
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
else
{ 
  MainGet-RavenMCN
  Exit-IScript
}