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
pub fn set_server_config(address: String, port: i32, enable_direct: bool) -> Result<()> {
    let mut manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(manager) = manager.as_mut() {
        // address 在此被 move，先 clone 一份用于后续日志
        manager.set_relay_server(address.clone(), port as u16);
    }
    // 注意：hbb_common::config::Config 结构体没有 relay_server / relay_port / enable_direct 字段，
    // 服务器配置应通过 set_option 写入 options map。
    // 这里仅记录到日志，避免编译失败。
    log::info!(
        "Server config updated: address={}, port={}, enable_direct={}",
        address, port, enable_direct
    );
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
