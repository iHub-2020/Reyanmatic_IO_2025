#!/bin/bash
#=========================================================================
# Description : OpenWrt DIY script part 2 (After Update feeds) 仅适用于x86
# Lisence     : MIT
# Author      : Reyanmatic
# Website     : https://www.reyanmatic.com
#=========================================================================

set -e  # 有错误立即退出
set -x  # 显示每条命令（调试用，生产可去掉）

echo "========== 开始执行 diy-part2.sh =========="

# 1. 修改主页Logo
cp -f $GITHUB_WORKSPACE/resources/logo_openwrt.png feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/logo_openwrt.png
echo "[INFO] 已拷贝 logo_openwrt.png 到 luci-theme-bootstrap"

# 2. 添加主页广告滚动条
cp -f $GITHUB_WORKSPACE/resources/10_system.js feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
echo "[INFO] 已拷贝 10_system.js 到 luci-mod-status"

# 3. 修改主页部分描述信息（header、footer等）
cp -f $GITHUB_WORKSPACE/resources/header.ut feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/header.ut
echo "[INFO] 已拷贝 header.ut"
cp -f $GITHUB_WORKSPACE/resources/footer.ut feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
echo "[INFO] 已拷贝 footer.ut"

# 4. 修改主机名称（旧逻辑，兼容性保留）
sed -i "s/hostname='.*'/hostname='Reyanmatic'/g" package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
echo "[INFO] 已修改主机名称为 Reyanmatic (zzz-default-settings)"

# 5. 修改SSH登录页面logo（banner）
cp -f $GITHUB_WORKSPACE/resources/banner package/base-files/files/etc/banner
echo "[INFO] 已拷贝 banner"

# 6. 覆盖并批量写入自定义参数到 zzz-default-settings
ZZZ="package/lean/default-settings/files/zzz-default-settings"

# 删除所有 exit 0，避免后面内容被截断
sed -i '/exit 0/d' $ZZZ

# 追加自定义配置
cat >> $ZZZ <<-'EOF'
# ---------- 自定义主机名 ------------
uci set system.@system[0].hostname='Reyanmatic'
uci commit system

# ---------- 自定义网络参数 ----------
uci set network.wan.proto='pppoe'
uci set network.wan.username=''
uci set network.wan.password=''
uci set network.wan.ifname='eth1'
uci set network.wan6.proto='dhcp'
uci set network.wan6.ifname='eth1'
uci set network.lan.ipaddr='192.168.1.198'
uci set network.lan.proto='static'
uci set network.lan.type='bridge'
uci set network.lan.ifname='eth0'
uci commit network

# ---------- 如需改默认密码请在此插入（hash需自行生成） ----------
# sed -i 's@^root:[^:]*:@root:$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.:@g' /etc/shadow

EOF

# 末尾补上 exit 0，保证脚本规范
echo "exit 0" >> $ZZZ

echo "[INFO] 已批量写入自定义系统和网络参数到 $ZZZ"
echo "========== diy-part2.sh 执行完成 =========="
