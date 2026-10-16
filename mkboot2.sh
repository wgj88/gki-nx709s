#!/data/data/com.termux/files/usr/bin/bash
# 新内核 + 同树编译的 kernelsu.ko 重打包 boot（LKM 模式，与本机现工作方式一致）
set -euo pipefail

WORK=~/nx709s-boot
NEW_IMAGE="${1:-$WORK/Image}"
NEW_KSU="${2:-$WORK/kernelsu.ko}"
MB=/data/adb/ksu/bin/magiskboot

[ -f "$NEW_IMAGE" ] || { echo "[!] 缺 $NEW_IMAGE"; exit 1; }
[ -f "$NEW_KSU" ]   || { echo "[!] 缺 $NEW_KSU"; exit 1; }

mkdir -p "$WORK"; cd "$WORK"
[ -f boot_backup.img ] || su -c "dd if=/dev/block/by-name/boot$(getprop ro.boot.slot_suffix) of=$WORK/boot_backup.img bs=4096"

rm -rf unpack2 && mkdir -p unpack2
cp boot_backup.img unpack2/
cp "$NEW_IMAGE" unpack2/kernel_new
cp "$NEW_KSU" unpack2/kernelsu_ko_new
cd unpack2

echo "[*] 解包原 boot"
su -c "cd $WORK/unpack2 && $MB unpack boot_backup.img"

echo "[*] 替换内核"
su -c "cd $WORK/unpack2 && cp kernel_new kernel"

echo "[*] 替换 ramdisk 里的 kernelsu.ko（旧模块给原内核，换成同树编译版本）"
su -c "cd $WORK/unpack2 && $MB cpio ramdisk.cpio 'rm kernelsu.ko' 'add 0755 kernelsu.ko kernelsu_ko_new'"
su -c "cd $WORK/unpack2 && $MB cpio ramdisk.cpio ls" | grep -i kernelsu

echo "[*] 重打包"
su -c "cd $WORK/unpack2 && rm -f new-boot.img && $MB repack boot_backup.img"
su -c "cd $WORK/unpack2 && $MB verify new-boot.img" 2>&1 | head -10

cp new-boot.img "$WORK/new-boot-lkm.img"
echo "[✓] $WORK/new-boot-lkm.img  $(stat -c%s "$WORK/new-boot-lkm.img") bytes"
echo "[*] sha256: $(sha256sum "$WORK/new-boot-lkm.img" | cut -d' ' -f1)"
