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

  export CC="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-gcc"
  export CXX="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-g++"

  export AR="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-ar"
  export AS="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-as"
  export DLLTOOL="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-dlltool"
  export LD="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-ld"
  export NM="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-nm"
  export OBJCOPY="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-objcopy"
  export OBJDUMP="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-objdump"
  export RANLIB="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-ranlib"
  # export READELF="${prefix}readelf"
  # export SIZE="${prefix}size"
  export STRIP="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-strip"
  export WINDRES="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-windres"
  # export WINDMC="${prefix}windmc"
  # Use the XBB one, not the native llvm?
  export RC="${APP_PREFIX}${NATIVE_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-windres"

  export PATH="${APP_PREFIX}${NATIVE_SUFFIX}/bin:${PATH}"
  xbb_activate_libs
}

function build_versions()
{
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    LLVM_BRANDING="${BRANDING_PREFIX} MinGW-w64 ${TARGET_BITS}-bit"
    LLVM_NATIVE_BRANDING="${BRANDING_PREFIX} bootstrap ${TARGET_BITS}-bit"
    BINUTILS_BRANDING="${BRANDING_PREFIX} MinGW-w64 binutils ${TARGET_BITS}-bit"
  else
    LLVM_BRANDING="${BRANDING_PREFIX} ${TARGET_BITS}-bit"
    BINUTILS_BRANDING="${BRANDING_PREFIX} binutils ${TARGET_BITS}-bit"
  fi

  LLVM_VERSION="$(echo "${RELEASE_VERSION}" | sed -e 's|-[0-9]*||')"

  export NATIVE_SUFFIX="-native"

# -----------------------------------------------------------------------------
  
  if [[ "${RELEASE_VERSION}" =~ 11\.1\.0-[1] ]]
  then

    # Also used in -DLLVM_BINUTILS_INCDIR
    BINUTILS_VERSION="2.36.1"

    LLVM_VERSION="12.0.0"
    MINGW_VERSION="8.0.2"

    if [ "${TARGET_PLATFORM}" = "win32" ]
    then

      USE_LLVM_MINGW="n"

      if [ "${USE_LLVM_MINGW}" == "y" ]
      then

      # Build a native toolchain, mainly for the *-tblgen tools, but
      # since it's already in, also use it to build the final llvm & mingw.
      build_native_llvm_mingw "${LLVM_VERSION}"

      else


      # Build a native toolchain, mainly for the *-tblgen tools, but
      # since it's already in, also use it to build the final llvm & mingw.
      # CC=${NATIVE_CC} is set inside the function.
      build_llvm "${LLVM_VERSION}" "${NATIVE_SUFFIX}"

      (
        xbb_activate

        # Favour LLVM bootstrap binaries.
        xbb_activate_llvm_bootstrap_bins

        prepare_mingw_env "${MINGW_VERSION}" "${NATIVE_SUFFIX}"

        build_mingw_core
      )

      (
        xbb_activate

        # Temporarily revert to the XBB GCC (not the mingw-gcc,
        # as usual for windows targets).
        prepare_gcc_env "" "-xbb"

        prepare_mingw_env "${MINGW_VERSION}" "${NATIVE_SUFFIX}"

        build_mingw_libmangle
        # run_verbose ls -l "${LIBS_INSTALL_FOLDER_PATH}${NATIVE_SUFFIX}/lib"

        build_mingw_gendef

        # Refers to mingw headers.
        build_mingw_widl
      )
   
      (
        xbb_activate

        # Favour bootstrap binaries.
        xbb_activate_llvm_bootstrap_bins

        build_llvm_compiler_rt "${NATIVE_SUFFIX}"

        prepare_mingw_env "${MINGW_VERSION}" "${NATIVE_SUFFIX}"

        build_mingw_winpthreads

        build_mingw_winstorecompat

        # libunwind, libcxx, libcxxabi
        build_llvm_libcxx "${NATIVE_SUFFIX}"
      )

      fi
    
      if true
      then
      # Use the native llvm-mingw binaries.
      xbb_activate_llvm_bootstrap_bins

      # Due to llvm-gentab specifics, it must be the same version as the
      # native llvm.
      build_llvm "${LLVM_VERSION}"

      (
        xbb_activate
        prepare_mingw_env "${MINGW_VERSION}" 

        # headers & crt
        build_mingw_core
      )

      (
        xbb_activate

        # Temporarily use the XBB GCC (not mingw as usual for windows targets).
        prepare_gcc_env "" "-xbb"

        prepare_mingw_env "${MINGW_VERSION}"

        build_mingw_libmangle
        # run_verbose ls -l "${LIBS_INSTALL_FOLDER_PATH}${NATIVE_SUFFIX}/lib"

        build_mingw_gendef

        # Refers to mingw headers.
        build_mingw_widl
      )

      (
        xbb_activate

        # Favour bootstrap binaries.
        # export PATH="${APP_PREFIX}${NATIVE_SUFFIX}/bin:${PATH}"
        xbb_activate_llvm_bootstrap_bins

        build_llvm_compiler_rt

        prepare_mingw_env "${MINGW_VERSION}" 

        build_mingw_winpthreads
        build_mingw_winstorecompat

        # libunwind, libcxx, libcxxabi
        build_llvm_libcxx
      )
    fi

    else

      build_zlib "1.2.11"
      build_libffi "3.3"

      build_ncurses "6.2"
      build_libiconv "1.16"

      build_xz "5.2.5"

      build_libxml2 "2.9.11"
      build_libedit "20210522-3.1"

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then 

        build_binutils_ld_gold "${BINUTILS_VERSION}"

      fi

      build_llvm "${LLVM_VERSION}"

    fi
    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${APP_LC_NAME} version ${RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
