#!/usr/bin/env bash
# Prepare build space. License: MIT
set -euo pipefail

echo "Preparing build space..."

# Remove preinstalled software (best-effort, silent)
{
  [ "${INPUT_REMOVE_ANDROID}" = "true" ]       && sudo rm -rf /usr/local/lib/android
  [ "${INPUT_REMOVE_DOTNET}" = "true" ]        && sudo rm -rf /usr/share/dotnet
  [ "${INPUT_REMOVE_HASKELL}" = "true" ]       && sudo rm -rf /opt/ghc /usr/local/.ghcup
  [ "${INPUT_REMOVE_CODEQL}" = "true" ]        && sudo rm -rf /opt/hostedtoolcache/CodeQL
  [ "${INPUT_REMOVE_TOOL_CACHE}" = "true" ]    && sudo rm -rf /opt/hostedtoolcache
  if [ "${INPUT_REMOVE_DOCKER_IMAGES}" = "true" ]; then
    sudo docker image prune --all --force
    sudo systemctl stop docker.service docker.socket
    sudo rm -rf /var/lib/docker
  fi
  if [ "${INPUT_REMOVE_SWAP_STORAGE}" = "true" ]; then
    sudo swapoff -a; sudo rm -f /mnt/swapfile /swapfile
  fi
  if [ "${INPUT_REMOVE_LARGE_PACKAGES}" = "true" ]; then
    sudo apt-get -qq -o DPkg::Lock::Timeout=120 purge -y \
      '^aspnetcore-.*' '^dotnet-.*' '^llvm-.*' '^mongodb-.*' '^mysql-.*' \
      'php.*' azure-cli google-cloud-cli google-cloud-sdk \
      google-chrome-stable firefox powershell mono-devel
    sudo apt-get -qq -o DPkg::Lock::Timeout=120 autoremove --purge -y
  fi
  sudo rm -rf \
    /usr/share/swift /usr/local/share/powershell /opt/microsoft /usr/lib/jvm \
    /usr/local/lib/node_modules /usr/local/share/chromium /usr/local/share/vcpkg \
    /usr/local/graalvm /usr/local/julia* /usr/local/bin/chromedriver \
    /usr/local/bin/geckodriver /usr/local/bin/edge_driver /opt/az /var/lib/gems \
    /usr/local/share/boost
  sudo apt-get -qq -o DPkg::Lock::Timeout=120 autoremove --purge -y
  sudo apt-get -qq clean
  sudo rm -rf /var/lib/apt/lists/*
} || true  # keep output visible for postmortem (B-026)

# Expand build volume: merge free space of / and /mnt via LVM when they are
# separate disks; otherwise use the root partition directly.
ROOT_SRC=$(df --output=source / | tail -1 | tr -d ' ')
MNT_SRC=$(df --output=source /mnt 2>/dev/null | tail -1 | tr -d ' ' || echo '')
MNT_TARGET=$(df --output=target /mnt 2>/dev/null | tail -1 | tr -d ' ' || echo '')

if [ -n "${MNT_SRC}" ] && [ "${MNT_SRC}" != "${ROOT_SRC}" ] && [ "${MNT_TARGET}" = "/mnt" ]; then
  DUAL_DISK="true"
else
  DUAL_DISK="false"
fi

if [ "${DUAL_DISK}" = "true" ]; then
  command -v pvcreate >/dev/null 2>&1 || { sudo apt-get -qq -o DPkg::Lock::Timeout=120 update; sudo apt-get -qq -o DPkg::Lock::Timeout=120 install -y lvm2; } || true  # keep output visible for postmortem (B-026)
  ROOT_RESERVE_KB=$(( INPUT_ROOT_RESERVE_MB * 1024 ))
  ROOT_FREE_KB=$(df --block-size=1024 --output=avail / | tail -1 | tr -d ' ')
  ROOT_LVM_SIZE_BYTES=$(( (ROOT_FREE_KB - ROOT_RESERVE_KB) * 1024 ))
  TMP_RESERVE_KB=$(( INPUT_TEMP_RESERVE_MB * 1024 ))
  TMP_FREE_KB=$(df --block-size=1024 --output=avail /mnt | tail -1 | tr -d ' ')
  TMP_LVM_SIZE_BYTES=$(( (TMP_FREE_KB - TMP_RESERVE_KB) * 1024 ))

  sudo touch "${INPUT_PV_LOOP_PATH}"
  sudo fallocate -l "${ROOT_LVM_SIZE_BYTES}" "${INPUT_PV_LOOP_PATH}"
  ROOT_LOOP_DEV=$(sudo losetup --find --show "${INPUT_PV_LOOP_PATH}")
  sudo pvcreate -f "${ROOT_LOOP_DEV}" >/dev/null

  sudo touch "${INPUT_TMP_PV_LOOP_PATH}"
  sudo fallocate -l "${TMP_LVM_SIZE_BYTES}" "${INPUT_TMP_PV_LOOP_PATH}"
  TMP_LOOP_DEV=$(sudo losetup --find --show "${INPUT_TMP_PV_LOOP_PATH}")
  sudo pvcreate -f "${TMP_LOOP_DEV}" >/dev/null

  sudo vgcreate buildvg "${ROOT_LOOP_DEV}" "${TMP_LOOP_DEV}" >/dev/null
  if [ "${INPUT_SWAP_SIZE_MB}" -gt 0 ]; then
    sudo lvcreate -L "${INPUT_SWAP_SIZE_MB}M" -n buildswap buildvg >/dev/null
    sudo mkswap /dev/mapper/buildvg-buildswap >/dev/null
    sudo swapon /dev/mapper/buildvg-buildswap
  fi
  if [ "${INPUT_OVERPROVISION_LVM}" = "true" ]; then
    sudo lvcreate -l 100%FREE -T -n buildpool buildvg >/dev/null
    sudo lvcreate -V "$(( ROOT_LVM_SIZE_BYTES + TMP_LVM_SIZE_BYTES ))B" -T buildvg/buildpool -n buildlv >/dev/null
  else
    sudo lvcreate -l 100%FREE -n buildlv buildvg >/dev/null
  fi
  sudo mkfs.ext4 -q -m0 /dev/mapper/buildvg-buildlv
  sudo mkdir -p "${INPUT_BUILD_MOUNT_PATH}"
  sudo mount /dev/mapper/buildvg-buildlv "${INPUT_BUILD_MOUNT_PATH}"
  sudo chown -R "${INPUT_BUILD_MOUNT_PATH_OWNERSHIP}" "${INPUT_BUILD_MOUNT_PATH}"
else
  if [ "${INPUT_SWAP_SIZE_MB}" -gt 0 ]; then
    sudo swapoff -a || true
    sudo rm -f /swapfile || true
    sudo fallocate -l "${INPUT_SWAP_SIZE_MB}M" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile >/dev/null
    sudo swapon /swapfile
  fi
  sudo mkdir -p "${INPUT_BUILD_MOUNT_PATH}"
  sudo chown -R "${INPUT_BUILD_MOUNT_PATH_OWNERSHIP}" "${INPUT_BUILD_MOUNT_PATH}"
fi

echo "Build space ready."
