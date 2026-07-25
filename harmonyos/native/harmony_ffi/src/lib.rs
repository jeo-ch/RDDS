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
    // home dir 取上一层（与 flutter_ffi.rs 中 _home 的语义一致）
    let app_home_dir = std::path::Path::new(&app_dir)
        .parent()
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_else(|| app_dir.clone());
    #[cfg(any(target_os = "android", target_os = "ios"))]
    {
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
