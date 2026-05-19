#!/usr/bin/env bash
#
# HarmonyOS 开发工具脚本
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARMONY_DIR="${PROJECT_ROOT}/harmonyos"
RUST_CORE_DIR="${HARMONY_DIR}/native/harmony_ffi"

log_info() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

check_git_status() {
  log_info "检查 Git 状态..."
  cd "${PROJECT_ROOT}"
  
  local branch=$(git rev-parse --abbrev-ref HEAD)
  echo "当前分支: ${branch}"
  
  if [[ "$branch" != "harmonyos-dev" ]]; then
    log_warn "当前不是 harmonyos-dev 分支"
    read -p "是否切换到 harmonyos-dev 分支? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      git checkout -b harmonyos-dev 2>/dev/null || git checkout harmonyos-dev
    fi
  fi
  
  git status
}

check_rust() {
  log_info "检查 Rust 环境..."
  if ! command -v rustc &> /dev/null; then
    log_error "Rust 未安装，请先安装 Rust"
    exit 1
  fi
  
  echo "Rust 版本: $(rustc --version)"
  echo "Cargo 版本: $(cargo --version)"
}

build_rust_core() {
  log_info "构建 Rust 核心..."
  cd "${RUST_CORE_DIR}"
  
  if [ ! -f "Cargo.toml" ]; then
    log_error "找不到 Cargo.toml"
    exit 1
  fi
  
  # 这里需要配置鸿蒙的 Rust 工具链
  # 实际开发时需要:
  # 1. 安装鸿蒙 Rust 工具链
  # 2. 配置 target
  
  log_info "检查 Rust 核心代码..."
  cargo check --quiet
  
  if [ $? -eq 0 ]; then
    log_info "Rust 代码检查通过"
  else
    log_warn "Rust 代码检查有警告或错误"
  fi
}

list_files() {
  log_info "项目文件结构:"
  echo ""
  echo "harmonyos/"
  find "${HARMONY_DIR}" -type f -name "*.ets" -o -name "*.rs" -o -name "*.json" -o -name "*.toml" -o -name "*.sh" 2>/dev/null | head -30 | sed "s#${PROJECT_ROOT}/##"
  echo ""
  echo "... 以及更多文件"
}

show_help() {
  echo "RustDesk HarmonyOS 开发工具"
  echo ""
  echo "用法: $0 [命令]"
  echo ""
  echo "命令:"
  echo "  status    - 检查项目状态"
  echo "  build     - 构建 Rust 核心"
  echo "  list      - 列出项目文件"
  echo "  help      - 显示此帮助"
  echo ""
}

case "${1:-status}" in
  status)
    check_git_status
    check_rust
    list_files
    ;;
  build)
    build_rust_core
    ;;
  list)
    list_files
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    log_error "未知命令: $1"
    show_help
    exit 1
    ;;
esac

echo ""
log_info "完成!"
