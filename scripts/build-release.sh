#!/usr/bin/env bash
#
# 交叉编译各平台二进制到 dist/，并生成 sha256sums.txt。
# 产物命名必须与 scripts/run.sh 的 asset 名一致。
#
# 用法：VERSION=v2.0.0 ./scripts/build-release.sh

set -euo pipefail

VERSION="${VERSION:-${1:-}}"
if [[ -z "$VERSION" ]]; then
  echo "用法：VERSION=v2.0.0 $0" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/dist"
BARE="${VERSION#v}"

rm -rf "$DIST"
mkdir -p "$DIST"
cd "$ROOT"

PLATFORMS=(
  "linux/amd64"
  "linux/arm64"
  "darwin/amd64"
  "darwin/arm64"
  "windows/amd64"
)

for p in "${PLATFORMS[@]}"; do
  os="${p%/*}"
  arch="${p#*/}"
  suffix=""
  [[ "$os" == "windows" ]] && suffix=".exe"

  out="$DIST/feishu-messenger-${BARE}-${os}-${arch}${suffix}"
  echo "building $out"
  CGO_ENABLED=0 GOOS="$os" GOARCH="$arch" \
    go build -trimpath -ldflags="-w -s" -o "$out" .
done

cd "$DIST"
if command -v sha256sum >/dev/null 2>&1; then
  sha256sum feishu-messenger-* > sha256sums.txt
else
  shasum -a 256 feishu-messenger-* > sha256sums.txt
fi

echo
echo "dist/:"
ls -lh
echo
cat sha256sums.txt
