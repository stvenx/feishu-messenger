#!/usr/bin/env bash
#
# 解析出 feishu-messenger 二进制并执行。
#
# 查找顺序：
#   1. action 目录下的缓存（同一 job 内重复调用不重复下载）
#   2. GitHub release 下载（带 sha256 校验）
#   3. 用本地 go toolchain 从源码编译（源码随 action checkout 一起到位）
#
# 消息参数通过 INPUT_* 环境变量传给二进制，由 action.yaml 注入。

set -euo pipefail

ACTION_PATH="${GITHUB_ACTION_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
ACTION_PATH="${ACTION_PATH%/}"
VERSION="${FM_VERSION:-v2.0.0}"
RELEASE_URL="${FM_RELEASE_URL:-https://github.com/stvenx/feishu-messenger/releases/download}"
RELEASE_URL="${RELEASE_URL%/}"

# 错误码
readonly ERR_UNSUPPORTED_PLATFORM=2
readonly ERR_UNSUPPORTED_ARCH=3
readonly ERR_RESOLVE_FAILED=4
readonly ERR_CHECKSUM_FAILED=5

log() { echo "$*"; }
fail() { echo "::error::$1" >&2; exit "$2"; }

detect_platform() {
  local os arch
  os="$(uname -s | tr '[:upper:]' '[:lower:]')"
  arch="$(uname -m)"

  case "$os" in
    linux | darwin) ;;
    mingw* | msys* | cygwin* | windows*) os="windows" ;;
    *) fail "不支持的操作系统：${os}（支持 linux、darwin、windows）" "$ERR_UNSUPPORTED_PLATFORM" ;;
  esac

  case "$arch" in
    x86_64 | amd64) arch="amd64" ;;
    aarch64 | arm64) arch="arm64" ;;
    *) fail "不支持的架构：${arch}（支持 x86_64、arm64）" "$ERR_UNSUPPORTED_ARCH" ;;
  esac

  PLATFORM_OS="$os"
  PLATFORM_ARCH="$arch"
}

verify_checksum() {
  local file="$1" sums="$2" name="$3"
  local expected actual

  expected="$(awk -v n="$name" '$2 == n || $2 == "*" n { print $1 }' "$sums" | head -n 1)"
  if [[ -z "$expected" ]]; then
    log "sha256sums.txt 中没有 $name 的记录，跳过校验"
    return 0
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$file" | awk '{print $1}')"
  elif command -v shasum >/dev/null 2>&1; then
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
  else
    log "找不到 sha256sum / shasum，跳过校验"
    return 0
  fi

  if [[ "$expected" != "$actual" ]]; then
    fail "sha256 校验失败：期望 ${expected}，实际 ${actual}" "$ERR_CHECKSUM_FAILED"
  fi
  log "sha256 校验通过"
}

download_binary() {
  local name="$1" target="$2"
  local url="$RELEASE_URL/$VERSION/$name"
  local tmp sums

  command -v curl >/dev/null 2>&1 || return 1

  tmp="$(mktemp)"
  if ! curl --fail --location --silent --show-error --retry 3 --retry-delay 2 \
       --output "$tmp" "$url"; then
    rm -f "$tmp"
    log "下载失败：$url"
    return 1
  fi
  [[ -s "$tmp" ]] || { rm -f "$tmp"; return 1; }

  sums="$(mktemp)"
  if curl --fail --location --silent --show-error --retry 2 \
       --output "$sums" "$RELEASE_URL/$VERSION/sha256sums.txt"; then
    verify_checksum "$tmp" "$sums" "$name"
  else
    log "拉不到 sha256sums.txt，跳过校验"
  fi
  rm -f "$sums"

  chmod +x "$tmp"
  mv "$tmp" "$target"
}

build_from_source() {
  local target="$1"

  command -v go >/dev/null 2>&1 || return 1
  [[ -f "$ACTION_PATH/main.go" ]] || return 1

  log "用本地 go toolchain 从源码编译（$(go version)）"
  ( cd "$ACTION_PATH" && CGO_ENABLED=0 go build -ldflags="-w -s" -o "$target" . )
}

main() {
  detect_platform

  local suffix=""
  [[ "$PLATFORM_OS" == "windows" ]] && suffix=".exe"

  local asset="feishu-messenger-${VERSION#v}-${PLATFORM_OS}-${PLATFORM_ARCH}${suffix}"
  local bin_dir="$ACTION_PATH/bin"
  local bin="$bin_dir/feishu-messenger-${VERSION#v}-${PLATFORM_OS}-${PLATFORM_ARCH}${suffix}"

  mkdir -p "$bin_dir"

  if [[ -x "$bin" ]]; then
    log "复用已有二进制：$bin"
  elif download_binary "$asset" "$bin"; then
    log "已下载：$asset"
  elif build_from_source "$bin"; then
    log "已从源码编译：$bin"
  else
    fail "拿不到二进制：release 下载失败且本地没有 go toolchain。检查网络、version（${VERSION}）是否存在，或 release_url（${RELEASE_URL}）是否可达" "$ERR_RESOLVE_FAILED"
  fi

  exec "$bin"
}

main "$@"


