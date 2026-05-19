#!/bin/bash

# HarmonyOS 项目配置脚本
# 这个脚本会创建一个最小但完整的 HarmonyOS 项目结构

echo "========================================"
echo "  RustDesk HarmonyOS 项目准备"
echo "========================================"

# 确保在正确的目录
cd "$(dirname "$0")/harmonyos" || {
  echo "❌ 无法进入 harmonyos 目录"
  exit 1
}

echo "✅ 项目目录: $(pwd)"

# 创建 .hvigor 目录
if [ ! -d ".hvigor" ]; then
  mkdir -p .hvigor
  echo "✅ 已创建 .hvigor 目录"
fi

# 检查关键文件
REQUIRED_FILES=(
  "hvigorfile.ts"
  "build-profile.json5"
  "oh-package.json5"
  "package.json"
  "entry/hvigorfile.ts"
  "entry/package.json"
  "entry/oh-package.json5"
  "AppScope/app.json5"
)

echo ""
echo "检查必要文件..."
all_ok=true
for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo "✅ $file"
  else
    echo "❌ $file 缺失"
    all_ok=false
  fi
done

echo ""
if [ "$all_ok" = true ]; then
  echo "========================================"
  echo "  ✅ 所有必要文件已准备完成！"
  echo "========================================"
  echo ""
  echo "现在可以在 DevEco Studio 中打开项目："
  echo "1. 启动 DevEco Studio"
  echo "2. 选择 File -> Open"
  echo "3. 选择 $(pwd) 目录"
  echo ""
else
  echo "❌ 部分文件缺失，请检查"
  exit 1
fi
