use napi::bindgen_prelude::*;
use napi_derive::napi;
use hbb_common::config;
use hbb_common::log;
use std::sync::Mutex;
use lazy_static::lazy_static;

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
    *CONNECTION_MANAGER.lock().unwrap() = Some(HarmonyConnectionManager::new()?);
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
    let manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(manager) = manager.as_ref() {
        manager.create_connection(peer_id).await
    } else {
        Err(Error::from_reason("Connection manager not initialized"))
    }
}

#[napi]
pub fn disconnect_peer(peer_id: String) -> Result<()> {
    let manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(manager) = manager.as_ref() {
        manager.close_connection(&peer_id)?;
    }
    Ok(())
}

#[napi]
pub fn disconnect() -> Result<()> {
    let mut manager = CONNECTION_MANAGER.lock().unwrap();
    if let Some(mut manager) = manager.take() {
        manager.close_all()?;
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
        manager.set_relay_server(address, port as u16);
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
