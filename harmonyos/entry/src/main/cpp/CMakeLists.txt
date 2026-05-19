cmake_minimum_required(VERSION 3.16)
project(RustDeskHarmony)

# 设置输出目录
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 设置 C++ 标准
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 编译选项
add_compile_options(-Wall -Wextra -Werror -O2)

# 添加 NAPI 头文件
if(EXISTS ${CMAKE_SYSROOT}/usr/include/napi)
  include_directories(${CMAKE_SYSROOT}/usr/include/napi)
endif()

# 查找 NAPI 库
find_library(NAPI_LIBRARY napi)
if(NOT NAPI_LIBRARY)
  message(FATAL_ERROR "NAPI library not found")
endif()

# 创建 NAPI 绑定库
add_library(rustdesk_napi SHARED
  napi_bindings.cpp
  napi_module.cpp
)

# 链接 NAPI 库
target_link_libraries(rustdesk_napi PRIVATE
  ${NAPI_LIBRARY}
  hilog_ndk.z
)

# 设置库属性
set_target_properties(rustdesk_napi PROPERTIES
  LINK_FLAGS "-Wl,--hash-style=both"
)

# Rust 核心库链接（当可用时）
# if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/../../native/harmony_ffi/target/aarch64-unknown-linux-ohos/release/librustdesk_core.a)
#   add_library(rustdesk_core STATIC IMPORTED)
#   set_target_properties(rustdesk_core PROPERTIES
#     IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../../native/harmony_ffi/target/aarch64-unknown-linux-ohos/release/librustdesk_core.a
#   )
#   target_link_libraries(rustdesk_napi PRIVATE rustdesk_core)
# endif()
