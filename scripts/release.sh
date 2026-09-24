#!/bin/bash
# ============================================================
# TXTForMac 发布脚本（T-047）
# 用法: bash scripts/release.sh <version>   例如: bash scripts/release.sh 1.0.0
#
# 流程: 版本号写入 project.yml → Release 构建 → ad-hoc 签名 →
#       ZIP(Sparkle 用) + DMG(人装用) → EdDSA 签名 → 渲染 appcast.xml →
#       提交 tag → gh release → 推送 gh-pages
#
# 前置: Sparkle 工具在 .tmp/sparkle/bin（sign_update）；EdDSA 私钥在本机
#       登录钥匙串（generate_keys 生成）；gh 已登录 NonchalantLudens
# ============================================================
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "用法: bash scripts/release.sh <version>"
  exit 1
fi

DERIVED_ROOT="${TXTFORMAC_DERIVED:-$HOME/Library/Caches/txtformac-dd}"
DERIVED="$DERIVED_ROOT/release-$VERSION"
TOOLS="$ROOT/.tmp/sparkle/bin"
REPO="NonchalantLudens/TXTForMac"
FEED_REPO_DIR="$DERIVED/gh-pages"

cd "$ROOT"

# 0. 前置校验
git diff --quiet || { echo "❌ 有未提交改动，先提交"; exit 1; }
git rev-parse --verify "v$VERSION" >/dev/null 2>&1 && { echo "❌ tag v$VERSION 已存在"; exit 1; }
[ -x "$TOOLS/sign_update" ] || { echo "❌ 缺少 Sparkle 工具（.tmp/sparkle/bin/sign_update）"; exit 1; }

echo "==> 1/7 版本号 → project.yml ($VERSION)"
sed -i '' "s/MARKETING_VERSION: \".*\"/MARKETING_VERSION: \"$VERSION\"/" project.yml
xcodegen generate
git add project.yml TXTForMac.xcodeproj
git commit -m "release: 版本号更新至 v$VERSION"

echo "==> 2/7 Release 构建"
xcodebuild -scheme TXTForMac \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED/dd" \
  build
APP="$DERIVED/dd/Build/Products/Release/TXTForMac.app"

echo "==> 3/7 ad-hoc 签名（ADR-003，公证链路预留）"
codesign --force --deep --sign - "$APP"

echo "==> 4/7 打包 ZIP + DMG"
ZIP="$DERIVED/TXTForMac-$VERSION.zip"
DMG="$DERIVED/TXTForMac-$VERSION.dmg"
ditto -c -k --keepParent "$APP" "$ZIP"
rm -f "$DMG"
hdiutil create -volname "TXTForMac" -srcfolder "$APP" -ov -format UDZO "$DMG" >/dev/null

echo "==> 5/7 EdDSA 签名并渲染 appcast 条目"
SIGN_OUTPUT="$("$TOOLS/sign_update" "$ZIP")"
SIG="$(echo "$SIGN_OUTPUT" | sed -n 's/.*sparkle:edSignature="\([^"]*\)".*/\1/p')"
LENGTH="$(echo "$SIGN_OUTPUT" | sed -n 's/.*length="\([0-9]*\)".*/\1/p')"
[ -n "$SIG" ] && [ -n "$LENGTH" ] || { echo "❌ EdDSA 签名失败：$SIGN_OUTPUT"; exit 1; }
PUBDATE="$(LC_ALL=C date -u '+%a, %d %b %Y %H:%M:%S %z')"
BUILD="$(echo "$VERSION" | tr -d '.')"

ITEM="    <item>
      <title>Version $VERSION</title>
      <pubDate>$PUBDATE</pubDate>
      <sparkle:version>$BUILD</sparkle:version>
      <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
      <link>https://github.com/$REPO/releases/download/v$VERSION/TXTForMac-$VERSION.zip</link>
      <enclosure url=\"https://github.com/$REPO/releases/download/v$VERSION/TXTForMac-$VERSION.zip\" sparkle:edSignature=\"$SIG\" length=\"$LENGTH\" type=\"application/octet-stream\" />
      <sparkle:minimumSystemVersion>15.0</sparkle:minimumSystemVersion>
    </item>"

echo "==> 6/7 同步 gh-pages（appcast.xml）"
if git rev-parse --verify origin/gh-pages >/dev/null 2>&1; then
  git fetch origin gh-pages >/dev/null
fi
if git rev-parse --verify gh-pages >/dev/null 2>&1; then
  git worktree remove --force "$FEED_REPO_DIR" 2>/dev/null || true
fi
if git rev-parse --verify -q gh-pages >/dev/null 2>&1; then
  git worktree add "$FEED_REPO_DIR" gh-pages
else
  git worktree add --orphan -b gh-pages "$FEED_REPO_DIR"
  (cd "$FEED_REPO_DIR" && git rm -rf . >/dev/null 2>&1 || true)
fi
cp scripts/appcast-template.xml "$FEED_REPO_DIR/appcast.xml.tmp"
if [ -f "$FEED_REPO_DIR/appcast.xml" ]; then
  python3 - "$FEED_REPO_DIR" "$ITEM" << 'PYEOF'
import sys
feed_dir, item = sys.argv[1], sys.argv[2]
path = feed_dir + '/appcast.xml'
content = open(path, encoding='utf-8').read()
marker = '<!-- 新版本条目由 scripts/release.sh 自动插入到本注释之后 -->'
assert marker in content, 'appcast.xml 缺少插入锚点'
content = content.replace(marker, marker + '\n' + item)
open(path, 'w', encoding='utf-8').write(content)
PYEOF
else
  python3 - "$FEED_REPO_DIR" "$ITEM" << 'PYEOF'
import sys
feed_dir, item = sys.argv[1], sys.argv[2]
template = open(feed_dir + '/appcast.xml.tmp', encoding='utf-8').read()
marker = '<!-- 新版本条目由 scripts/release.sh 自动插入到本注释之后 -->'
content = template.replace(marker, marker + '\n' + item)
open(feed_dir + '/appcast.xml', 'w', encoding='utf-8').write(content)
PYEOF
fi
rm -f "$FEED_REPO_DIR/appcast.xml.tmp"
(cd "$FEED_REPO_DIR" && git add appcast.xml && git commit -m "release: appcast v$VERSION")

echo "==> 7/7 tag + GitHub Release + 推送"
git tag "v$VERSION"
gh release create "v$VERSION" "$ZIP" "$DMG" \
  --title "TXTForMac v$VERSION" \
  --notes "TXTForMac $VERSION

See CHANGELOG.md for details. / 详见 CHANGELOG.md。

**Install / 安装**: download the DMG and drag TXTForMac into Applications.
First launch (unsigned build): right-click the app → Open." \
  --verify-tag
git push origin "v$VERSION"
(cd "$FEED_REPO_DIR" && git push origin gh-pages)

echo ""
echo "✅ v$VERSION 发布完成："
echo "   Release: https://github.com/$REPO/releases/tag/v$VERSION"
echo "   Appcast: https://nonchalantludens.github.io/TXTForMac/appcast.xml"
