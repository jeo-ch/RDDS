use napi::bindgen_prelude::*;
use napi_derive::napi;
use hbb_common::config;
use hbb_common::log;
use std::sync::Mutex;
use lazy_static::lazy_static;

// hbb_common 使用 anyhow::Error，napi 使用 napi::Error，两者不兼容，
// 这里提供一个统一的转换辅助函数。
fn map_err<E: std::fmt::Display>(e: E) -> Error {
    Error::from_reason(e.to_string())
}

mod capture;
mod input;
mod connection;
mod video;
mod utils;

pub use capture::HarmonyScreenCapturer;
pub use input::HarmonyInputInjector;
pub use connection::{HarmonyConnectionManager, ConnectionState};
pub use video::{VideoFrame, FrameBuffer, HarmonyVideoDecoder, PixelFormat};

lazy_static! {
    static ref INITIALIZED: Mutex<bool> = Mutex::new(false);
    static ref CAPTURER: Mutex<Option<HarmonyScreenCapturer>> = Mutex::new(None);
    static ref INPUT_INJECTOR: Mutex<Option<HarmonyInputInjector>> = Mutex::new(None);
    static ref CONNECTION_MANAGER: Mutex<Option<HarmonyConnectionManager>> = Mutex::new(None);
    static ref VIDEO_DECODER: Mutex<Option<HarmonyVideoDecoder>> = Mutex::new(None);
}

#[napi]
pub fn initialize(app_dir: String) -> Result<()> {
    let mut initialized = INITIALIZED.lock().unwrap();
    if *initialized {
        return Ok(());
    }

    log::info!("Initializing RustDesk for HarmonyOS, app_dir: {}", app_dir);

    // 鸿蒙按 android target 编译，Config::path() 走 APP_DIR 分支，
    // init_log 走 APP_HOME_DIR 分支，两者都必须先设置，否则
    // RustDesk.toml / RustDesk2.toml 会写到空路径，日志也会被跳过。
    // app_dir 形如 /data/storage/el2/base/haps/entry/files
    *config::APP_DIR.write().unwrap() = app_dir.clone();
    // home dir 取上一层（与 flutter_ffi.rs 中 _home 的语义一致）。
    // 仅 android/ios target 需要 APP_HOME_DIR，把计算放进 cfg 块
    // 避免在其他 target 下产生 unused variable 警告。
    #[cfg(any(target_os = "android", target_os = "ios"))]
    {
        let app_home_dir = std::path::Path::new(&app_dir)
            .parent()
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_else(|| app_dir.clone());
        *config::APP_HOME_DIR.write().unwrap() = app_home_dir;
    }

    // hbb_common::init_log 返回 Option<LoggerHandle>，丢弃返回值即可
    let _ = hbb_common::init_log(false, "harmony");

    *CAPTURER.lock().unwrap() = Some(HarmonyScreenCapturer::new()?);
    *INPUT_INJECTOR.lock().unwrap() = Some(HarmonyInputInjector::new()?);
    *CONNECTION_MANAGER.lock().unwrap() = Some(HarmonyConnectionManager::new().map_err(map_err)?);
    *VIDEO_DECODER.lock().unwrap() = Some(HarmonyVideoDecoder::new()?);

    *initialized = true;
    log::info!("RustDesk HarmonyOS core initialized successfully");

    Ok(())
}

#[napi]
pub fn get_local_id() -> Result<String> {
    // hbb_common::config::Config::get_id 是静态方法
    let id = config::Config::get_id();
    Ok(id)
}

#[napi]
pub async fn connect_to_peer(peer_id: String, password: String) -> Result<bool> {
    log::info!("connect_to_peer: peer_id={}, password_len={}", peer_id, password.len());

    // 获取 relay 配置后立即释放 CONNECTION_MANAGER 锁，
    // 避免跨 .await 持有 std::sync::MutexGuard（不满足 Send）。
    let (relay_server, relay_port) = {
        let manager = CONNECTION_MANAGER.lock().unwrap();
        match manager.as_ref() {
            Some(m) => m.get_relay_config(),
            None => return Err(Error::from_reason("Connection manager not initialized")),
        }
    };

    // 在锁外进行异步连接
    let mut session = connection::ConnectionSession::new(peer_id.clone());
    match session.connect(&relay_server, relay_port).await {
        Ok(success) => {
            if success {
                // 重新获取锁 push session
                let manager = CONNECTION_MANAGER.lock().unwrap();
                if let Some(manager) = manager.as_ref() {
                    manager.add_session(session);
                }
                Ok(true)
            } else {
                Ok(false)
            }
        }
        Err(e) => {
            log::error!("Failed to create connection: {}", e);
            Ok(false)
        }
    }
}

#[napi]
pub fn disconnect_peer(peer_id: String) -> Result<()> {
    let manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(manager) = manager.as_ref() {
        manager.close_connection(&peer_id).map_err(map_err)?;
    }
    Ok(())
}

#[napi]
pub fn disconnect() -> Result<()> {
    let mut manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(mut manager) = manager.take() {
        manager.close_all().map_err(map_err)?;
    }
    Ok(())
}

#[napi]
pub fn get_connection_state(peer_id: String) -> Result<String> {
    let manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(manager) = manager.as_ref() {
        let state = manager.get_connection_state(&peer_id);
        Ok(format!("{:?}", state))
    } else {
        Ok("Disconnected".to_string())
    }
}

#[napi]
pub fn set_server_config(
    rendezvous_server: String,
    api_server: String,
    relay_server: String,
    key: String,
) -> Result<()> {
    // 写入主项目正式的 option 字段，会自动持久化到 RustDesk2.toml，
    // 后续 RendezvousMediator 启动连接时会自动读取应用。
    config::Config::set_option(
        config::keys::OPTION_CUSTOM_RENDEZVOUS_SERVER.to_string(),
        rendezvous_server.clone(),
    );
    config::Config::set_option(
        config::keys::OPTION_API_SERVER.to_string(),
        api_server.clone(),
    );
    config::Config::set_option(
        config::keys::OPTION_RELAY_SERVER.to_string(),
        relay_server.clone(),
    );
    config::Config::set_option(config::keys::OPTION_KEY.to_string(), key.clone());

    // 同步更新内存中的 ConnectionManager 的 relay 配置（用于 mock 连接路径）
    let mut manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(manager) = manager.as_mut() {
        // 解析 host:port，没有 port 时使用默认 21117
        let (host, p) = if let Some((h, p)) = relay_server.rsplit_once(':') {
            (h.to_string(), p.parse::<u16>().unwrap_or(21117))
        } else {
            (relay_server.clone(), 21117)
        };
        manager.set_relay_server(host, p);
    }

    log::info!(
        "Server config updated: rendezvous={}, api={}, relay={}, key_len={}",
        rendezvous_server,
        api_server,
        relay_server,
        key.len()
    );
    Ok(())
}

/// 通用 option 写入接口（覆盖 verification-method / approve-mode / temporary-password-length 等）
#[napi]
pub fn set_option(key: String, value: String) -> Result<()> {
    log::info!("set_option: key={}, value_len={}", key, value.len());
    config::Config::set_option(key, value);
    Ok(())
}

/// 通用 option 读取接口
#[napi]
pub fn get_option(key: String) -> Result<String> {
    Ok(config::Config::get_option(&key))
}

/// 设置固定密码（永久密码）
/// 内部用 SHA256(password‖salt) 哈希后存入 RustDesk.toml，并清空 trusted_devices。
/// 返回 false 表示被 disable-change-permanent-password 锁定或新旧值相同。
#[napi]
pub fn set_permanent_password(password: String) -> Result<bool> {
    log::info!("set_permanent_password: password_len={}", password.len());
    Ok(config::Config::set_permanent_password(&password))
}

/// 查询当前是否已设置固定密码（含 HARD_SETTINGS 预设）
#[napi]
pub fn has_permanent_password() -> Result<bool> {
    Ok(config::Config::has_permanent_password())
}

/// 验证明文密码是否与当前固定密码匹配
/// 用于 UI 端"输入密码后立即验证"，避免格式错误导致登录失败
#[napi]
pub fn matches_permanent_password(password: String) -> Result<bool> {
    Ok(config::Config::matches_permanent_password_plain(&password))
}

/// 设置 Socks5 代理
/// 传入空 proxy 表示清除代理
#[napi]
pub fn set_socks(proxy: String, username: String, password: String) -> Result<()> {
    let socks = if proxy.is_empty() {
        None
    } else {
        Some(config::Socks5Server {
            proxy,
            username,
            password,
        })
    };
    log::info!("set_socks: proxy_set={}", socks.is_some());
    config::Config::set_socks(socks);
    Ok(())
}

#[napi]
pub fn inject_mouse_move(x: f64, y: f64) -> Result<()> {
    let injector = INPUT_INJECTOR.lock().unwrap();
    if let Some(injector) = injector.as_ref() {
        injector.inject_mouse_move(x as i32, y as i32)?;
    }
    Ok(())
}

#[napi]
pub fn inject_mouse_click(x: f64, y: f64, button: i32, down: bool) -> Result<()> {
    let injector = INPUT_INJECTOR.lock().unwrap();
    if let Some(injector) = injector.as_ref() {
        injector.inject_mouse_button(x as i32, y as i32, button, down)?;
    }
    Ok(())
}

#[napi]
pub fn inject_key(key_code: i32, down: bool) -> Result<()> {
    let injector = INPUT_INJECTOR.lock().unwrap();
    if let Some(injector) = injector.as_ref() {
        injector.inject_key(key_code, down)?;
    }
    Ok(())
}

#[napi]
pub fn capture_screen_frame() -> Result<Buffer> {
    let capturer = CAPTURER.lock().unwrap();
    if let Some(capturer) = capturer.as_ref() {
        let frame = capturer.capture_frame()?;
        Ok(Buffer::from(frame))
    } else {
        Err(Error::from_reason("Screen capturer not initialized"))
    }
}

#[napi]
pub fn get_version() -> Result<String> {
    Ok("1.4.6-harmony".to_string())
}

#[napi]
pub fn get_build_info() -> Result<String> {
    Ok(format!("Build on {} for HarmonyOS", std::env::consts::OS))
}

// =============================================================================
// C ABI 导出（供 napi_bindings.cpp 通过 extern "C" 直接调用）
//
// 设计意图：
//   - napi_bindings.cpp 是鸿蒙 NAPI 模块的唯一注册入口（nm_modname="rustdesk_napi"），
//     ArkTS 端 `requireNapi('rustdesk_napi')` 加载的就是这个 C++ 模块。
//   - Rust 静态库 librustdesk_core.a 链接进来后，必须通过 C ABI 暴露函数
//     才能被 C++ 调用（#[napi] 宏生成的符号依赖 NAPI 运行时，无法直接 extern）。
//   - 因此这里为「关键函数」额外提供 #[no_mangle] extern "C" 包装，
//     专门给 napi_bindings.cpp 使用；#[napi] 版本保留给「直接用 Rust napi 模块」的路径。
//
// 调用约定：
//   - 输入字符串以 (ptr, len) 形式传递，不依赖 C null 终止（避免密码内含 \0 时截断）。
//   - 输入字符串所有权不转移（C 侧仍负责释放原 buffer）。
//   - 出参仅返回简单 bool，错误用 false 表达（与 napi_bindings.cpp 现有 mock 行为兼容）。
// =============================================================================

/// 查询当前是否已设置固定密码（含 HARD_SETTINGS 预设）
#[no_mangle]
pub extern "C" fn rust_core_has_permanent_password() -> bool {
    config::Config::has_permanent_password()
}

/// 验证明文密码是否与当前固定密码匹配
/// 输入：UTF-8 字节切片 (ptr, len)，空指针或零长度返回 false
#[no_mangle]
pub extern "C" fn rust_core_matches_permanent_password(
    password: *const u8,
    password_len: usize,
) -> bool {
    if password.is_null() || password_len == 0 {
        return false;
    }
    // SAFETY: 调用方（napi_bindings.cpp）保证 password 指向至少 password_len 字节的有效内存
    let bytes = unsafe { std::slice::from_raw_parts(password, password_len) };
    let pwd = match std::str::from_utf8(bytes) {
        Ok(s) => s,
        Err(_) => {
            log::warn!(
                "rust_core_matches_permanent_password: input is not valid UTF-8 (len={})",
                password_len
            );
            return false;
        }
    };
    config::Config::matches_permanent_password_plain(pwd)
}

/// 设置固定密码
/// 输入：UTF-8 字节切片 (ptr, len)
/// - 空指针或零长度：等价于清除密码
/// 返回 false 表示被 disable-change-permanent-password 锁定或新旧值相同
#[no_mangle]
pub extern "C" fn rust_core_set_permanent_password(
    password: *const u8,
    password_len: usize,
) -> bool {
    let pwd: String = if password.is_null() || password_len == 0 {
        String::new()
    } else {
        // SAFETY: 同上
        let bytes = unsafe { std::slice::from_raw_parts(password, password_len) };
        match std::str::from_utf8(bytes) {
            Ok(s) => s.to_owned(),
            Err(_) => {
                log::warn!(
                    "rust_core_set_permanent_password: input is not valid UTF-8 (len={})",
                    password_len
                );
                return false;
            }
        }
    };
    config::Config::set_permanent_password(&pwd)
}
