#!/data/data/com.termux/files/usr/bin/bash
# 用新编译的 Image 重打包本机 boot 镜像（只产出文件，不写分区）
set -euo pipefail

WORK=~/nx709s-boot
NEW_IMAGE="${1:-$WORK/Image}"
MB=/data/adb/ksu/bin/magiskboot

echo "[*] NEW_IMAGE = $NEW_IMAGE"
[ -f "$NEW_IMAGE" ] || { echo "[!] 缺少新内核 Image: $NEW_IMAGE"; exit 1; }

mkdir -p "$WORK"
cd "$WORK"

if [ ! -f boot_backup.img ]; then
  SLOT=$(getprop ro.boot.slot_suffix)
  echo "[*] 备份当前 boot${SLOT} ..."
  su -c "dd if=/dev/block/by-name/boot${SLOT} of=$WORK/boot_backup.img bs=4096"
fi

rm -rf unpack && mkdir -p unpack
cp boot_backup.img unpack/
cp "$NEW_IMAGE" unpack/kernel_new
cd unpack

echo "[*] 解包原 boot ..."
su -c "cd $WORK/unpack && $MB unpack boot_backup.img"

echo "[*] 替换 kernel ..."
su -c "cd $WORK/unpack && cp kernel_new kernel && rm -f new-boot.img && $MB repack boot_backup.img"
su -c "cd $WORK/unpack && ls -l new-boot.img"

echo "[*] 校验 ..."
su -c "cd $WORK/unpack && $MB verify new-boot.img" 2>&1 | head -10
su -c "cd $WORK/unpack && $MB unpack new-boot.img" 2>&1 | head -8

cp new-boot.img "$WORK/new-boot.img"
echo "[*] 完成: $WORK/new-boot.img  $(stat -c%s "$WORK/new-boot.img") bytes"
echo "[*] sha256: $(sha256sum "$WORK/new-boot.img" | cut -d' ' -f1)"
