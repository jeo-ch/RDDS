/**
 * RustDesk HarmonyOS NAPI Module
 *
 * NAPI binding layer for Rust core
 *
 * 注意：当前为占位实现。当 Rust 静态库 librustdesk_core.a 链接后，
 * 应将各 TODO 替换为对 Rust 导出函数的真实调用。
 */

#include <napi/native_api.h>
#include <napi/native_common.h>
#include <hilog/log.h>
#include <cstring>
#include <cstdlib>
#include <cstdint>

#define LOG_DOMAIN 0x3200
#define LOG_TAG "RustDeskNAPI"
#define NAPI_LOGI(fmt, ...) OH_LOG_PRINT(LOG_INFO, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)
#define NAPI_LOGE(fmt, ...) OH_LOG_PRINT(LOG_ERROR, LOG_DOMAIN, LOG_TAG, fmt, ##__VA_ARGS__)

namespace rustdesk_napi {

// Helper for error handling
static napi_value create_error(napi_env env, const char* message) {
  napi_value code, msg, error;
  napi_create_string_utf8(env, "RUSTDESK_ERROR", NAPI_AUTO_LENGTH, &code);
  napi_create_string_utf8(env, message, NAPI_AUTO_LENGTH, &msg);
  napi_create_error(env, code, msg, &error);
  return error;
}

// Helper for string conversion，调用方负责 free 返回的 buffer
static char* get_string_utf8(napi_env env, napi_value value, size_t* length) {
  size_t len = 0;
  if (napi_get_value_string_utf8(env, value, nullptr, 0, &len) != napi_ok) {
    if (length) *length = 0;
    return nullptr;
  }
  char* buffer = (char*)malloc(len + 1);
  if (!buffer) {
    if (length) *length = 0;
    return nullptr;
  }
  if (napi_get_value_string_utf8(env, value, buffer, len + 1, &len) != napi_ok) {
    free(buffer);
    if (length) *length = 0;
    return nullptr;
  }
  if (length) *length = len;
  return buffer;
}

/**
 * Initialize native module
 */
static napi_value initialize(napi_env env, napi_callback_info info) {
  size_t argc = 1;
  napi_value argv[1] = {nullptr};
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

  if (argc < 1) {
    return create_error(env, "Missing app directory argument");
  }

  size_t len = 0;
  char* app_dir = get_string_utf8(env, argv[0], &len);
  if (!app_dir) {
    return create_error(env, "Failed to parse app directory");
  }

  NAPI_LOGI("initialize called, app_dir=%{public}s len=%{public}zu", app_dir, len);
  // TODO: rust_core_initialize(app_dir);
  free(app_dir);

  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Get local device ID
 */
static napi_value get_local_id(napi_env env, napi_callback_info info) {
  // TODO: rust_core_get_local_id();
  const char* mock_id = "TEST123456";

  napi_value result;
  napi_create_string_utf8(env, mock_id, NAPI_AUTO_LENGTH, &result);
  return result;
}

/**
 * Connect to remote peer
 */
static napi_value connect_to_peer(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value argv[2] = {nullptr, nullptr};
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

  if (argc < 1) {
    return create_error(env, "Missing peer ID argument");
  }

  char* peer_id = get_string_utf8(env, argv[0], nullptr);
  char* password = (argc >= 2) ? get_string_utf8(env, argv[1], nullptr) : nullptr;

  if (!peer_id) {
    if (password) free(password);
    return create_error(env, "Failed to parse peer ID");
  }

  NAPI_LOGI("connect_to_peer: peer_id=%{public}s password_len=%{public}zu",
            peer_id, password ? strlen(password) : 0);
  // TODO: bool result = rust_core_connect_to_peer(peer_id, password);
  // 当前为模拟实现：等待 1.5s 后返回 true
  bool mock_result = true;

  free(peer_id);
  if (password) free(password);

  napi_value result;
  napi_get_boolean(env, mock_result, &result);
  return result;
}

/**
 * Disconnect
 */
static napi_value disconnect(napi_env env, napi_callback_info info) {
  NAPI_LOGI("disconnect called");
  // TODO: rust_core_disconnect();

  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Inject mouse movement
 */
static napi_value inject_mouse_move(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value argv[2] = {nullptr, nullptr};
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

  if (argc < 2) {
    return create_error(env, "Missing arguments");
  }

  double x = 0, y = 0;
  napi_get_value_double(env, argv[0], &x);
  napi_get_value_double(env, argv[1], &y);

  // TODO: rust_core_inject_mouse_move(x, y);
  NAPI_LOGI("inject_mouse_move: x=%{public}f y=%{public}f", x, y);

  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Inject mouse click
 */
static napi_value inject_mouse_click(napi_env env, napi_callback_info info) {
  size_t argc = 4;
  napi_value argv[4] = {nullptr, nullptr, nullptr, nullptr};
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

  if (argc < 4) {
    return create_error(env, "Missing arguments");
  }

  double x = 0, y = 0;
  int32_t button = 0;
  bool down = false;
  napi_get_value_double(env, argv[0], &x);
  napi_get_value_double(env, argv[1], &y);
  napi_get_value_int32(env, argv[2], &button);
  napi_get_value_bool(env, argv[3], &down);

  // TODO: rust_core_inject_mouse_click(x, y, button, down);
  NAPI_LOGI("inject_mouse_click: x=%{public}f y=%{public}f btn=%{public}d down=%{public}d",
            x, y, button, down ? 1 : 0);

  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

/**
 * Inject keyboard event
 */
static napi_value inject_key(napi_env env, napi_callback_info info) {
  size_t argc = 2;
  napi_value argv[2] = {nullptr, nullptr};
  napi_get_cb_info(env, info, &argc, argv, nullptr, nullptr);

  if (argc < 2) {
    return create_error(env, "Missing arguments");
  }

  int32_t key_code = 0;
  bool down = false;
  napi_get_value_int32(env, argv[0], &key_code);
  napi_get_value_bool(env, argv[1], &down);

  // TODO: rust_core_inject_key(key_code, down);
  NAPI_LOGI("inject_key: code=%{public}d down=%{public}d", key_code, down ? 1 : 0);

  napi_value result;
  napi_get_boolean(env, true, &result);
  return result;
}

// Finalizer：用于释放 napi_create_external_arraybuffer 分配的内存
static void arraybuffer_finalize_cb(napi_env env, void* data, void* hint) {
  (void)env;
  (void)hint;
  if (data) {
    free(data);
  }
}

/**
 * Capture screen frame
 */
static napi_value capture_screen_frame(napi_env env, napi_callback_info info) {
  // TODO: rust_core_capture_screen_frame() 返回真实帧数据
  // 当前生成 1x1 的 BGRA 测试帧（避免大块内存分配和泄漏）
  const size_t kWidth = 1;
  const size_t kHeight = 1;
  const size_t size = kWidth * kHeight * 4;
  uint8_t* data = (uint8_t*)malloc(size);
  if (!data) {
    return create_error(env, "Failed to allocate frame buffer");
  }
  // 黑色不透明像素
  data[0] = 0;   // B
  data[1] = 0;   // G
  data[2] = 0;   // R
  data[3] = 255; // A

  napi_value buffer;
  napi_status status = napi_create_external_arraybuffer(env, data, size,
                                                       arraybuffer_finalize_cb, nullptr, &buffer);
  if (status != napi_ok) {
    free(data);
    return create_error(env, "Failed to create arraybuffer");
  }
  return buffer;
}

/**
 * Get version
 */
static napi_value get_version(napi_env env, napi_callback_info info) {
  const char* version = "1.4.6-harmony";

  napi_value result;
  napi_create_string_utf8(env, version, NAPI_AUTO_LENGTH, &result);
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

  NAPI_LOGI("RustDesk NAPI module registered");
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
