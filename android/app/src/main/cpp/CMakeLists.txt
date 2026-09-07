cmake_minimum_required(VERSION 3.22.1)
project(edith_native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# llama.cpp is vendored as a trimmed, CPU-only checkout under
# android/app/src/main/cpp/llama.cpp (see /tools/vendor_llama.sh).
# Because it's included here via add_subdirectory (not built standalone),
# LLAMA_STANDALONE evaluates false, so tests/examples/server/tools/app
# never get added to the build regardless of what's on disk.
add_subdirectory(llama.cpp)

add_library(edith_engine SHARED
    native_bridge.cpp
)

target_link_libraries(edith_engine
    llama
    android
    log
)

target_include_directories(edith_engine PRIVATE
    llama.cpp/include
    llama.cpp/ggml/include
)
