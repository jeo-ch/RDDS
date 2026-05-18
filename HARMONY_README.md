# RustDesk HarmonyOS 适配

这是为了避免原 Android 版本被鸿蒙系统拦截而重写的鸿蒙原生版本。

## 架构

### 前端 (ArkTS)
- 鸿蒙原生 UI，不会被系统拦截
- 通过 NAPI 调用 Rust 核心

### 后端 (Rust)
- 复用 RustDesk 核心逻辑
- 提供 NAPI 绑定给 ArkTS 调用
- 使用鸿蒙官方的 API 进行屏幕捕获和输入注入

## 项目结构

```
harmonyos/
├── AppScope/              # 应用配置
├── entry/
│   ├── src/main/
│   │   ├── ets/
│   │   │   ├── pages/          # UI 页面
│   │   │   │   ├── Index.ets
│   │   │   │   ├── RemoteDesktop.ets
│   │   │   │   └── Settings.ets
│   │   │   ├── utils/          # 工具函数
│   │   │   │   └── RustDeskCore.ets
│   │   │   └── entryability/
│   │   ├── cpp/            # NAPI 绑定占位符
│   │   └── resources/
│   └── module.json5
└── native/harmony_ffi/     # Rust NAPI 绑定
    ├── src/
    │   ├── lib.rs         # NAPI 入口
    │   ├── capture.rs     # 屏幕捕获
    │   ├── input.rs       # 输入注入
    │   ├── connection.rs  # 连接管理
    │   └── video.rs       # 视频解码
    └── Cargo.toml
```

## 开发指南

### 1. 环境准备

- DevEco Studio (鸿蒙开发 IDE)
- Rust 工具链 (需要鸿蒙支持)
- Node.js (可选)

### 2. 快速开始

```bash
# 进入项目目录
cd /workspace

# 检查当前分支 (应该在 harmonyos-dev)
./harmony_tool.sh status

# 列出项目文件
./harmony_tool.sh list
```

### 3. 使用 DevEco Studio 开发

1. 打开 DevEco Studio
2. 选择 "打开项目"
3. 选择 `/workspace/harmonyos` 目录
4. 等待项目同步完成
5. 连接鸿蒙设备或启动模拟器
6. 点击运行按钮

## 核心模块说明

### 屏幕捕获 (capture.rs)
- 使用鸿蒙 ScreenCaptureManager API
- 支持多显示器
- 自动格式转换

### 输入注入 (input.rs)
- 使用鸿蒙 InputManager API
- 支持鼠标和键盘
- 完整的按键映射表

### 连接管理 (connection.rs)
- 复用现有的 RustDesk 协议
- 支持中继服务器
- NAT 穿透

### 视频解码 (video.rs)
- 支持硬件解码
- 帧缓冲区管理
- 图像缩放和格式转换

## 下一步工作

- [ ] 配置鸿蒙 Rust 工具链
- [ ] 实现真实的屏幕捕获 API 调用
- [ ] 实现真实的输入注入 API 调用
- [ ] 完整集成 RustDesk 核心
- [ ] 测试和性能优化
- [ ] 应用市场适配

## 注意事项

1. 本分支专门用于鸿蒙适配，不要将其他分支的代码直接合并
2. 所有修改都应该在 `harmonyos-dev` 分支进行
3. 主要文档在 `HARMONY_GUIDE.md` 中

## 相关链接

- [鸿蒙 NAPI 开发](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/napi-guides-V5)
- [屏幕捕获 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/native-screencapture-V5)
- [输入管理 API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/native-input-v5)
