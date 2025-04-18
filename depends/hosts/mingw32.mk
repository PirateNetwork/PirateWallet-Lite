# MinGW32 makefile for building dependencies
mingw32_CFLAGS=-pipe -std=c17
mingw32_CXXFLAGS=-pipe -std=c++17

mingw32_release_CFLAGS=-g -O2
mingw32_release_CXXFLAGS=$(mingw32_CXXFLAGS) $(mingw32_release_CFLAGS)

mingw32_debug_CFLAGS=-O1
mingw32_debug_CXXFLAGS=$(mingw32_debug_CFLAGS)

mingw32_debug_CFLAGS=-g -O0
mingw32_debug_CPPFLAGS=-D_GLIBCXX_DEBUG -D_GLIBCXX_DEBUG_PEDANTIC
mingw32_debug_CXXFLAGS=$(mingw32_CXXFLAGS) $(mingw32_debug_CFLAGS)
