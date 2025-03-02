package=qt
$(package)_version=5.15.13
$(package)_download_path=http://mirrors.ocf.berkeley.edu/qt/archive/qt/5.15/$($(package)_version)/single
$(package)_suffix=everywhere-opensource-src-$($(package)_version).tar.xz
$(package)_file_name=qt-$($(package)_suffix)
$(package)_sha256_hash=9550ec8fc758d3d8d9090e261329700ddcd712e2dda97e5fcfeabfac22bea2ca
$(package)_linux_dependencies=freetype fontconfig libxcb libxkbcommon libxcb_util libxcb_util_render libxcb_util_keysyms libxcb_util_image libxcb_util_wm
$(package)_patches = qt.pro
$(package)_patches += qttools_src.pro
$(package)_patches += mac-qmake.conf
$(package)_patches += fix_qt_pkgconfig.patch
$(package)_patches += no-xlib.patch
$(package)_patches += fix_android_jni_static.patch
$(package)_patches += dont_hardcode_pwd.patch
$(package)_patches += qtbase-moc-ignore-gcc-macro.patch
$(package)_patches += rcc_hardcode_timestamp.patch
$(package)_patches += static_xcb.patch
$(package)_patches += duplicate_lcqpafonts.patch
$(package)_patches += guix_cross_lib_path.patch
$(package)_patches += fix-macos-linker.patch
$(package)_patches += memory_resource.patch
$(package)_patches += utc_from_string_no_optimize.patch
$(package)_patches += windows_lto.patch
$(package)_patches += zlib-timebits64.patch

define $(package)_set_vars
$(package)_config_env = QT_MAC_SDK_NO_VERSION_CHECK=1

$(package)_config_opts += -confirm-license
$(package)_config_opts += -opensource
$(package)_config_opts += -static
$(package)_config_opts += -release

$(package)_config_opts += -c++std c++17

$(package)_config_opts += -bindir $(build_prefix)/bin
$(package)_config_opts += -hostprefix $(build_prefix)
$(package)_config_opts += -prefix $(host_prefix)
$(package)_config_opts += -pkg-config

$(package)_config_opts += -ltcg
$(package)_config_opts += -qt-libjpeg
$(package)_config_opts += -qt-libpng
$(package)_config_opts += -qt-pcre
$(package)_config_opts += -qt-harfbuzz
$(package)_config_opts += -qt-zlib

$(package)_config_opts += -no-xcb-xlib
$(package)_config_opts += -no-feature-xlib
$(package)_config_opts += -no-opengl
$(package)_config_opts += -no-feature-vulkan

$(package)_config_opts += -no-cups
$(package)_config_opts += -no-pch
$(package)_config_opts += -no-egl
$(package)_config_opts += -no-eglfs
$(package)_config_opts += -no-glib
$(package)_config_opts += -no-icu
$(package)_config_opts += -no-iconv
$(package)_config_opts += -no-kms
$(package)_config_opts += -no-linuxfb
$(package)_config_opts += -no-libproxy
$(package)_config_opts += -no-libudev
$(package)_config_opts += -no-mtdev
$(package)_config_opts += -no-openvg
$(package)_config_opts += -no-reduce-relocations
$(package)_config_opts += -no-sctp
$(package)_config_opts += -no-sql-db2
$(package)_config_opts += -no-sql-ibase
$(package)_config_opts += -no-sql-oci
$(package)_config_opts += -no-sql-tds
$(package)_config_opts += -no-sql-mysql
$(package)_config_opts += -no-sql-odbc
$(package)_config_opts += -no-sql-psql
$(package)_config_opts += -no-sql-sqlite
$(package)_config_opts += -no-sql-sqlite2
$(package)_config_opts += -no-system-proxies
$(package)_config_opts += -no-use-gold-linker

$(package)_config_opts += -nomake examples
$(package)_config_opts += -nomake tests
$(package)_config_opts += -nomake tools

$(package)_config_opts += -skip qtactiveqt
$(package)_config_opts += -skip qtconnectivity
$(package)_config_opts += -skip qt3d
$(package)_config_opts += -skip qtcanvas3d
$(package)_config_opts += -skip qtdatavis3d
$(package)_config_opts += -skip qtcharts
$(package)_config_opts += -skip qtlocation
$(package)_config_opts += -skip qtsensors
$(package)_config_opts += -skip qtdeclarative
$(package)_config_opts += -skip qtdoc
$(package)_config_opts += -skip qtgraphicaleffects
$(package)_config_opts += -skip qtmultimedia
$(package)_config_opts += -skip qtquickcontrols
$(package)_config_opts += -skip qtquickcontrols2
$(package)_config_opts += -skip qtpurchasing
$(package)_config_opts += -skip qtremoteobjects
$(package)_config_opts += -skip qtsensors
$(package)_config_opts += -skip qtserialport
$(package)_config_opts += -skip qtwebchannel
$(package)_config_opts += -skip qtgamepad
$(package)_config_opts += -skip qtscript
$(package)_config_opts += -skip qtserialbus
$(package)_config_opts += -skip qtvirtualkeyboard
$(package)_config_opts += -skip qtwayland
$(package)_config_opts += -skip qtwebview
$(package)_config_opts += -skip qtwebglplugin
$(package)_config_opts += -skip qtxmlpatterns
$(package)_config_opts += -skip qtwebengine

$(package)_config_opts += -v


$(package)_config_opts_mingw32 += -xplatform win32-g++
$(package)_config_opts_mingw32 += -device-option CROSS_COMPILE="$(host)-"


endef


define $(package)_preprocess_cmds
  patch -p1 -i $($(package)_patch_dir)/fix-macos-linker.patch && \
  patch -p1 -i $($(package)_patch_dir)/dont_hardcode_pwd.patch && \
  patch -p1 -i $($(package)_patch_dir)/fix_qt_pkgconfig.patch && \
  patch -p1 -i $($(package)_patch_dir)/fix_android_jni_static.patch && \
  patch -p1 -i $($(package)_patch_dir)/no-xlib.patch && \
  patch -p1 -i $($(package)_patch_dir)/qtbase-moc-ignore-gcc-macro.patch && \
  patch -p1 -i $($(package)_patch_dir)/memory_resource.patch && \
  patch -p1 -i $($(package)_patch_dir)/rcc_hardcode_timestamp.patch && \
	patch -p1 -i $($(package)_patch_dir)/static_xcb.patch && \
  patch -p1 -i $($(package)_patch_dir)/duplicate_lcqpafonts.patch && \
  patch -p1 -i $($(package)_patch_dir)/utc_from_string_no_optimize.patch && \
  patch -p1 -i $($(package)_patch_dir)/guix_cross_lib_path.patch && \
  patch -p1 -i $($(package)_patch_dir)/windows_lto.patch && \
  patch -p1 -i $($(package)_patch_dir)/zlib-timebits64.patch 
endef

define $(package)_config_cmds
	export PKG_CONFIG_SYSROOT_DIR=/ && \
  export PKG_CONFIG_LIBDIR=$(host_prefix)/lib/pkgconfig && \
  export PKG_CONFIG_PATH=$(host_prefix)/share/pkgconfig  && \
  ./configure $($(package)_config_opts)
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) -C qtbase INSTALL_ROOT=$($(package)_staging_dir) install && \
  $(MAKE) -C qttools INSTALL_ROOT=$($(package)_staging_dir) install && \
  $(MAKE) -C qttranslations INSTALL_ROOT=$($(package)_staging_dir) install && \
  $(MAKE) -C qtwebsockets INSTALL_ROOT=$($(package)_staging_dir) install
endef

