#!/usr/bin/env bash
#
# 在 macOS 上编译出【未签名】的 .ipa
#
# 用途：在云 Mac / GitHub Actions 上编译，把 ipa 下载回 Windows，
#       再用 AltStore / Sideloadly 拿你的免费 Apple ID 签名安装。
#
# 为什么不做签名：云 Mac 看不到你的 iPhone，Xcode 的自动签名
#   需要设备连着才能注册 UDID 生成描述文件。所以这里只出未签名包，
#   签名交给本地的 AltStore —— 它能直接调苹果的接口完成设备注册。
#
# 用法：  bash scripts/build-unsigned-ipa.sh
#
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="BudgetAssistant"
SCHEME="BudgetAssistant"
BUILD_DIR="build"
OUT_DIR="dist"

# 先用环境变量兜底，避免 Xcode 找不到工具链
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:$PATH"

echo "==> 环境"
echo "    macOS : $(sw_vers -productVersion 2>/dev/null || echo unknown)"
echo "    Xcode : $(xcodebuild -version 2>/dev/null | head -1 || echo '未安装')"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "!! 找不到 xcodebuild，请先装 Xcode 并执行："
  echo "   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

# 没有工程文件就用 XcodeGen 生成
if [ ! -d "${APP_NAME}.xcodeproj" ]; then
  echo "==> 没有 ${APP_NAME}.xcodeproj，尝试用 XcodeGen 生成"
  if ! command -v xcodegen >/dev/null 2>&1; then
    echo "!! 需要 XcodeGen：brew install xcodegen"
    exit 1
  fi
  xcodegen generate
fi

echo "==> 清理旧产物"
rm -rf "$BUILD_DIR" "$OUT_DIR"
mkdir -p "$OUT_DIR"

echo "==> 编译（Release / 不签名）"
xcodebuild \
  -project "${APP_NAME}.xcodeproj" \
  -scheme "$SCHEME" \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGN_ENTITLEMENTS="" \
  build

APP_PATH="$BUILD_DIR/Build/Products/Release-iphoneos/${APP_NAME}.app"
if [ ! -d "$APP_PATH" ]; then
  echo "!! 编译产物不存在：$APP_PATH"
  exit 1
fi

echo "==> 打包装成 .ipa"
rm -rf "$OUT_DIR/Payload"
mkdir -p "$OUT_DIR/Payload"
cp -R "$APP_PATH" "$OUT_DIR/Payload/"

IPA="$OUT_DIR/${APP_NAME}-unsigned.ipa"
( cd "$OUT_DIR" && zip -qry "$(basename "$IPA")" Payload )
rm -rf "$OUT_DIR/Payload"

echo ""
echo "==> 完成"
ls -lh "$IPA"
echo ""
echo "把上面这个 .ipa 下载到 Windows，然后用 AltStore / Sideloadly"
echo "配合你的免费 Apple ID 签名安装（需要 iPhone 用数据线连着电脑）。"
echo ""
echo "包里包含的扩展："
find "$APP_PATH/PlugIns" -maxdepth 1 -name '*.appex' -exec basename {} \; 2>/dev/null || echo "  （无）"
