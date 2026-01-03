#!/bin/bash
#
# =========================================================================
# Description : OpenWrt DIY Script Part 2 (After Update Feeds) 仅适用于x86
# License     : MIT
# Author      : Reyanmatic
# Website     : https://www.reyanmatic.com
# Date        : 2025-01-03
# Version     : 2.1.0
# Update/Fixed: Added sed command to inject build date into 10_system.js;
#               Optimized file path handling.
# =========================================================================
#

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

# 2. 添加主页广告滚动条 (假设是自定义的JS功能) 并注入动态编译日期
# 目标路径: feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js
SYSTEM_JS_TARGET_PATH="feeds/luci/modules/luci-mod-status/htdocs/luci-static/resources/view/status/include/10_system.js"
if [ -f "$RESOURCES_DIR/10_system.js" ]; then
  cp -f "$RESOURCES_DIR/10_system.js" "$SYSTEM_JS_TARGET_PATH"
  echo "[INFO] 已拷贝 10_system.js 到 $SYSTEM_JS_TARGET_PATH"

  # [NEW] 动态替换固件版本日期
  # 获取当前日期，格式: dd.mm.yyyy (例如: 03.01.2025)
  BUILD_DATE_VAR=$(date +%d.%m.%Y)
  
  # 使用 sed 将 10_system.js 中的占位符 {BUILD_DATE} 替换为实际日期
  # 确保你的 10_system.js 中包含 'Ver.{BUILD_DATE}' 字符串
  sed -i "s/{BUILD_DATE}/$BUILD_DATE_VAR/g" "$SYSTEM_JS_TARGET_PATH"
  echo "[INFO] 已将 10_system.js 中的版本日期更新为: $BUILD_DATE_VAR"
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
  sed -i '/^[[:space:]]*exit 0[[:space:]]*$/d' "$ZZZ_DEFAULT_SETTINGS_PATH"
  echo "[INFO] 已从 $ZZZ_DEFAULT_SETTINGS_PATH 移除原有的 'exit 0' 行。"

  # 追加自定义配置到 zzz-default-settings
  # 使用 <<-'EOF' 可以保留缩进，并且 EOF 前的单引号会阻止所有变量扩展和命令替换
  # 这意味着 $variable 会被原样写入文件，在 zzz-default-settings 执行时再由其shell解释
  cat >> "$ZZZ_DEFAULT_SETTINGS_PATH" <<-'EOF'

# ==> x86自定义设置开始 (由 diy-part2.sh 添加) <==

# ---------- x86自定义主机名 ----------
uci set system.@system[0].hostname='Reyanmatic'
# 主机名设置后，可以单独commit，或与其他uci更改一起在末尾commit
# 为确保主机名更改生效，我们在这里提交 system 表的更改。
uci commit system

# ---------- x86自定义登录密码 (通过直接修改 /etc/shadow) ----------
# 下面这行会在 zzz-default-settings 脚本执行时定义一个名为 root_password_hash 的shell变量
# 生成密码hash的命令: openssl passwd -1 'your_password'
root_password_hash='$1$TyTMQln5$cgHCPhiHmSTtSpSzZDRZ3/'   # 替换为您的密码hash

# 检查 /etc/shadow 文件是否存在
if [ -f /etc/shadow ]; then
  # 当 zzz-default-settings 脚本执行时，下面的 sed 命令会运行。
  # sed 命令中的双引号允许 $root_password_hash 变量被展开（使用的是在 zzz-default-settings 中定义的那个变量）。
  # 使用 @ 作为 sed 的分隔符，以避免密码哈希中可能存在的 / 字符造成冲突。
  # 此命令会查找以 "root:" 开头的行，并将其第二个冒号分隔的字段（即密码哈希）替换为新的哈希。
  sed -i "s@^root:[^:]*:@root:$root_password_hash:@g" /etc/shadow
  echo "[INFO zzz-default-settings] Root password in /etc/shadow has been updated via sed."
else
  echo "[WARN zzz-default-settings] /etc/shadow not found. Cannot set root password via sed."
fi
# 注意：通过 sed 修改 /etc/shadow 后，不需要再为密码执行 uci commit system。

# ---------- 自定义网络参数 ----------
# WAN 设置为 PPPoE (请根据实际情况填写用户名和密码)
uci set network.wan.proto='pppoe'
uci set network.wan.username=''                           # 示例: 您的PPPoE用户名
uci set network.wan.password=''                           # 示例: 您的PPPoE密码
uci set network.wan.ifname='eth1'                         # WAN口网卡, x86通常是eth0或eth1, 根据实际调整 (eth1常用于旁路由WAN)

# WAN6 设置为 DHCPv6 (通常基于WAN口)
uci set network.wan6.proto='dhcpv6'                       # 通常是 dhcpv6
uci set network.wan6.ifname='@wan'                        # 关联到WAN接口 (eth1)

# LAN 设置
uci set network.lan.ipaddr='192.168.1.198'                # 自定义LAN IP
uci set network.lan.proto='static'
# uci set network.lan.type='bridge'                       # 如果LAN是桥接多个接口（如物理网口+WiFi），取消此行注释
uci set network.lan.ifname='eth0'                         # LAN口网卡, 根据实际调整 (eth0常用于旁路由LAN)
uci commit network                                        # 提交网络相关的uci更改

# ==> x86自定义设置结束 <==
EOF

  # 在文件末尾确保有一个 'exit 0'，保证脚本执行的规范性。
  echo "" >> "$ZZZ_DEFAULT_SETTINGS_PATH" # 添加一个空行以美化格式
  echo "exit 0" >> "$ZZZ_DEFAULT_SETTINGS_PATH"

  echo "[INFO] 已批量写入自定义系统和网络参数到 $ZZZ_DEFAULT_SETTINGS_PATH"
else
  echo "[WARN] 默认配置文件 '$ZZZ_DEFAULT_SETTINGS_PATH' 未找到，跳过自定义参数写入。"
fi

echo "========== diy-part2.sh 执行完成 =========="
