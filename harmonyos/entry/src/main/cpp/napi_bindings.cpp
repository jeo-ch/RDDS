// NAPI绑定包装
#include <napi/napi.h>

// 实际开发中需要调用Rust编译好的库
// 这里是一个占位文件，实际需要在Rust编译出.h文件后使用

namespace {

// 初始化函数
napi_value Init(napi_env env, napi_value exports) {
    return exports;
}

}

// 注册NAPI模块
NAPI_MODULE(rustdesk_core, Init)
