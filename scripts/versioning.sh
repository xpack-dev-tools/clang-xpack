# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function _xbb_activate_llvm_bootstrap_bins()
{
  # Warning, this should not bring llvm-config into the PATH, since
  # it crashes the compiler-rt build.
  export PATH="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin:${PATH}"

  # Set LD_LIBRARY_PATH to XBB folders, refered by the bootstrap.
  xbb_activate_libs
}

function _prepare_bootstrap_cross_env()
{
  unset_compiler_env

  export CC="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-gcc"
  export CXX="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-g++"

  export AR="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-ar"
  export AS="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-as"
  export DLLTOOL="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-dlltool"
  export LD="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-ld"
  export NM="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-nm"
  export OBJCOPY="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-objcopy"
  export OBJDUMP="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-objdump"
  export RANLIB="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-ranlib"
  # export READELF="${prefix}readelf"
  # export SIZE="${prefix}size"
  export STRIP="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-strip"
  export WINDRES="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-windres"
  # export WINDMC="${prefix}windmc"
  # Use the XBB one, not the native llvm?
  export RC="${XBB_BINARIES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_CROSS_COMPILE_PREFIX}-windres"

  set_xbb_extras
}

function _build_mingw_bootstrap()
{
  # Build a bootstrap toolchain, that runs on Linux and creates Windows
  # binaries.
  (
    # Make the use of XBB GCC explicit.
    prepare_gcc_env "" "-xbb"

    prepare_mingw_env "${XBB_MINGW_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"

    # Deploy the headers, they are needed by the compiler.
    build_mingw_headers

    # Build LLVM with the host XBB compiler.
    # Has a reference to /opt/xbb/lib/libncurses.so.
    build_llvm "${XBB_LLVM_VERSION}" "${XBB_BOOTSTRAP_SUFFIX}"

    # Build gendef & widl with the host XBB compiler.
    build_mingw_libmangle # Refered by gendef
    build_mingw_gendef
    build_mingw_widl # Refers to mingw headers.

    (
      xbb_activate_llvm_bootstrap_bins
      prepare_bootstrap_cross_env

      build_llvm_compiler_rt "${XBB_BOOTSTRAP_SUFFIX}"

      build_mingw_crt
      build_mingw_winpthreads
      # build_mingw_winstorecompat # Not needed by the bootstrap.

      build_llvm_libcxx "${XBB_BOOTSTRAP_SUFFIX}" # libunwind, libcxx, libcxxabi
    )
  )
}

function _build_common()
{
  (
    if [ "${XBB_TARGET_PLATFORM}" == "win32" ]
    then

      # Build a bootstrap toolchain, mainly for the *-tblgen tools, but
      # also because mixing with mingw-gcc fails the build in
      # various weird ways.
      build_mingw_bootstrap

      if true # Switch used during bootstrap tests.
      then
        # All of the following are cross compiled with the bootstrap LLVM
        # and the results are Windows binaries.
        xbb_activate_llvm_bootstrap_bins # Adjust paths.
        prepare_bootstrap_cross_env # Define CC & family.

        # Build libraries refered by LLVM.
        build_zlib "${XBB_ZLIB_VERSION}"
        build_ncurses "${XBB_NCURSES_VERSION}"
        build_libiconv "${XBB_LIBICONV_VERSION}"
        build_xz "${XBB_XZ_VERSION}"

        # Build mingw-w64 components.
        prepare_mingw_env "${XBB_MINGW_VERSION}"

        build_mingw_headers
        build_mingw_crt
        build_mingw_winpthreads
        build_mingw_winstorecompat
        build_mingw_libmangle
        build_mingw_gendef
        build_mingw_widl

        # Finally build LLVM clang.
        build_llvm "${XBB_LLVM_VERSION}"

        build_llvm_compiler_rt
        build_llvm_libcxx # libunwind, libcxx, libcxxabi

      fi

    else # linux or darwin

      # macOS has its own linker, cannot use the binutils ones.
      if [ "${XBB_TARGET_PLATFORM}" == "linux" ]
      then
        # Build ld.gold to support LTO.
        build_binutils_ld_gold "${XBB_BINUTILS_VERSION}"
      fi

      # Build libraries refered by LLVM.
      build_zlib "${XBB_ZLIB_VERSION}"
      build_libffi "${XBB_LIBFFI_VERSION}"
      build_ncurses "${XBB_NCURSES_VERSION}"
      build_libiconv "${XBB_LIBICONV_VERSION}"
      build_xz "${XBB_XZ_VERSION}"
      build_libxml2 "${XBB_LIBXML2_VERSION}"
      build_libedit "${XBB_LIBEDIT_VERSION}"

      # Finally build LLVM clang.
      build_llvm "${XBB_LLVM_VERSION}"

    fi
  )
}

function build_application_versioned_components()
{
  if [ "${XBB_TARGET_PLATFORM}" == "win32" ]
  then
    XBB_LLVM_BOOTSTRAP_BRANDING="${XBB_APPLICATION_DISTRO_NAME} bootstrap ${XBB_TARGET_MACHINE}"

    XBB_LLVM_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 ${XBB_REQUESTED_TARGET_MACHINE}"
    XBB_BINUTILS_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 binutils ${XBB_REQUESTED_TARGET_MACHINE}"
  else
    XBB_LLVM_BRANDING="${XBB_APPLICATION_DISTRO_NAME} ${XBB_REQUESTED_TARGET_MACHINE}"
    XBB_BINUTILS_BRANDING="${XBB_APPLICATION_DISTRO_NAME} binutils ${XBB_REQUESTED_TARGET_MACHINE}"
  fi

  # https://github.com/llvm/llvm-project/releases/
  XBB_LLVM_VERSION="$(echo "${XBB_RELEASE_VERSION}" | sed -e 's|-.*||')"
  XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_LLVM_VERSION}.patch.diff"

  export XBB_BOOTSTRAP_SUFFIX="-bootstrap"

  # ---------------------------------------------------------------------------

  if [[ "${XBB_RELEASE_VERSION}" =~ 14\.0\.6-[123] ]]
  then

    XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_RELEASE_VERSION}.patch.diff"

    # Also used in -DLLVM_BINUTILS_INCDIR
    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.39" # "2.38"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="10.0.0" # "9.0.0" # "8.0.2"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.12" # "1.2.11"
    # https://github.com/libffi/libffi/releases
    XBB_LIBFFI_VERSION="3.4.2" # "3.3"
    # https://ftp.gnu.org/gnu/ncurses/
    XBB_NCURSES_VERSION="6.3"
    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17" # "1.16"
    # https://sourceforge.net/projects/lzmautils/files/
    XBB_XZ_VERSION="5.2.6" # "5.2.5"
    # https://download.gnome.org/sources/libxml2/
    XBB_LIBXML2_VERSION="2.10.0" # "2.9.11"
    # https://www.thrysoee.dk/editline/
    XBB_LIBEDIT_VERSION="20210910-3.1" # "20210522-3.1"

    # build_common

    # -------------------------------------------------------------------------
    # Build the native dependencies.

    # autoreconf required by libxml2.

    # https://ftp.gnu.org/pub/gnu/libiconv/
    build_libiconv "${XBB_LIBICONV_VERSION}"

    # https://ftp.gnu.org/gnu/autoconf/
    # depends on m4.
    build_autoconf "2.71"

    # https://ftp.gnu.org/gnu/automake/
    # depends on autoconf.
    build_automake "1.16.5"

    # http://ftpmirror.gnu.org/libtool/
    build_libtool "2.4.7"

    # configure.ac:34: error: Macro PKG_PROG_PKG_CONFIG is not available. It is usually defined in file pkg.m4 provided by package pkg-config.
    # https://pkgconfig.freedesktop.org/releases/
    # depends on libiconv
    build_pkg_config "0.29.2"

    # -------------------------------------------------------------------------
    # Build the target dependencies.

    xbb_set_target

    if [ "${XBB_TARGET_PLATFORM}" == "win32" ]
    then
      build_libiconv "${XBB_LIBICONV_VERSION}"
    else
      # Already built with the native dependencies.
      :
    fi

    build_zlib "${XBB_ZLIB_VERSION}"
    build_libffi "${XBB_LIBFFI_VERSION}"

    XBB_NCURSES_DISABLE_WIDEC="y"
    build_ncurses "${XBB_NCURSES_VERSION}"

    build_xz "${XBB_XZ_VERSION}"
    build_libxml2 "${XBB_LIBXML2_VERSION}"
    build_libedit "${XBB_LIBEDIT_VERSION}"

    # -------------------------------------------------------------------------
    # Build the application binaries.

    xbb_set_binaries_install "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"
    xbb_set_binaries_install "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"

    # macOS has its own linker, cannot use the binutils ones.
    if [ "${XBB_TARGET_PLATFORM}" == "linux" ]
    then
      # Build ld.gold to support LTO.
      build_binutils_ld_gold "${XBB_BINUTILS_VERSION}"
    fi

    # Finally build LLVM clang.
    build_llvm "${XBB_LLVM_VERSION}"

    # strip_libs

    # -------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 13\.0\.1-[1] ]]
  then

    # Also used in -DLLVM_BINUTILS_INCDIR
    XBB_BINUTILS_VERSION="2.38"

    XBB_MINGW_VERSION="9.0.0" # "8.0.2"

    XBB_ZLIB_VERSION="1.2.11"
    XBB_LIBFFI_VERSION="3.4.2" # "3.3"
    XBB_NCURSES_VERSION="6.3"
    XBB_LIBICONV_VERSION="1.16"
    XBB_XZ_VERSION="5.2.5"
    XBB_LIBXML2_VERSION="2.9.11"
    XBB_LIBEDIT_VERSION="20210910-3.1" # "20210522-3.1"

    XBB_NCURSES_DISABLE_WIDEC="y"

    build_common

    # -------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 12\.0\.1-[12] ]]
  then

    # Also used in -DLLVM_BINUTILS_INCDIR
    XBB_BINUTILS_VERSION="2.36.1"

    XBB_MINGW_VERSION="9.0.0" # "8.0.2"

    XBB_ZLIB_VERSION="1.2.11"
    XBB_LIBFFI_VERSION="3.4.2" # "3.3"
    XBB_NCURSES_VERSION="6.2"
    XBB_LIBICONV_VERSION="1.16"
    XBB_XZ_VERSION="5.2.5"
    XBB_LIBXML2_VERSION="2.9.11"
    XBB_LIBEDIT_VERSION="20210910-3.1" # "20210522-3.1"

    XBB_NCURSES_DISABLE_WIDEC="y"

    build_common

    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
