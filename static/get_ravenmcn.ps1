#RavenMCN��װ�ű�

Out-String -InputObject "# RavenM���ڰ氲װ�ű�
# ��RavenfieldCommunityά��"

#����session��ʹ��ֱ��api�����ļ�
Try {
  $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
  $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
  $session.Cookies.Add((New-Object System.Net.Cookie("PHPSESSID", "", "/", "api.leafone.cn")))
  $session.Cookies.Add((New-Object System.Net.Cookie("notice", "1", "/", "api.leafone.cn")))
  Invoke-WebRequest -UseBasicParsing -Uri "https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/ih1aS1z0ofne&type=down" `
    -WebSession $session `
    -OutFile .\RavenMCN.zip `
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
}
Catch 
{ 
  Out-String -InputObject "��װ�ļ�����ʧ�ܣ����������������������"
  Read-Host -prompt " " 
  Read-Host -prompt " "
  exit 1
}

Out-String -InputObject "��װ�ļ����سɹ�"

#У��hash
$hash1 = Get-FileHash .\RavenMCN.zip -Algorithm SHA256
$hash2 = $hash1.Hash
Out-String -InputObject "��װ�ļ�Hash: $hash2"
if ($hash2 -eq "946539FC1FF3B99D148190AD04435FAF9CBDD7706DBE8159528B91D7ED556F78") 
{ 
  #��ѹ
  Out-String -InputObject "���������ļ�..."
  Expand-Archive .\RavenMCN.zip -Force
  #����
  & .\RavenMCN\RavenMһ����װ����.exe 
  Read-Host -prompt " "
  Read-Host -prompt " "
}
else 
{ 
  Out-String -InputObject "��װ�ļ�У�鲻ͨ�����뷴������������"
  Read-Host -prompt " " 
  Read-Host -prompt " "
}
