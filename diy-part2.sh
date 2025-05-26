#!/bin/bash
#=========================================================================
# Description : OpenWrt DIY script part 2 (After Update feeds) 仅适用于x86
# Lisence     : MIT
# Author      : Reyanmatic
# Website     : https://www.reyanmatic.com
#=========================================================================

# 当任何命令执行返回非零退出状态时立即退出，有助于早期发现错误。
set -e

# (可选) 打印脚本执行的每一条命令。在调试时非常有用。
# 对于生产环境或非调试构建，建议注释掉此行以减少日志输出。
# set -x

echo "========== 开始执行 diy-part2.sh =========="

# 定义资源文件目录变量，方便管理和修改
RESOURCES_DIR="$GITHUB_WORKSPACE/resources" # GITHUB_WORKSPACE 是 GitHub Actions 提供的环境变量，指向仓库根目录

# 检查资源目录是否存在，增加脚本的健壮性
if [ ! -d "$RESOURCES_DIR" ]; then
  echo "[ERROR] 资源目录 '$RESOURCES_DIR' 未找到！请检查路径。"
  exit 1
fi

# --- UI 及系统文件修改 ---

# 1. 修改主页Logo
# 目标路径: feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/logo_openwrt.png
LOGO_TARGET_PATH="feeds/luci/themes/luci-theme-bootstrap/htdocs/luci-static/bootstrap/logo_openwrt.png"
if [ -f "$RESOURCES_DIR/logo_openwrt.png" ]; then
  cp -f "$RESOURCES_DIR/logo_openwrt.png" "$LOGO_TARGET_PATH"
  echo "[INFO] 已拷贝 logo_openwrt.png 到 $LOGO_TARGET_PATH"
else
  echo "[WARN] Logo 文件 '$RESOURCES_DIR/logo_openwrt.png' 未找到，跳过替换。"
fi

# 2. 添加主页广告滚动条 (假设是自定义的JS功能)
# 目标路径: feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
SYSTEM_JS_TARGET_PATH="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
if [ -f "$RESOURCES_DIR/10_system.js" ]; then
  cp -f "$RESOURCES_DIR/10_system.js" "$SYSTEM_JS_TARGET_PATH"
  echo "[INFO] 已拷贝 10_system.js 到 $SYSTEM_JS_TARGET_PATH"
else
  echo "[WARN] JS 文件 '$RESOURCES_DIR/10_system.js' 未找到，跳过替换。"
fi

# 3. 修改主页部分描述信息（header、footer等）
# 目标路径: feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/header.ut
HEADER_UT_TARGET_PATH="feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/header.ut"
if [ -f "$RESOURCES_DIR/header.ut" ]; then
  cp -f "$RESOURCES_DIR/header.ut" "$HEADER_UT_TARGET_PATH"
  echo "[INFO] 已拷贝 header.ut 到 $HEADER_UT_TARGET_PATH"
else
  echo "[WARN] header.ut 文件 '$RESOURCES_DIR/header.ut' 未找到，跳过替换。"
fi

# 目标路径: feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut
FOOTER_UT_TARGET_PATH="feeds/luci/themes/luci-theme-bootstrap/ucode/template/themes/bootstrap/footer.ut"
if [ -f "$RESOURCES_DIR/footer.ut" ]; then
  cp -f "$RESOURCES_DIR/footer.ut" "$FOOTER_UT_TARGET_PATH"
  echo "[INFO] 已拷贝 footer.ut 到 $FOOTER_UT_TARGET_PATH"
else
  echo "[WARN] footer.ut 文件 '$RESOURCES_DIR/footer.ut' 未找到，跳过替换。"
fi

# 4. 修改SSH登录页面logo（banner）
# 目标路径: package/base-files/files/etc/banner
BANNER_TARGET_PATH="package/base-files/files/etc/banner"
if [ -f "$RESOURCES_DIR/banner" ]; then
  cp -f "$RESOURCES_DIR/banner" "$BANNER_TARGET_PATH"
  echo "[INFO] 已拷贝 banner 到 $BANNER_TARGET_PATH"
else
  echo "[WARN] banner 文件 '$RESOURCES_DIR/banner' 未找到，跳过替换。"
fi

# --- 自定义默认设置 ---

# 5. 覆盖并批量写入自定义参数到 zzz-default-settings
# 注意: 此路径特定于 coolsnowwolf/lede (Lean's OpenWrt source)
ZZZ_DEFAULT_SETTINGS_PATH="package/lean/default-settings/files/zzz-default-settings"

if [ -f "$ZZZ_DEFAULT_SETTINGS_PATH" ]; then
  # 删除文件中所有独立的 'exit 0' 行，为追加自定义设置做准备。
  # 使用更精确的正则表达式匹配行首到行尾的 'exit 0'，允许前后有空格。
  sed -i '/^[[:space:]]*exit 0[[:space:]]*$/d' "$ZZZ_DEFAULT_SETTINGS_PATH"
  echo "[INFO] 已从 $ZZZ_DEFAULT_SETTINGS_PATH 移除原有的 'exit 0' 行。"

  # 追加自定义配置到 zzz-default-settings
  # 使用 cat 和 here document (<<-'EOF') 来追加多行文本。
  # '-' 使 here document 中的前导制表符被忽略，方便排版。
  cat >> "$ZZZ_DEFAULT_SETTINGS_PATH" <<-'EOF'

# ==> 自定义设置开始 (由 diy-part2.sh 添加) <==

# ---------- 自定义主机名和登录密码 ------------
uci set system.@system[0].hostname='Reyanmatic'
root_password_hash='$1$PrH5T/M2$bJ/LEDMMUQ0vj4vhg7jeC.'   # 替换为您的密码hash
uci set system.@system[0].password="$root_password_hash"
uci commit system

# ---------- 自定义网络参数 ----------
# WAN 设置为 PPPoE (请根据实际情况填写用户名和密码)
uci set network.wan.proto='pppoe'
uci set network.wan.username='' # 示例: 您的PPPoE用户名
uci set network.wan.password='' # 示例: 您的PPPoE密码
uci set network.wan.ifname='eth1' # WAN口网卡，x86通常是eth0或eth1, 根据实际调整

# WAN6 设置为 DHCPv6
uci set network.wan6.proto='dhcpv6' # 通常为 dhcpv6
uci set network.wan6.ifname='@wan' # 通常关联到wan接口

# LAN 设置
uci set network.lan.ipaddr='192.168.1.198'
uci set network.lan.proto='static'
# uci set network.lan.type='bridge' # 如果LAN是桥接多个接口，取消此行注释
uci set network.lan.ifname='eth0' # LAN口网卡, 根据实际调整
uci commit network

# ---------- 如需改默认密码请在此插入（hash需自行生成） ----------
# 注意: 直接修改 /etc/shadow 文件更为可靠，但这通常在固件首次启动脚本中完成，
# 或者通过预置 files/etc/shadow 文件。
# 在 zzz-default-settings 中修改密码相对复杂且不一定总能按预期工作。
# 推荐方法是预置 /etc/config/system 中的登录密码hash，或通过 files 机制覆盖 /etc/shadow。
# 例如 (生成密码hash的命令: openssl passwd -1 'your_password'):
# root_password_hash='$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF.' # 替换为您的密码hash
# uci set system.@system[0].password="$root_password_hash"
# uci commit system

# ==> 自定义设置结束 <==
EOF

  # 在文件末尾确保有一个 'exit 0'，保证脚本执行的规范性。
  echo "" >> "$ZZZ_DEFAULT_SETTINGS_PATH" # 添加一个空行以美化格式
  echo "exit 0" >> "$ZZZ_DEFAULT_SETTINGS_PATH"

  echo "[INFO] 已批量写入自定义系统和网络参数到 $ZZZ_DEFAULT_SETTINGS_PATH"
else
  echo "[WARN] 默认配置文件 '$ZZZ_DEFAULT_SETTINGS_PATH' 未找到，跳过自定义参数写入。"
fi

echo "========== diy-part2.sh 执行完成 =========="
