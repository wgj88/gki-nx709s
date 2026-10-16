#!/data/data/com.termux/files/usr/bin/bash
# 将 new-boot.img 写入当前 slot 的 boot 分区（先校验再写入）
set -euo pipefail

IMG="${1:-$HOME/nx709s-boot/new-boot.img}"
[ -f "$IMG" ] || { echo "[!] 缺少 $IMG"; exit 1; }

SLOT=$(getprop ro.boot.slot_suffix)
DST=/dev/block/by-name/boot${SLOT}
SIZE=$(stat -c%s "$IMG")
PART=$(su -c "blockdev --getsize64 $DST")

echo "[*] 目标分区: $DST (${PART} bytes)"
echo "[*] 镜像大小: $SIZE bytes"
[ "$SIZE" -le "$PART" ] || { echo "[!] 镜像大于分区，中止"; exit 1; }

echo "[*] 写入前再次备份 -> /sdcard/boot_backup_preflash.img"
su -c "dd if=$DST of=/sdcard/boot_backup_preflash.img bs=4096"

echo "[*] 写入 $IMG -> $DST"
su -c "dd if=$IMG of=$DST bs=4096"

echo "[*] 回读校验 ..."
su -c "dd if=$DST bs=4096 count=$(( (SIZE+4095)/4096 ))" | sha256sum | cut -d' ' -f1 > /data/data/com.termux/files/home/nx709s-boot/.rb
head -c "$SIZE" "$IMG" | sha256sum | cut -d' ' -f1 > /data/data/com.termux/files/home/nx709s-boot/.ri
if cmp -s /data/data/com.termux/files/home/nx709s-boot/.rb /data/data/com.termux/files/home/nx709s-boot/.ri; then
  echo "[✓] 校验一致，刷入成功。可执行 reboot"
else
  echo "[!] 校验不一致，请勿重启！"; cat /data/data/com.termux/files/home/nx709s-boot/.rb /data/data/com.termux/files/home/nx709s-boot/.ri; exit 1
fi
