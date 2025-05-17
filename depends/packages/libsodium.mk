package=libsodium
$(package)_version=1.0.20
$(package)_download_path=https://download.libsodium.org/libsodium/releases
$(package)_file_name=$(package)-$($(package)_version).tar.gz
$(package)_sha256_hash=ebb65ef6ca439333c2bb41a0c1990587288da07f6c7fd07cb3a18cc18d30ce19
$(package)_mingw32_dependencies = mxe
$(package)_dependencies=
$(package)_config_opts=
$(package)_config_opts_aarch64=--build=$(BUILD)
$(package)_cflags_aarch64_darwin += -arch arm64
$(package)_ldflags_aarch64_darwin += -arch arm64

define $(package)_set_vars
  $(package)_build_env=DO_NOT_UPDATE_CONFIG_SCRIPTS=1
  ifeq ($(build_os),darwin)
  $(package)_build_env+=MACOSX_DEPLOYMENT_TARGET="$(OSX_MIN_VERSION)"
  $(package)_cc=clang
  $(package)_cxx=clang++
  endif
endef

define $(package)_preprocess_cmds
  cd $($(package)_build_subdir); ./autogen.sh
endef

define $(package)_config_cmds
  $($(package)_autoconf) --host=$(host) --enable-static --disable-shared
endef

define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef
