#RavenMCN��װ�ű�

Out-String -InputObject "# RavenM���ڰ氲װ�ű�
# ��RavenfieldCommunityά��"

#�������
$isOldFileExist = $false

#��ȡ����·��
$envVar = Get-ChildItem Env:appdata
$path = $envVar.Value
$folderPath = $path + "\RavenmCN"
$zipPath = $folderPath + "\RavenMCN.zip"
$exePath = $folderPath + "\RavenMһ����װ����.exe"

$isPathExist = Test-Path -Path $folderPath
if ($isPathExist -eq $true) {}
else {$result_ = mkdir $folderPath}

$isOldFileExist = Test-Path -Path $zipPath

#��ӡ����Ŀ¼
$tipText = "����Ŀ¼��" + $folderPath
Out-String -InputObject $tipText

#���庯��
function Download-RavenMCN {
  Out-String -InputObject "���������ļ�..." 
  #����session��ʹ��ֱ��api�����ļ�
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
  $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
  $request_ = Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/ih1aS1z0ofne&type=down" `
    -WebSession $session `
    -OutFile $zipPath `
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
    if ($_ -eq $null) {} else { Write-Warning $_ }
}

function CheckAndRun-RavenMCN {
  #У��hash
  $hash1 = Get-FileHash $zipPath -Algorithm SHA256
  $hash2 = $hash1.Hash
  Out-String -InputObject "��װ�ļ�Hash: $hash2"
  if ($hash2 -eq "946539FC1FF3B99D148190AD04435FAF9CBDD7706DBE8159528B91D7ED556F78") 
  { 
    Run-RavenMCN
  }
  else 
  { 
    Out-String -InputObject "��װ�ļ�У�鲻ͨ�����뷴���������������������"
    Read-Host -prompt "�����ڿ��Թرմ�����" 
  }
}

function Run-RavenMCN {
  #��ѹ
  Out-String -InputObject "���������ļ�..."
  Expand-Archive $zipPath -DestinationPath $folderPath -Force
  #����   
  Start-Process $exePath
  Out-String -InputObject "ע�⣬���а�װ�ļ�����Ҫ����ԱȨ��"
  Read-Host -prompt "���ֶ���װ��RavenM���ٹرձ�����"
  Read-Host -prompt "���ֶ���װ��RavenM���ٹرձ�����"
}

function MainGet-RavenMCN {
  Download-RavenMCN
  $result_ = Test-Path -Path $zipPath
  if ($result_ -eq $true)
  {
    CheckAndRun-RavenMCN
  }
  else
  {
    Out-String -InputObject "��װ�ļ�����ʧ�ܣ����������������������"
    Read-Host -prompt "�����ڿ��Թرմ�����"
  }
}


#������
if ($isOldFileExist -eq $true)
{
  Out-String -InputObject "���ش��ڰ�װ�ļ����Ƿ�ֱ�����У�" 
  $yesRun = Read-Host -Prompt "��������'1'�������������ذ�װ�ļ�"
  Out-String -InputObject "" 
  if ($yesRun  -eq "1")
  {
    CheckAndRun-RavenMCN
  }
  else { MainGet-RavenMCN }
}
else { MainGet-RavenMCN }