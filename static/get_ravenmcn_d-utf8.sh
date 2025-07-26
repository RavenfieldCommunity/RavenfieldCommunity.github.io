echo "# RavenM 联机插件国内版 直接安装版脚本 UNIX专供"
echo "# RavenM国内版 由 Ravenfield贴吧@Aya 维护"
echo "# 安装脚本 由 Github@RavenfieldCommunity 维护"
echo "# 参见: https://ravenfieldcommunity.github.io/docs/cn/Projects/ravenm.html"
echo ""
echo "# 提示：在已安装插件的情况下重新安装插件 => 等价于更新"
echo ""

PrintWarning(){
  echo -e "\e[33m警告: $1\e[0m"
}

ExitScript(){
  echo "您现在可以关闭终端了"
  read -s
  exit
}

CatchError(){
  echo -e "\e[33m警告: $1\e[0m"
  ExitScript
  ExitScript
  read -s
  exit
}

if (( $EUID == 0 )); then
  PrintWarning "此脚本不能以root身份运行";
  EXitScript
fi

if [ $(uname -m) == "i386" ]; then
  CatchError "32位架构不兼容此安装脚本";
fi

#是否为ARM
isArm=0
if [ $(uname -m) == "i386" ]; then
  PrintWarning "ARM架构可能不兼容插件框架";
  isArm=1
fi

#创建临时目录
tempPath='/tmp/RavenfieldCommunityCN' 
mkdir $tempPath

#是否为macos, 是否使用兼容层, BepInEX是否已安装的bool
isMacos=0
useProton=0
isBepInEXInstalled=0

#基本变量与初始化
gamePath=""
gameName="Ravenfield"
bepinexDownloadPath="$tempPath/BepInEx.zip"
ravenmCNDownlaodPath="$tempPath/RavenMCN.zip"
#bepinex信息
bepInEXUrl_win_x64='https://ghproxy.net/https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.3/BepInEx_win_x64_5.4.23.3.zip'
bepInEXHash_win_x64='41A089E5B1B1F0713B331346BAF6677B1184C69EABEBF51101097954E854C749'
bepInEXInfo_win_x64='5.4.23.3 for windows x64'
bepInEXUrl_linux_x64='https://ghproxy.net/https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.3/BepInEx_linux_x64_5.4.23.3.zip'
bepinEXHash_linux_x64='B9EF28B37676F18277CFD8DDED01F675E934F207C30F65F2A4BB93C7E41ABDBB'
bepInEXInfo_linux_x64='5.4.23.3 for linux x64'
bepInEXUrl_macos_x64='https://ghproxy.net/https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.3/BepInEx_macos_x64_5.4.23.3.zip'
bepinEXHash_macos_x64='22A872EFAE6EE658019BD7C25FDB05B361AAD876453A4D7B988790E7259A9088'
bepInEXInfo_macos_x64='5.4.23.3 for macos x64'

#平台判断
if [ $(uname -s) == "Drawin" ]; then
  isMacos=1;
  echo "本机为 Mac 平台"
  PrintWarning "Mac 平台可能会有未知bug, 请及时报告"	 
elif [ $(uname -s) == "Linux" ]; then
  isMacos=0;
  echo "本机为 Linux 平台"	 
else 
  CatchError "未知平台, 操作终止"
fi
echo "本机CPU架构为 $(uname -m)"
 
#找path
if (( $isMacos == 1 )); then
  cd ~
  homePath=$(pwd)
  gamePath="$homePath/Library/Application Support/Steam/steamapps/common/${gameName}/"
  if test -e $gamePath; then
    :
  else
    CatchError "找不到游戏路径"
  fi
else
  gamePath="$HOME/.steam/steam/steamapps/common/${gameName}/"
  if test -e $gamePath; then
    echo ""
  else
    CatchError "找不到游戏路径"
  fi
fi
echo "游戏路径: ${gamePath}"

#测试与安装bepinex
if test -e "$gamePath/winhttp.dll"; then
  echo "已经安装BepInEX (windows), 跳过"
  isBepInEXInstalled=1
  useProton=1
elif test -e "$gamePath/run_bepinex.sh"; then
  echo "已经安装BepInEX (unix), 跳过"
  isBepInEXInstalled=1
fi

function ApplyBepinEX() {
  #选择方案
  if (( $isBepInEXInstalled != 1 )); then
    echo "您想使用哪一种 BepInEX 运行模式?
  0. 原生运行(包括MacOS ARM跑x64)
  1. 使用类似Wine的Windows兼容层
请输入序号"
    read -p ":>" useProton
    if (( $useProton != 0 && $useProton != 1)); then
      CatchError "无效输入"
    fi
  else
    return;
  fi

  #定义目标信息
  targetUrl=""
  fileInfo=""
  fileHash=""
  if (($useProton == 1)); then
    targetUrl=$bepInEXUrl_win_x64
    fileInfo=$bepInEXInfo_win_x64
    fileHash=$bepinEXHash_win_x64
  elif (($isMacos == 1)); then
    targetUrl=$bepInEXUrl_macos_x64
    fileInfo=$bepInEXInfo_macos_x64
    fileHash=$bepinEXHash_macos_x64
  else
    targetUrl=$bepInEXUrl_linux_x64
    fileInfo=$bepInEXInfo_linux_x64
    fileHash=$bepinEXHash_linux_x64
  fi
  
  #下载
  echo "正在下载正在下载 BepInEX (${fileInfo}) ..."
  #逆天引号
  result=$(curl $targetUrl -o $bepinexDownloadPath -w "%{http_code}" -H 'accept: application/json, text/javascript, */*; q=0.01'  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0' -H 'accept: application/json, text/javascript, */*; q=0.01' -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' -H 'sec-ch-ua: "Microsoft Edge";v="135", "Not-A.Brand";v="8", "Chromium";v="135"' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: same-origin' -H 'x-requested-with: XMLHttpRequest' -L)
  echo "服务器返回码: $result"
  if (($result != 200)); then
    CatchError "BepInEX 下载失败, 请反馈或稍后重试";
  fi
	
  #校验
  echo "BepInEX 已下载"
  if (($isMacos == 0)); then
    echo $fileHash $bepinexDownloadPath | sha256sum -c --strict --quiet
  else
    echo $fileHash $bepinexDownloadPath > hash.txt
	shasum -a 256 hash.txt -c -s 
  fi
  if (($? != 0)); then
   CatchError "BepInEX 校验不通过, 请反馈或稍后重试"
  fi
	
  #unzip
  echo "BepInEX 校验通过"
  unzip -o $bepinexDownloadPath -d $gamePath 
  if (($? != 0)); then
    CatchError "BepInEX 安装失败" 
  fi
  echo "BepInEX 已安装"
  
  #配置1
  mv $gamePath/run_bepinex.sh $gamePath/run_bepinex.sh.txt
  if (($isMacos == 1)); then
    sed '/executable_name=""/a\executable_name="Ravenfield.app"' $gamePath/run_bepinex.sh.txt > $gamePath/run_bepinex.sh
  else
    sed '/executable_name=""/a\executable_name="Ravenfield.x86_64"' $gamePath/run_bepinex.sh.txt > $gamePath/run_bepinex.sh
  fi
  if (($? == 0)); then
    echo "BepInEX 已配置"
  else 
    PrintWarning "BepInEX 配置失败, 可能需要手动配置, 请打开游戏目录并依据 https://docs.bepinex.dev/ 检查 run_bepinex.sh 文件"
  fi
  
  #配置2
  chmod u+x $gamePath/run_bepinex.sh
  if (($? == 0)); then
    echo "BepInEX执行脚本 已配置启动权限"
  else 
    PrintWarning "BepInEX执行脚本 启动权限配置失败, 可能需要手动配置, 请打开游戏目录并依据 https://docs.bepinex.dev 在终端配置 run_bepinex.sh "
  fi
  
  #arm配置
  if (($isArm == 1)); then
    echo "#!/bin/sh
arch -x86_64 /bin/bash '$gamePath/run_bepinex.sh'" > $gamePath/RUN_ME.sh
    chmod u+x $gamePath/RUN_ME.sh
	if (($? == 0)); then
      echo "BepInEX ARM平台执行脚本 已配置启动权限"
    else 
      PrintWarning "BepInEX执行ARM平台脚本 启动权限配置失败, 可能需要手动配置, 请打开游戏目录并依据 https://docs.bepinex.dev/ 在终端配置 RUN_ME.sh "
    fi
  fi
}

function ApplyRavenMCN() {
  #fetch信息
  json=$(curl 'https://gitee.com/api/v5/repos/RedQieMei/Raven-M/releases/372833' -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' -H 'Connection: keep-alive' -H 'Sec-Fetch-Dest: document' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0' -H 'sec-ch-ua: "Microsoft Edge";v="135", "Not-A.Brand";v="8", "Chromium";v="135"')
  if (($? != 0)); then
    CatchError "获取 RavenMCN 信息时出错, 请反馈或稍后重试"
  fi
  
  #打印ver
  versionName=$(echo $json | grep -o -P '(?<=se,"name":").*?(?=")' - )
  echo "正在下载 RavenMCN (${versionName}) ..."
  
  #取id并下载
  preefileStr=$(echo $json | grep -o -P '(?<=https://gitee.com/RedQieMei/Raven-M/releases/download/).*?(?=.zip)' - )
  preefileUrl="https://gitee.com/RedQieMei/Raven-M/releases/download/${preefileStr}.zip"
  prefileUrl=$(curl $preefileUrl | grep -o -P '(?<=href\=").*?(?=">r)' - )
  fileId=$(echo $prefileUrl | grep -o -P '(?<=_files/).*?(?=/)' - )
  fileUrl="https://gitee.com/api/v5/repos/RedQieMei/Raven-M/releases/372833/attach_files/$fileId/download"
  result=$(curl -L --max-redirs 5 $fileUrl -o $ravenmCNDownlaodPath  -w "%{http_code}" -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7' -H 'Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' -H 'Connection: keep-alive' -H 'Sec-Fetch-Dest: document' -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0' -H 'sec-ch-ua: "Microsoft Edge";v="135", "Not-A.Brand";v="8", "Chromium";v="135"')
  echo "服务器返回码: $result"
  if (($result != 200)); then
    CatchError "RavenMCN 下载失败, 请反馈或稍后重试"
  fi
  
  #unzip
  unzip -o $ravenmCNDownlaodPath -d "$gamePath/BepInEx/plugins" 
  if (($? != 0)); then
    CatchError "RavenMCN 安装失败"
  fi  
  echo "RavenMCN 安装成功"
}
  
ApplyBepinEX
ApplyRavenMCN

#最后步骤
echo "安装已结束 (以下步骤若已经执行过请忽略)"
if (($isArm == 1)); then
  echo "从游戏目录执行脚本运行 BepInEX, 请执行脚本创建的 `RUN_ME.sh` 而不是 `run_bepinex.sh`"
fi

if (($useProton == 1)); then
  echo "您使用了Windows兼容层, 若要在游戏启动时启用 BepInEX, 请将下行内容添加入游戏启动参数(在 Steam -> 游戏属性 -> 高级启动参数, 或其他):
WINEDLLOVERRIDES=\"winhttp.dll=n,b\" %command%"
elif (($isMacos == 1)); then
  if (($isArm == 1)); then
    echo "若要在游戏启动时启用 BepInEX, 请将下行内容添加入游戏启动参数(在 Steam -> 游戏属性 -> 高级启动参数, 或其他):
\"$gamePath/RUN_ME.sh\" %command%"
  fi
else
  echo "若要在游戏启动时启用 BepInEX, 请将下行内容添加入游戏启动参数(在 Steam -> 游戏属性 -> 高级启动参数, 或其他):
./run_bepinex.sh %command%
"
fi

ExitScript