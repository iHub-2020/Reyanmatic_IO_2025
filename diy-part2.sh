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

# 6. 修改默认网络参数到 config_generate
CFG_GEN="package/base-files/files/bin/config_generate"
echo "[INFO] 开始覆盖 config_generate 的默认网络参数与主机名等"

# 6.1 修改主机名
sed -i "s/hostname='OpenWrt'/hostname='Reyanmatic'/g" $CFG_GEN

# 6.2 修改WAN口协议
sed -i "s/set network\.wan\.proto='dhcp'/set network.wan.proto='pppoe'/g" $CFG_GEN

# 6.3 修改WAN物理口
sed -i "s/set network\.wan\.ifname='[^']*'/set network.wan.ifname='eth1'/g" $CFG_GEN

# 6.4 修改LAN协议
sed -i "s/set network\.lan\.proto='[^']*'/set network.lan.proto='static'/g" $CFG_GEN

# 6.5 修改LAN物理接口
sed -i "s/set network\.lan\.ifname='[^']*'/set network.lan.ifname='eth0'/g" $CFG_GEN

# 6.6 修改LAN口 static IP（默认管理IP）
sed -i "s/set network\.lan\.ipaddr='[^']*'/set network.lan.ipaddr='192.168.1.198'/g" $CFG_GEN

# 6.7 修改LAN类型为bridge（如无则追加）
grep -q "set network\.lan\.type='bridge'" $CFG_GEN || \
    sed -i "/set network\.lan\.proto='static'/a\    set network.lan.type='bridge'" $CFG_GEN

# 6.8 （可选）修改默认登录密码（建议安全环境下操作，hash需替换）
# HASH='$1$yC8...$abcd....'  # 用 openssl passwd -1 '你的密码' 生成
# sed -i "s@root:::0:99999:7:::@root:${HASH}:0:0:99999:7:::@g" package/base-files/files/etc/shadow

echo "[INFO] 已通过 sed 覆盖 config_generate 的主机名、默认IP、网络参数"

echo "========== diy-part2.sh 执行完成 =========="
