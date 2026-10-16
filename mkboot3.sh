#!/data/data/com.termux/files/usr/bin/bash
# 备用方案：新内核 + 原厂未修补 ramdisk（无 KernelSU），用于排除 KSU 干扰的纯净验证
set -euo pipefail

WORK=~/nx709s-boot
NEW_IMAGE="${1:-$WORK/Image}"
STOCK_BOOT="${2:-/sdcard/Download/boot.img}"
MB=/data/adb/ksu/bin/magiskboot

[ -f "$NEW_IMAGE" ]  || { echo "[!] 缺 $NEW_IMAGE"; exit 1; }
[ -f "$STOCK_BOOT" ] || { echo "[!] 缺 $STOCK_BOOT"; exit 1; }

mkdir -p "$WORK/stockvar"; cd "$WORK/stockvar"
cp "$STOCK_BOOT" stock-boot.img
cp "$NEW_IMAGE"  kernel_new

echo "[*] 解包原厂 boot ..."
su -c "cd $WORK/stockvar && $MB unpack stock-boot.img"

echo "[*] 用新内核替换（ramdisk 保持原厂，不含 kernelsu.ko）"
su -c "cd $WORK/stockvar && cp kernel_new kernel"

echo "[*] 重打包 ..."
su -c "cd $WORK/stockvar && rm -f new-boot.img && $MB repack stock-boot.img"
su -c "cd $WORK/stockvar && $MB verify new-boot.img" 2>&1 | head -10
su -c "cd $WORK/stockvar && $MB cpio ramdisk.cpio ls" | grep -iE "kernelsu|init"

cp new-boot.img "$WORK/new-boot-stockramdisk.img"
echo "[✓] $WORK/new-boot-stockramdisk.img  $(stat -c%s "$WORK/new-boot-stockramdisk.img") bytes"
echo "[*] sha256: $(sha256sum "$WORK/new-boot-stockramdisk.img" | cut -d' ' -f1)"
echo "[!] 注意：该镜像无 KernelSU，刷入后 root 消失，用于纯净验证内核本身"
