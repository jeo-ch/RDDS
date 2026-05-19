/**
 * RustDesk HarmonyOS NAPI Module
 * 
 * NAPI binding layer for Rust core
 */

#include <napi/native_api.h>
#include <napi/native_common.h>
#include <cstring>
#include <cstdlib>

// Logging
static napi_env global_env = nullptr;

namespace rustdesk_napi {

// Helper for error handling
static napi_value create_error(napi_env env, const char* message) {
  napi_value error;
  napi_create_error(env, nullptr, nullptr, &error);
  return error;
}

// Helper for string conversion
static char* get_string_utf8(napi_env env, napi_value value, size_t* length) {
  size_t len;
  napi_get_value_string_utf8(env, value, nullptr, 0, &len);
  char* buffer = (char*)malloc(len + 1);
  napi_get_value_string_utf8(env, value, buffer, len + 1, &len);
  if (length) *length = len;
  return buffer;
}

/**
 * Initialize native module
 */
static napi_value initialize(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value argv[1];
  
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  
  if (argc < 1) {
    return create_error(env, "Missing app directory argument");
  }
  
  char* app_dir = get_string_utf8(env, argv[0], nullptr);
  
  // TODO: Call Rust core initialization
  // rust_core_initialize(app_dir);
  
  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Get local device ID
 */
static napi_value get_local_id(napi_env env, napi_callback_info info) {
  // TODO: Call Rust core
  const char* mock_id = "TEST123456";
  
  napi_value result;
  napi_create_string_utf8(env, mock_id, strlen(mock_id), &result);
  return result;
}

/**
 * Connect to remote peer
 */
static napi_value connect_to_peer(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value argv[2];
  
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  
  if (argc < 1) {
    return create_error(env, "Missing peer ID argument");
  }
  
  char* peer_id = get_string_utf8(env, argv[0], nullptr);
  char* password = (argc >= 2) ? get_string_utf8(env, argv[1], nullptr) : nullptr;
  
  // TODO: Call Rust core connection
  // bool result = rust_core_connect_to_peer(peer_id, password);
  
  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Disconnect
 */
static napi_value disconnect(napi_env env, napi_callback_info info) {
  // TODO: Call Rust core disconnect
  // rust_core_disconnect();
  
  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Inject mouse movement
 */
static napi_value inject_mouse_move(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value argv[2];
  
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  
  if (argc < 2) {
    return create_error(env, "Missing arguments");
  }
  
  int32_t x, y;
  napi_get_value_int32(env, argv[0], &x);
  napi_get_value_int32(env, argv[1], &y);
  
  // TODO: Call input injection
  // rust_core_inject_mouse_move(x, y);
  
  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Inject mouse click
 */
static napi_value inject_mouse_click(napi_env env, napi_callback_info info) {
  size_t argc = 4;
  napi_value argv[4];
  
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  
  if (argc < 4) {
    return create_error(env, "Missing arguments");
  }
  
  int32_t x, y, button;
  bool down;
  napi_get_value_int32(env, argv[0], &x);
  napi_get_value_int32(env, argv[1], &y);
  napi_get_value_int32(env, argv[2], &button);
  napi_get_value_bool(env, argv[3], &down);
  
  // TODO: Call input injection
  // rust_core_inject_mouse_click(x, y, button, down);
  
  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Inject keyboard event
 */
static napi_value inject_key(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value argv[2];
  
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);
  
  if (argc < 2) {
    return create_error(env, "Missing arguments");
  }
  
  int32_t key_code;
  bool down;
  napi_get_value_int32(env, argv[0], &key_code);
  napi_get_value_bool(env, argv[1], &down);
  
  // TODO: Call input injection
  // rust_core_inject_key(key_code, down);
  
  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Capture screen frame
 */
static napi_value capture_screen_frame(napi_env env, napi_callback_info info) {
  // TODO: Call screen capture
  // Return mock data for now
  size_t size = 1280 * 720 * 4;
  uint8_t* data = (uint8_t*)malloc(size);
  
  napi_value buffer;
  napi_create_external_arraybuffer(env, data, size, nullptr, nullptr, &buffer);
  
  return buffer;
}

/**
 * Get version
 */
static napi_value get_version(napi_env env, napi_callback_info info) {
  const char* version = "1.0.0-harmony";
  
  napi_value result;
  napi_create_string_utf8(env, version, strlen(version), &result);
  return result;
}

/**
 * Module registration
 */
static napi_value register_module(napi_env env, napi_value exports) {
  napi_property_descriptor desc[] = {
    {"initialize", nullptr, initialize, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"getLocalId", nullptr, get_local_id, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"connectToPeer", nullptr, connect_to_peer, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"disconnect", nullptr, disconnect, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"injectMouseMove", nullptr, inject_mouse_move, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"injectMouseClick", nullptr, inject_mouse_click, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"injectKey", nullptr, inject_key, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"captureScreenFrame", nullptr, capture_screen_frame, nullptr, nullptr, nullptr, napi_default, nullptr},
    {"getVersion", nullptr, get_version, nullptr, nullptr, nullptr, napi_default, nullptr},
  };
  
  napi_define_properties(env, exports, sizeof(desc) / sizeof(napi_property_descriptor), desc);
  
  global_env = env;
  
  return exports;
}

} // namespace rustdesk_napi

// Register the module
static napi_module rustdesk_module = {
  .nm_version = 1,
  .nm_flags = 0,
  .nm_filename = nullptr,
  .nm_register_func = rustdesk_napi::register_module,
  .nm_modname = "rustdesk_napi",
  .nm_priv = ((void*)0),
  .reserved = {0},
};

extern "C" __attribute__((constructor)) void register_rustdesk_module(void) {
  napi_module_register(&rustdesk_module);
}
