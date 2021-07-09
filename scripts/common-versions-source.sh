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
  unset_gcc_env

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

  # Warning, this might bring llvm-config into the PATH, and crash the
  # compiler-rt build.
  export PATH="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin:${PATH}"
  xbb_activate_libs
}

function build_versions()
{
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    LLVM_BRANDING="${BRANDING_PREFIX} MinGW-w64 ${TARGET_BITS}-bit"
    LLVM_BOOTSTRAP_BRANDING="${BRANDING_PREFIX} bootstrap ${TARGET_BITS}-bit"
    BINUTILS_BRANDING="${BRANDING_PREFIX} MinGW-w64 binutils ${TARGET_BITS}-bit"
  else
    LLVM_BRANDING="${BRANDING_PREFIX} ${TARGET_BITS}-bit"
    BINUTILS_BRANDING="${BRANDING_PREFIX} binutils ${TARGET_BITS}-bit"
  fi

  LLVM_VERSION="$(echo "${RELEASE_VERSION}" | sed -e 's|-[0-9]*||')"

  export BOOTSTRAP_SUFFIX="-bootstrap"

# -----------------------------------------------------------------------------
  
  if [[ "${RELEASE_VERSION}" =~ 12\.0\.1-[1] ]]
  then

    # Also used in -DLLVM_BINUTILS_INCDIR
    BINUTILS_VERSION="2.36.1"

    MINGW_VERSION="8.0.2"

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # Build a bootstrap toolchain, mainly for the *-tblgen tools, but
      # also because mixing with mingw-gcc fails the build in
      # various weird ways.
      build_llvm "${LLVM_VERSION}" "${BOOTSTRAP_SUFFIX}"

      (
        xbb_activate
        xbb_activate_llvm_bootstrap_bins  # Use the bootstrap llvm binaries.

        prepare_mingw_env "${MINGW_VERSION}" "${BOOTSTRAP_SUFFIX}"

        build_mingw_core
      )

      (
        xbb_activate

        # Temporarily revert to the XBB GCC (not the mingw-gcc,
        # as usual for windows targets).
        prepare_gcc_env "" "-xbb"

        prepare_mingw_env "${MINGW_VERSION}" "${BOOTSTRAP_SUFFIX}"

        build_mingw_libmangle
        build_mingw_gendef
        build_mingw_widl # Refers to mingw headers.
      )
   
      (
        xbb_activate
        xbb_activate_llvm_bootstrap_bins

        build_llvm_compiler_rt "${BOOTSTRAP_SUFFIX}"

        prepare_mingw_env "${MINGW_VERSION}" "${BOOTSTRAP_SUFFIX}"

        build_mingw_winpthreads
        build_mingw_winstorecompat

        build_llvm_libcxx "${BOOTSTRAP_SUFFIX}" # libunwind, libcxx, libcxxabi
      )
    fi

    if true # Switch used while testing the bootstrap.
    then
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then 
        build_binutils_ld_gold "${BINUTILS_VERSION}"
      fi

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        xbb_activate_llvm_bootstrap_bins # Use the bootstrap llvm binaries.
      fi

      build_zlib "1.2.11"

      if [ "${TARGET_PLATFORM}" != "win32" ]
      then 
        # Fails when built with bootstrap on Windows.
        build_libffi "3.3"
      fi

      build_ncurses "6.2"
      build_libiconv "1.16"

      build_xz "5.2.5"

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then 
        # On Windows it fails with the LLVM bootstrap.
        build_libxml2 "2.9.11"
        build_libedit "20210522-3.1"
      fi

      # Due to llvm-gentab specifics, it must be the same version as the
      # bootstrap llvm.
      build_llvm "${LLVM_VERSION}"

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        (
          xbb_activate
          prepare_mingw_env "${MINGW_VERSION}" 

          build_mingw_core # headers & crt
        )

        (
          xbb_activate
          # Temporarily use the XBB GCC (not mingw as usual for windows targets).
          prepare_gcc_env "" "-xbb"

          prepare_mingw_env "${MINGW_VERSION}"

          build_mingw_libmangle
          build_mingw_gendef
          # Refers to mingw headers.
          build_mingw_widl
        )

        (
          xbb_activate
          xbb_activate_llvm_bootstrap_bins # Use the bootstrap llvm binaries.

          build_llvm_compiler_rt

          prepare_mingw_env "${MINGW_VERSION}" 

          build_mingw_winpthreads
          build_mingw_winstorecompat
  
          build_llvm_libcxx # libunwind, libcxx, libcxxabi
        )
      fi
    fi

    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${APP_LC_NAME} version ${RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
