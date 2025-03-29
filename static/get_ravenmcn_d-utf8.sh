echo "# RavenM 联机插件国内版 直接安装版脚本 UNIX专供"
echo "# RavenM国内版 由 Ravenfield贴吧吧主@Aya 维护"
echo "# 安装脚本 由 Github@RavenfieldCommunity 维护"
echo "# 参见: https://ravenfieldcommunity.github.io/docs/cn/Projects/ravenm.html"
echo ""
echo "# 提示：在已安装插件的情况下重新安装插件 => 等价于更新"
echo "# 提示：脚本不适用Windows, 运行脚本需要先安装Python3! 参见: https://liaoxuefeng.com/books/python/install/index.html"
echo ""

[ "$EUID" -eq 0 ] && { echo "\033[33m警告: 此脚本不能以root身份运行\033[0m"; exit 1; }
[ "$get_arch" == "aarch64" ] && { echo "\033[33m警告: ARM架构可能不兼容此插件!\033[0m"; }

python3 -c "import sys
import os
import zipfile
import urllib
import hashlib
import urllib.request
import json

#预定义变量
isMacos = False #是否为macos
tempPath = '/tmp/RavenfieldCommunityCN/' #临时目录
#下载文件路径
bepInEXDownlaodPath = tempPath + 'BepInEx.zip'
ravenmCNDownlaodPath = tempPath + 'RavenMCN.zip'
ravenmCNUrl = 'https://gitee.com/api/v5/repos/RedQieMei/Raven-M/releases/372833' #gitee链接
#bepinex信息
bepInEXUrlID = 'iMcD41xbcqgf'
bepInEXInfo = '5.4.22 for x64'
bepInEXHash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' #要在hashlib算

#获取steamapps目录
def GetSteamAppsPath():
    if (isMacos):
        #逆天路径
        return '%s/Library/Application Support/Steam/SteamApps/' %(os.path.expanduser('~'))
    else:
        return '%s/.steam/steam/steamapps/' %(os.path.expanduser('~'))

#获取游戏目录
def GetGamePath():
    return GetSteamAppsPath() + 'common/Ravenfield/'

#打印警告
def PrintWarning(text):
    print('\033[33m警告: ' + text + '\033[0m')

#退出脚本func
def QuitScript():
    quit()

#安装bepinex
def ApplyBepInEX():
    #已安装测试
    if ( os.path.exists(GetGamePath() + 'winhttp.dll') ):
        print('已经安装 BepInEX, 跳过')
        return
    header = { #header
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
    print('正在下载 BepInEX (%s) ...' %(bepInEXInfo))
    #下载
    request1 = urllib.request.Request('https://api.leafone.cn/api/lanzou?url=https://www.lanzouj.com/%s&type=down' %(bepInEXUrlID),headers=header)
    response1 = urllib.request.urlopen(request1)
    #写入
    file = open(bepInEXDownlaodPath, 'bw+')
    file.write(response1.read())
    #校验hash
    hashObject = hashlib.sha256()
    while True:
        if file.read(4096):
            hashObject.update(content)
        else:
            break
    file.close()
    #解压
    print('BepInEX 已下载')
    print('下载的 BepInEX 的Hash: %s' %(hashObject.hexdigest()) )
    if (hashObject.hexdigest() == bepInEXHash):
        #解压
        zipFile = zipfile.ZipFile(bepInEXDownlaodPath)
        zipFile.extractall(GetGamePath())
        print('BepInEX 已安装')
    else:
        print('下载的 BepInEX 校验不通过, 请反馈或重新下载或向服务器请求过快, 请反馈或稍后重新下载(重新运行脚本), 或更换网络环境')
        QuitScript()



def ApplyRavenMCN():
    header = {
        'User-Agent':'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0',
        'Cookie':'user_locale=zh-CN; oschina_new_user=false; remote_way=http; sensorsdata2015jssdkchannel=7;'
    }
    request1 = urllib.request.Request(ravenmCNUrl,headers=header)
    response1 = urllib.request.urlopen(request1)
    response1Json = json.loads(response1.read().decode())
    print('正在下载 RavenMCN (%s) ...' %(response1Json['name']) )
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
    print('RavenMCN 已下载')
    zipFile = zipfile.ZipFile(ravenmCNDownlaodPath)
    zipFile.extractall(GetGamePath() + 'BepInEx/plugins/')
    print('RavenMCN 已安装')


###main program
##系统检测
if sys.platform == 'darwin':
    print('本机为 Mac 平台')
    PrintWarning('Mac平台可能无法正常运行此脚本, 任何问题请反馈!')
    isMacos = True
elif sys.platform == 'linux':
    print('本机为 Linux 平台')
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
if ( not os.path.exists(tempPath) ): #创建下载目录
    os.mkdir(tempPath)
print('下载目录: ' + tempPath)
#安装
ApplyBepInEX()
ApplyRavenMCN()
#最后步骤
print('''
已将所需文件安装到本地, 由于Steam的限制, 您仍需要进行以下操作 (参见: https://ravenfieldcommunity.github.io/docs/cn/Projects/mlang#启用Proton.html):
  1. Steam启用Proton
  2. 为RF强制启用Proton
  3. 给RF添加启动参数: WINEDLLOVERRIDES=\"winhttp.dll=n,b\" %command%
''')
QuitScript()
"

echo '您现在可以退出脚本或关闭Shell了'
read -s
