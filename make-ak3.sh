#!/data/data/com.termux/files/usr/bin/bash
# 生成 AnyKernel3 刷机包（内含新编译的 Image，recovery 可刷）
set -euo pipefail
WORK=~/nx709s-boot
AK=~/tmp/AnyKernel3-master
OUT=$WORK/ak3
[ -f "$WORK/Image" ] || { echo "[!] 缺少 $WORK/Image"; exit 1; }
rm -rf "$OUT" && mkdir -p "$OUT"
cp -r "$AK"/META-INF "$AK"/tools "$OUT"/
cp "$WORK/Image" "$OUT"/Image
cat > "$OUT"/anykernel.sh <<'EOF'
### AnyKernel3 Ramdisk Mod Script
## NX709S GKI 5.10.168 + KernelSU v3.3.0 + Docker namespaces

properties() { '
kernel.string=NX709S GKI 5.10.168 + KernelSU v3.3.0 + Docker(PID_NS/IPC_NS/POSIX_MQUEUE)
do.devicecheck=0
do.modules=0
do.systemless=1
do.cleanup=0
do.cleanuponabort=0
supported.versions=
supported.patchlevels=
'; } # end properties

block=auto;
is_slot_device=auto;
ramdisk_compression=auto;
patch_vbmeta_flag=auto;

. tools/ak3-core.sh;

split_boot;
flash_boot;
## end install
EOF
cd "$OUT" && 7z a -tzip -mx1 -y "$WORK/AnyKernel3-NX709S-GKI510-docker.zip" . >/dev/null
echo "[✓] $WORK/AnyKernel3-NX709S-GKI510-docker.zip ($(stat -c%s "$WORK/AnyKernel3-NX709S-GKI510-docker.zip") bytes)"
