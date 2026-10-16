#!/data/data/com.termux/files/usr/bin/bash
# 启动 redroid 容器（GKI 命名空间内核就绪后）
set -euo pipefail
NAME=${NAME:-redroid}
IMG=${IMG:-redroid/redroid:12.0.0-latest}
DATA=${DATA:-$HOME/redroid-data}
mkdir -p "$DATA"

if ! docker info >/dev/null 2>&1; then
  echo "[!] dockerd 未运行，请先启动 dockerd"; exit 1
fi

docker rm -f "$NAME" >/dev/null 2>&1 || true
docker run -itd \
  --name "$NAME" \
  --privileged \
  --memory-swappiness=0 \
  --restart=unless-stopped \
  -v "$DATA":/data \
  -p 5555:5555 \
  "$IMG" \
  androidboot.hardware=redroid \
  androidboot.selinux=permissive
echo "[*] 容器已启动，等待 init ..."
sleep 6
docker ps --filter name="$NAME"
echo "[*] adb connect 127.0.0.1:5555"
