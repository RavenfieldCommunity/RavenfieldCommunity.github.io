echo "# RavenM 联机插件国内版 直接安装版脚本 UNIX专供"
echo "# RavenM国内版 由 Ravenfield贴吧吧主@Aya 维护"
echo "# 安装脚本 由 Github@RavenfieldCommunity 维护"
echo "# 参见: https://ravenfieldcommunity.github.io/docs/cn/Projects/ravenm.html"
echo ""
echo "#提示：在已安装插件的情况下重新安装插件 => 等价于更新"
echo "#提示：脚本不适用Windows, 运行脚本需要先安装Python3! 参见: https://liaoxuefeng.com/books/python/install/index.html"
echo ""

[ "$EUID" -eq 0 ] && { echo "警告: 此脚本不能以root身份运行."; exit 1; }

if [[ $get_arch =~ "aarch64" ]];then
    echo "警告: ARM架构可能不兼容此插件!"
	
pyScript=curl -fsSL http://ravenfieldcommunity.github.io/static/get_ravenmcn_d_origin-utf8.py

python3 -c $pyScript