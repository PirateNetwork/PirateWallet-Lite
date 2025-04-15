package=fontconfig
$(package)_version=2.16.0
$(package)_download_path=https://www.freedesktop.org/software/fontconfig/release/
$(package)_file_name=$(package)-$($(package)_version).tar.xz
$(package)_sha256_hash=6a33dc555cc9ba8b10caf7695878ef134eeb36d0af366041f639b1da9b6ed220
$(package)_dependencies=freetype expat

define $(package)_set_vars
  $(package)_config_opts=--disable-docs --disable-static
  $(package)_config_opts += --disable-dependency-tracking --enable-option-checking
endef

define $(package)_config_cmds
  $($(package)_autoconf)
endef

# 2.12.1 uses CHAR_WIDTH which is reserved and clashes with some glibc versions, but newer versions of fontconfig
# have broken makefiles which needlessly attempt to re-generate headers with gperf.
# Instead, change all uses of CHAR_WIDTH, and disable the rule that forces header re-generation.
# This can be removed once the upstream build is fixed.
define $(package)_build_cmds
  $(MAKE)
endef

define $(package)_stage_cmds
  $(MAKE) DESTDIR=$($(package)_staging_dir) install
endef

define $(package)_postprocess_cmds
  rm lib/*.la
endef
