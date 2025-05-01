echo "# RavenM Installation script UNIX VERSION"
echo "# RavenM is made by ABigPickle"
echo "# Installation Script is made by Github@RavenfieldCommunity"
echo "# Refer: https://ravenfieldcommunity.github.io/docs/en/Projects/ravenm.html"
echo ""
echo "# Tip：Re-installing => Udpating"
echo ""

PrintWarning(){
  echo -e "\e[33mWARNING: $1\e[0m"
}

ExitScript(){
  echo "Now you can close the terminal"
  read -s
  exit
}

CatchError(){
  echo -e "\e[33mWARNING: $1\e[0m"
  ExitScript
  ExitScript
  read -s
  exit
}

if (( $EUID == 0 )); then
  PrintWarning "This script cannot be run on root access";
  EXitScript
fi

if [ $(uname -m) == "i386" ]; then
  CatchError "32-bit platform is not compatible with this script";
fi

#是否为ARM
isArm=0
elif [ $(uname -m) == "i386" ]; then
  PrintWarning "ARM platform maybe not compatible with this script";
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
bepInEXUrl_win_x64='https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.3/BepInEx_win_x64_5.4.23.3.zip'
bepInEXHash_win_x64='41A089E5B1B1F0713B331346BAF6677B1184C69EABEBF51101097954E854C749'
bepInEXInfo_win_x64='5.4.23.3 for windows x64'
bepInEXUrl_linux_x64='https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.3/BepInEx_linux_x64_5.4.23.3.zip'
bepinEXHash_linux_x64='B9EF28B37676F18277CFD8DDED01F675E934F207C30F65F2A4BB93C7E41ABDBB'
bepInEXInfo_linux_x64='5.4.23.3 for linux x64'
bepInEXUrl_macos_x64='https://github.com/BepInEx/BepInEx/releases/download/v5.4.23.3/BepInEx_macos_x64_5.4.23.3.zip'
bepinEXHash_macos_x64='22A872EFAE6EE658019BD7C25FDB05B361AAD876453A4D7B988790E7259A9088'
bepInEXInfo_macos_x64='5.4.23.3 for macos x64'

#平台判断
if [ $(uname -s) == "Drawin" ]; then
  isMacos=1;
  echo "Runs on Macos"
  PrintWarning  "Maybe buggy, please feedback"
elif [ $(uname -s) == "Linux" ]; then
  isMacos=0;
  echo "Runs on Linux"	 
else 
  CatchError "Unknown platform"
fi
echo "CPU platform: $(uname -m)"
 
#找path
if (( $isMacos == 1 )); then
  cd ~
  homePath=$(pwd)
  gamePath="$homePath/Library/Application Support/Steam/steamapps/common/${gameName}/"
  if test -e $gamePath; then
    :
  else
    CatchError "Cannot find out game path"
  fi
else
  gamePath="$HOME/.steam/steam/steamapps/common/${gameName}/"
  if test -e $gamePath; then
    :
  else
    CatchError "Cannot find out game path"
  fi
fi
echo "Game path: ${gamePath}"


#测试与安装bepinex
if test -e "$gamePath/winhttp.dll"; then
  echo "BepInEX (windows) is installed, skip"
  isBepInEXInstalled=1
  useProton=1
elif test -e "$gamePath/run_bepinex.sh"; then
  echo "BepInEX (unix) is installed, skip"
  isBepInEXInstalled=1
fi

function ApplyBepinEX() {
  #选择方案
  if (( $isBepInEXInstalled != 1 )); then
    echo "Which BepInEX running mode would you want?
  0. Native(include ARM-to-x64)
  1. Using Wine or Proton
Please enter index"
    read -p ":>" useProton
    if (( $useProton != 0 && $useProton != 1)); then
      CatchError "Invaild input"
    fi
  elif
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
  echo "Downloading BepInEX (${fileInfo}) ..."
  #逆天引号
  result=$(curl $targetUrl -o $bepinexDownloadPath -w "%{http_code}" -H 'accept: application/json, text/javascript, */*; q=0.01'  -H 'user-agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36 Edg/135.0.0.0' -H 'accept: application/json, text/javascript, */*; q=0.01' -H 'accept-language: zh-CN,zh;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6' -H 'sec-ch-ua: "Microsoft Edge";v="135", "Not-A.Brand";v="8", "Chromium";v="135"' -H 'sec-ch-ua-platform: "Windows"' -H 'sec-fetch-site: same-origin' -H 'x-requested-with: XMLHttpRequest' -L)
  echo "Return code: $result"
  if (($result != 200)); then
    CatchError "BepInEX download failed";
  fi
  echo "BepInEX downloaded"
	
  #unzip
  unzip -o $bepinexDownloadPath -d $gamePath 
  if (($? != 0)); then
    CatchError "BepInEX install failed" 
  fi
  echo "BepInEX installed"
  
  #配置1
  if (($isMacos == 1)); then
    sed '/executable_name=""/a\executable_name="Ravenfield.app"' "$gamePath/run_bepinex.sh" > "$gamePath/run_bepinex.sh"
  else
    sed '/executable_name=""/a\executable_name="Ravenfield.x86_64"' "$gamePath/run_bepinex.sh" > "$gamePath/run_bepinex.sh"
  fi
  if (($? == 0)); then
    echo "BepInEX configured"
  else 
    PrintWarning "BepInEX configure failed, manual configure maybe needed, please open game directory and follow `https://docs.bepinex.dev/` to check file `run_bepinex.sh`"
  fi
  
  #配置2
  chmox u+x $gamePath/run_bepinex.sh
  if (($? == 0)); then
    echo "BepInEX script access configured"
  else 
    PrintWarning "BepInEX script access configure failed, manual configure maybe needed, please open game directory and follow `https://docs.bepinex.dev/` to configure `run_bepinex.sh` on terminal"
  fi
  
  #arm配置
  if (($isArm == 1)); then
    echo "#!/bin/sh
arch -x86_64 /bin/bash ./run_bepinex.sh" > $gamePath/RUN_ME.sh
    chmox u+x $gamePath/RUN_ME.sh
	if (($? == 0)); then
      echo "BepInEX script for arm access configured"
    else 
      PrintWarning "BepInEX script for arm access configure failed, manual configure maybe needed, please open game directory and follow `https://docs.bepinex.dev/` to configure `run_bepinex.sh` on terminal"
    fi
  fi
}

function ApplyRavenMCN() {
#todo
  fileUrl="https://github.com/iliadsh/RavenM/releases/download/latest/RavenM-v0.7.zip"
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
echo "安装已结束"
if (($isArm == 1)); then
  echo "从游戏目录执行脚本运行 BepInEX, 请执行脚本创建的 `RUN_ME.sh` 而不是 `run_bepinex.sh`"
fi

if (($useProton == 1)); then
  echo "您使用了Windows兼容层, 若要在游戏启动时启用 BepInEX, 请将下行内容添加入游戏启动参数(在 Steam -> `游戏属性`-> `高级启动参数`, 或其他):
WINEDLLOVERRIDES=\"winhttp.dll=n,b\" %command%"
elif (($macos == 1)); then
  if (($isArm == 1)); then
    echo "若要在游戏启动时启用 BepInEX, 请将下行内容添加入游戏启动参数(在 Steam -> `游戏属性`-> `高级启动参数`, 或其他):
\"$gamePath/RUN_ME.sh\" %command%"
  else
  fi
else
  echo "若要在游戏启动时启用 BepInEX, 请将下行内容添加入游戏启动参数(在 Steam -> `游戏属性`-> `高级启动参数`, 或其他):
./run_bepinex.sh %command%
"
fi

ExitScript