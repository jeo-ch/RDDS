#!/usr/bin/env bash

# 鸿蒙分支初始化脚本

echo "=================================="
echo "RustDesk 鸿蒙适配分支初始化"
echo "=================================="
echo ""

# 检查是否在正确的git分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "harmonyos-dev" ]; then
    echo "⚠️  警告：当前分支不是 harmonyos-dev"
    echo "当前分支: $CURRENT_BRANCH"
    read -p "是否切换到 harmonyos-dev 分支? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout harmonyos-dev || git checkout -b harmonyos-dev
    fi
fi

echo ""
echo "✅ 分支检查完成"
echo ""

# 检查鸿蒙项目目录
if [ -d "harmonyos" ]; then
    echo "✅ 鸿蒙项目目录已存在"
else
    echo "❌ 鸿蒙项目目录不存在"
    exit 1
fi

# 检查Rust项目
if [ -d "harmonyos/native/harmony_ffi" ]; then
    echo "✅ Rust NAPI绑定项目已存在"
else
    echo "❌ Rust NAPI绑定项目不存在"
    exit 1
fi

echo ""
echo "=================================="
echo "初始化完成！"
echo "=================================="
echo ""
echo "下一步："
echo "1. 查看 HARMONY_GUIDE.md 了解项目结构"
echo "2. 使用 DevEco Studio 打开 harmonyos/ 目录"
echo "3. 配置鸿蒙Rust工具链（如需要）"
echo ""
