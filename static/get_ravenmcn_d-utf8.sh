echo "# RavenM 联机插件国内版 直接安装版  UNIX专供安装脚本"
echo "# RavenM国内版 由 Ravenfield贴吧吧主@Aya 维护"
echo "# 安装脚本 由 Github@RavenfieldCommunity 维护"
echo "# 参见: https://ravenfieldcommunity.github.io/docs/cn/Projects/ravenm.html"
echo ""
echo "#提示：在已安装插件的情况下重新安装插件 => 等价于更新"
echo "#提示：本地的安装文件会自动从服务器获取新的插件""

downloadPath = "~/.steam/steam/steamapps/common"

#退出脚本递归
Exit-IScript() {
 # read "您现在可以关闭窗口了"
 # exit
}