#!/bin/bash
#==========================================================================
# Description : OpenWrt customize script-2 (After Update feeds) 仅适用于R2S
# Lisence     : MIT
# Author      : Reyanmatic
# Website     : https:www.reyanmatic.com
#==========================================================================

echo "========== 开始执行 customize-2.sh =========="

set -e  # 遇到错误立即退出脚本
# set -x  # 调试模式，显示每条命令

# 切换到 openwrt 目录
cd openwrt

# 输出调试信息
echo "[DEBUG] Current working directory: $(pwd)"

# 1. 修改默认 IP 地址
# sed -i 's/192.168.1.1/192.168.1.198/g' openwrt/package/base-files/files/bin/config_generate
sed -i 's/192.168.1.1/192.168.1.198/g' package/base-files/files/bin/config_generate
echo "[INFO] 默认IP已修改为 192.168.1.198"

# 2. 替换主页 Logo
if [ -f "$GITHUB_WORKSPACE/resources/logo_openwrt.png" ]; then
    cp -f "$GITHUB_WORKSPACE/resources/logo_openwrt.png" feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/logo_openwrt.png
    echo "[INFO] 已拷贝 logo_openwrt.png 到 luci-theme-bootstrap"
else
    echo "[WARN] 未找到 logo_openwrt.png 文件"
fi

# 3. 添加主页广告滚动条
if [ -f "$GITHUB_WORKSPACE/resources/10_system.js" ]; then
    cp -f "$GITHUB_WORKSPACE/resources/10_system.js" feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
    echo "[INFO] 已拷贝 10_system.js 到 luci-mod-status"
else
    echo "[WARN] 未找到 10_system.js 文件"
fi

# 4. 修改主页描述信息
for file in header.ut footer.ut; do
    if [ -f "$GITHUB_WORKSPACE/resources/$file" ]; then
        cp -f "$GITHUB_WORKSPACE/resources/$file" feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/$file
        echo "[INFO] 已拷贝 $file"
    else
        echo "[WARN] 未找到 $file 文件"
    fi
done

# 5. 设置主机名称
sed -i "s/hostname='.*'/hostname='Reyanmatic'/g" package/lean/default-settings/files/zzz-default-settings 2>/dev/null || true
echo "[INFO] 已修改主机名称为 Reyanmatic"

# 6. 修改 SSH 登录页面 Banner
if [ -f "$GITHUB_WORKSPACE/resources/banner" ]; then
    cp -f "$GITHUB_WORKSPACE/resources/banner" package/base-files/files/etc/banner
    echo "[INFO] 已拷贝 banner"
else
    echo "[WARN] 未找到 banner 文件"
fi

# 7. 添加 x86 默认网络配置
ZZZ_BASE="package/lean/default-settings/files/zzz-default-settings"
if [ -f "$ZZZ_BASE" ]; then
    cat >> "$ZZZ_BASE" <<'EOF'

# ===== Reyanmatic R2S Default Network Settings =====
uci set network.wan.proto='pppoe'
uci set network.wan.username=''
uci set network.wan.password=''
uci set network.wan.ifname='eth0'
uci set network.wan6.proto='DHCP'
uci set network.wan6.ifname='eth0'
uci set network.lan.ipaddr='192.168.1.198'
uci set network.lan.proto='static'
uci set network.lan.type='bridge'
uci set network.lan.ifname='eth1'
uci commit network
EOF
    echo "[INFO] 已追加 R2S 默认网络配置到 zzz-default-settings"
else
    echo "[WARN] 未找到 zzz-default-settings 文件，无法追加网络配置"
fi

echo "========== customize-2.sh 执行完成 =========="
