#RF HavenM 安装脚本
#感谢: BartJolling/ps-steam-cmd
#感谢: api.leafone.cn

#初始化依赖lib
$w=(New-Object System.Net.WebClient);
$w.Encoding=[System.Text.Encoding]::UTF8;
try { iex($w.DownloadString('http://ravenfieldcommunity.github.io/static/corelib-utf8.ps1')); }
catch { 
    iex($w.DownloadString('http://ghproxy.net/https://raw.githubusercontent.com/ravenfieldcommunity/ravenfieldcommunity.github.io/main/static/corelib-utf8.ps1')); 
	if ($? -eq $true)
	{
		Write-Warning "Connot init corelib";
		Exit-IScript;
	}
}