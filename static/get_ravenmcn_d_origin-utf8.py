import sys
import os
import zipfile
import urllib
import hashlib
import urllib.request
import json

#预定义变量
isMacos = False #是否为macos
tempPath = '/tmp/RavenfieldCommunity/'
bepInEXDownlaodPath = tempPath + 'BepInEX.zip'
ravenmCNDownlaodPath = tempPath + 'RavenMCN.zip'
ravenmCNUrl = 'https://gitee.com/api/v5/repos/RedQieMei/Raven-M/releases/372833'
bepInEXUrlID = 'iMcD41xbcqgf'
bepInEXInfo = '5.4.22 for x64'
bepInEXHash = '4C149960673F0A387BA7C016C837096AB3A41309D9140F88590BB507C59EDA3F'

def GetSteamAppsPath():
    if (isMacos):
        return '~/Library/Application Support/Steam/SteamApps/'
    else:
        return '~/.steam/steam/steamapps/'
        

def GetGamePath():
    return GetSteamAppsPath() + 'common/Ravenfield/'
	
def PrintWarning(text):
    print('\033[33m警告: ' + text + '\033[0m')
	
def QuitScript():
    input('您现在可以退出脚本或关闭Shell了')
    quit()

def ApplyBepInEX():
    if ( os.path.exists(GetGamePath() + 'winhttp.dll') ):
        print('已经安装BepInEX, 跳过')
        return
    header = {
        'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0',
        'authority':'api.leafone.cn',
        'method':'GET',
        'path':'/api/lanzou?url=https://www.lanzouj.com/%s&type=down' %(bepInEXUrlID),
        'scheme':'https',
        'accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'accept-encoding':'gzip, deflate, br, zstd',
        'accept-language':'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
        'priority':'u=0, i',
        'sec-ch-ua':'\'Microsoft Edge\';v=\'125\', \'Chromium\';v=\'125\', \'Not.A/Brand\';v=\'24\'',
        'sec-ch-ua-mobile':'?0',
        'sec-ch-ua-platform':'\'Windows\'',
        'sec-fetch-dest':'document',
        'sec-fetch-mode':'navigate',
        'sec-fetch-site':'none',
        'sec-fetch-user':'?1',
        'upgrade-insecure-requests':'1',
        'Cookie':'PHPSESSID=api.leafone.cn'
    }
    print('正在下载BepInEX (%s)...' %(bepInEXInfo))
    request = urllib.request.Request('https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/%s&type=down' %(bepInEXUrlID),headers=header)
    response = urllib.request.urlopen(request)
    file = open(bepInEXDownlaodPath, 'wb')
    file.write(response.read())
    hashObject = hashlib.sha256()
    while chunk := file.read(8192):
        hashObject.update(chunk)
    file.close()
    print('BepInEX已下载')
    print('下载的BepInEX的Hash: %s' %(hashObject.hexdigest()) )
    if (hashObject.hexdigest() == bepInEXHash):
        zipFile = zipfile.ZipFile(bepInEXDownlaodPath)
        zipFile.extractall(GetGamePath())
        print('BepInEX已安装')
    else:
        print('下载的BepInEX校验不通过, 请反馈或重新下载或向服务器请求过快, 请反馈或稍后重新下载(重新运行脚本), 或更换网络环境')


	
def ApplyRavenMCN():
    header = {
        'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0',
        'Cookie':'user_locale=zh-CN; oschina_new_user=false; remote_way=http; sensorsdata2015jssdkchannel=7;' 
    }
    request1 = urllib.request.Request(ravenmCNUrl,headers=header)
    response1 = urllib.request.urlopen(request1)
    response1Json = json.loads(response1.read().decode())
    print('正在下载RavenMCN (%s)...' %(response1Json['body']) )
    header = {
        'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/195.0.0.0 Safari/537.36 Edg/175.0.0.0',
        'method':'GET',
        'accept':'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'accept-encoding':'gzip, deflate, br, zstd',
        'accept-language':'zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6',
        'priority':'u=0, i',
        'sec-ch-ua':'\'Microsoft Edge\';v=\'195\', \'Chromium\';v=\'175\', \'Not.A/Brand\';v=\'24\'',
        'sec-ch-ua-mobile':'?0',
        'sec-ch-ua-platform':'\'Windows\'',
        'sec-fetch-dest':'document',
        'sec-fetch-mode':'navigate',
        'sec-fetch-site':'none',
        'sec-fetch-user':'?1',
        'upgrade-insecure-requests':'1',
        'Cookie':'PHPSESSID=api.leafone.cn',
        'Content-Type':'application/zip'
    }
    request2 = urllib.request.Request(response1Json['assets'][0]['browser_download_url'],headers=header)
    response2 = urllib.request.urlopen(request2)
    file = open(ravenmCNDownlaodPath, 'wb')
    file.write(response2.read())
    file.close()
    print('RavenMCN已下载')
    zipFile = zipfile.ZipFile(bepInEXDownlaodPath)
    zipFile.extractall(GetGamePath() + 'BepInEX/plugins/')
    print('RavenMCN已安装')


###main program
##系统检测
if sys.platform == 'darwin':
    print('本机为 Mac平台')
    isMacos = True
elif sys.platform == 'linux':
    print('本机为 Linux平台')
    isMacos = False
else:
    PrintWarning('未知平台, 无法继续安装')
    QuitScript()

##steam检查
if ( os.path.exists(GetGamePath()) ):
    print('游戏所在安装路径: ' + GetGamePath())
else:
    PrintWarning('无法获取游戏安装路径或未安装游戏或Steam')
    QuitScript()

##安装
ApplyBepInEX()
ApplyRavenMCN()
print('')
print('''已将将所需文件部署到本地，由于Steam的限制您仍需要进行以下操作 (参见: https://ravenfieldcommunity.github.io/docs/cn/Projects/mlang#启用Proton.html):
  1. Steam启用Proton
  2. 为RF强制启用Proton
  3. 给RF添加启动参数: WINEDLLOVERRIDES=\"winhttp.dll=n,b\" %command%
''')
QuitScript()
