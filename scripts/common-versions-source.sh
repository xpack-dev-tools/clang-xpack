# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software 
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the second edition of the GNU MCU Eclipse build 
# scripts. As the name implies, it should contain only functions and 
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------

function xbb_activate_llvm_bootstrap_bins()
{
  # Warning, this should not bring llvm-config into the PATH, since
  # it crashes the compiler-rt build.
  export PATH="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin:${PATH}"

  # Set LD_LIBRARY_PATH to XBB folders, refered by the bootstrap.
  xbb_activate_libs
}

function prepare_bootstrap_cross_env()
{
  unset_compiler_env

  export CC="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-gcc"
  export CXX="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-g++"

  export AR="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-ar"
  export AS="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-as"
  export DLLTOOL="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-dlltool"
  export LD="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-ld"
  export NM="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-nm"
  export OBJCOPY="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-objcopy"
  export OBJDUMP="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-objdump"
  export RANLIB="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-ranlib"
  # export READELF="${prefix}readelf"
  # export SIZE="${prefix}size"
  export STRIP="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-strip"
  export WINDRES="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-windres"
  # export WINDMC="${prefix}windmc"
  # Use the XBB one, not the native llvm?
  export RC="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-windres"

  set_xbb_extras
}

function build_mingw_bootstrap()
{
  # Build a bootstrap toolchain, that runs on Linux and creates Windows
  # binaries.
  (
    # Make the use of XBB GCC explicit.
    prepare_gcc_env "" "-xbb"

    prepare_mingw_env "${MINGW_VERSION}" "${BOOTSTRAP_SUFFIX}"

    # Deploy the headers, they are needed by the compiler.
    build_mingw_headers

    # Build LLVM with the host XBB compiler.
    # Has a reference to /opt/xbb/lib/libncurses.so.
    build_llvm "${LLVM_VERSION}" "${BOOTSTRAP_SUFFIX}"

    # Build gendef & widl with the host XBB compiler.
    build_mingw_libmangle # Refered by gendef
    build_mingw_gendef
    build_mingw_widl # Refers to mingw headers.

    (
      xbb_activate_llvm_bootstrap_bins
      prepare_bootstrap_cross_env

      build_llvm_compiler_rt "${BOOTSTRAP_SUFFIX}"

      build_mingw_crt
      build_mingw_winpthreads
      # build_mingw_winstorecompat # Not needed by the bootstrap.

      build_llvm_libcxx "${BOOTSTRAP_SUFFIX}" # libunwind, libcxx, libcxxabi
    )
  )
}

function build_common()
{
  (
    xbb_activate

    if [ "${TARGET_PLATFORM}" == "win32" ]
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
        build_zlib "${ZLIB_VERSION}"
        build_ncurses "${NCURSES_VERSION}"
        build_libiconv "${LIBICONV_VERSION}"
        build_xz "${XZ_VERSION}"

        # Build mingw-w64 components.
        prepare_mingw_env "${MINGW_VERSION}" 

        build_mingw_headers
        build_mingw_crt
        build_mingw_winpthreads
        build_mingw_winstorecompat
        build_mingw_libmangle
        build_mingw_gendef
        build_mingw_widl

        # Finally build LLVM clang.
        build_llvm "${LLVM_VERSION}"

        build_llvm_compiler_rt
        build_llvm_libcxx # libunwind, libcxx, libcxxabi
        
      fi

    else # linux or darwin

      # macOS has its own linker, cannot use the binutils ones.
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        # Build ld.gold to support LTO.
        build_binutils_ld_gold "${BINUTILS_VERSION}"
      fi

      # Build libraries refered by LLVM.
      build_zlib "${ZLIB_VERSION}"
      build_libffi "${LIBFFI_VERSION}"
      build_ncurses "${NCURSES_VERSION}"
      build_libiconv "${LIBICONV_VERSION}"
      build_xz "${XZ_VERSION}"
      build_libxml2 "${LIBXML2_VERSION}"
      build_libedit "${LIBEDIT_VERSION}"

      # Finally build LLVM clang.
      build_llvm "${LLVM_VERSION}"

    fi
  )
}

function build_versions()
{
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    LLVM_BRANDING="${DISTRO_NAME} MinGW-w64 ${TARGET_MACHINE}"
    LLVM_BOOTSTRAP_BRANDING="${DISTRO_NAME} bootstrap ${TARGET_MACHINE}"
    BINUTILS_BRANDING="${DISTRO_NAME} MinGW-w64 binutils ${TARGET_MACHINE}"
  else
    LLVM_BRANDING="${DISTRO_NAME} ${TARGET_MACHINE}"
    BINUTILS_BRANDING="${DISTRO_NAME} binutils ${TARGET_MACHINE}"
  fi

  LLVM_VERSION="$(echo "${RELEASE_VERSION}" | sed -e 's|-.*||')"

  export BOOTSTRAP_SUFFIX="-bootstrap"

# -----------------------------------------------------------------------------
  
  if [[ "${RELEASE_VERSION}" =~ 12\.0\.1-[12] ]]
  then

    # Also used in -DLLVM_BINUTILS_INCDIR
    BINUTILS_VERSION="2.36.1"

    MINGW_VERSION="9.0.0" # "8.0.2"

    ZLIB_VERSION="1.2.11"
    LIBFFI_VERSION="3.4.2" # "3.3"
    NCURSES_VERSION="6.2"
    LIBICONV_VERSION="1.16"
    XZ_VERSION="5.2.5"
    LIBXML2_VERSION="2.9.11"
    LIBEDIT_VERSION="20210910-3.1" # "20210522-3.1"

    NCURSES_DISABLE_WIDEC="y"

    build_common

    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${APP_LC_NAME} version ${RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
