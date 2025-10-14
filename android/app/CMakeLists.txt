cmake_minimum_required(VERSION 3.10)

project(localai VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_ANDROID_STL_TYPE c++_shared)

find_library(log-lib log)
find_library(android-lib android)

option(USE_LLAMA_CPP "Build with llama.cpp support" ON)

if(USE_LLAMA_CPP)
    message(STATUS "Building WITH llama.cpp support")
    
    set(LLAMA_CPP_DIR "${CMAKE_CURRENT_SOURCE_DIR}/third_party/llama.cpp")
    
    if(EXISTS "${LLAMA_CPP_DIR}/CMakeLists.txt")
        message(STATUS "Found llama.cpp at: ${LLAMA_CPP_DIR}")
        
        # Isključi nepotrebne stvari
        set(LLAMA_BUILD_TESTS OFF CACHE BOOL "" FORCE)
        set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
        set(LLAMA_BUILD_SERVER OFF CACHE BOOL "" FORCE)
        set(GGML_OPENMP OFF CACHE BOOL "" FORCE)
        set(GGML_LLAMAFILE OFF CACHE BOOL "" FORCE)  # ← DODAJ OVO - isključuje llamafile optimizacije
        
        add_subdirectory(${LLAMA_CPP_DIR} llama.cpp.out)
        set(LLAMA_LIB llama)
    else()
        message(WARNING "llama.cpp CMakeLists.txt not found. Building MOCK mode.")
        set(USE_LLAMA_CPP OFF)
    endif()
else()
    message(STATUS "Building in MOCK mode (no llama.cpp)")
endif()

# Tvoj C++ shim kod
add_library(localai SHARED
    src/main/cpp/llama_shim.cpp
)

target_include_directories(localai PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/main/cpp
)

if(USE_LLAMA_CPP AND LLAMA_LIB)
    target_compile_definitions(localai PRIVATE USE_LLAMA_CPP)
    target_link_libraries(localai PRIVATE ${LLAMA_LIB})
    target_include_directories(localai PRIVATE
        ${LLAMA_CPP_DIR}/include
        ${LLAMA_CPP_DIR}/ggml/include
    )
endif()

target_link_libraries(localai PRIVATE
    ${log-lib}
    ${android-lib}
)

# Mobilne optimizacije
target_compile_options(localai PRIVATE
    -O3
    -ffast-math
    -funroll-loops
)

if(CMAKE_ANDROID_ARCH_ABI MATCHES "^armeabi-v7a")
    target_compile_options(localai PRIVATE -mfpu=neon -mfloat-abi=softfp)
elseif(CMAKE_ANDROID_ARCH_ABI MATCHES "^arm64-v8a")
    target_compile_options(localai PRIVATE -march=armv8-a)
endif()