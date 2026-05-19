# HarmonyOS适配说明

## 概述
此分支用于适配鸿蒙操作系统，解决Android APK在鸿蒙上被拦截的问题。

## 架构

### 1. 鸿蒙原生应用
- 使用ArkTS/ArkUI构建鸿蒙原生界面
- 通过NAPI调用Rust核心逻辑

### 2. Rust核心适配
- 使用`napi-rs`构建鸿蒙NAPI绑定
- 屏幕捕获：适配`ScreenCaptureManager` API
- 输入注入：适配`InputManager` API
- 网络层：保持与现有RustDesk核心一致

### 3. Flutter兼容层
- 保留现有的Flutter代码
- 新增`harmony_adapter.dart`用于鸿蒙平台检测和适配

## 项目结构

```
harmonyos/
├── AppScope/              # 应用配置
├── entry/                 # 主模块
│   ├── src/
│   │   ├── main/
│   │   │   ├── ets/       # ArkTS代码
│   │   │   ├── cpp/       # NAPI绑定
│   │   │   └── resources/ # 资源文件
│   │   └── module.json5   # 模块配置
└── native/
    └── harmony_ffi/       # Rust NAPI绑定
        ├── src/
        │   ├── lib.rs
        │   ├── capture.rs
        │   ├── input.rs
        │   ├── connection.rs
        │   └── utils.rs
        └── Cargo.toml
```

## 构建说明

### 1. 构建Rust核心
```bash
cd harmonyos/native/harmony_ffi
# 需要配置鸿蒙Rust工具链
cargo build --release --target aarch64-linux-harmony
```

### 2. 构建鸿蒙应用
```bash
# 使用DevEco Studio打开项目
# 点击Build -> Build Hap(s)/APP(s)
```

## 主要文件说明

### 鸿蒙UI层
- `entry/src/main/ets/pages/Index.ets`: 主页面
- `entry/src/main/ets/pages/RemoteDesktop.ets`: 远程桌面页面
- `entry/src/main/ets/pages/Settings.ets`: 设置页面

### Rust NAPI绑定
- `harmonyos/native/harmony_ffi/src/lib.rs`: NAPI入口
- `harmonyos/native/harmony_ffi/src/capture.rs`: 屏幕捕获实现
- `harmonyos/native/harmony_ffi/src/input.rs`: 输入注入实现
- `harmonyos/native/harmony_ffi/src/connection.rs`: 连接管理

### 原有代码适配
- `libs/scrap/src/harmony/mod.rs`: scrap库鸿蒙适配
- `src/platform/harmony.rs`: 平台抽象层鸿蒙实现
- `flutter/lib/plugin/harmony_adapter.dart`: Flutter兼容层

## 权限说明

在`module.json5`中声明的权限：
- `ohos.permission.INTERNET`: 网络通信
- `ohos.permission.SCREEN_CAPTURE`: 屏幕捕获
- `ohos.permission.INPUT_MONITORING`: 输入监控
- `ohos.permission.MICROPHONE`: 音频权限

## 下一步工作

1. 实现真实的屏幕捕获API调用
2. 实现真实的输入注入API调用
3. 完善连接管理，集成现有RustDesk核心
4. 测试和优化性能
5. 适配鸿蒙应用市场审核规范

## 相关文档

- 鸿蒙NAPI开发指南：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/napi-guides-V5
- 屏幕捕获API：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/native-screencapture-V5
- 输入管理API：https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/native-input-v5
