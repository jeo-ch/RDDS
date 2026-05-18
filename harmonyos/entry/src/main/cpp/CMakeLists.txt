cmak_minimum_required(VERSION 3.16)
project(RustDeskHarmony)

# 设置输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 设置Rust编译路径
set(RUST_PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../../../../harmonyos/native/harmony_ffi)

# 添加Rust静态库
add_library(rustdesk_core STATIC IMPORTED)

# 设置Rust库的路径 - 实际需要根据编译结果调整
if(${CMAKE_ANDROID_ARCH_ABI} STREQUAL "arm64-v8a")
    set_target_properties(rustdesk_core PROPERTIES IMPORTED_LOCATION
        ${RUST_PROJECT_DIR}/target/aarch64-linux-harmony/release/librustdesk_core.a)
elseif(${CMAKE_ANDROID_ARCH_ABI} STREQUAL "armeabi-v7a")
    set_target_properties(rustdesk_core PROPERTIES IMPORTED_LOCATION
        ${RUST_PROJECT_DIR}/target/armv7-linux-harmony/release/librustdesk_core.a)
endif()

# 创建NAPI绑定
add_library(rustdesk_napi SHARED napi_bindings.cpp)

# 链接Rust库和鸿蒙NAPI库
target_link_libraries(rustdesk_napi PRIVATE rustdesk_core)

# 包含NAPI头文件
target_include_directories(rustdesk_napi PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/../../../../harmonyos/native/harmony_ffi)
