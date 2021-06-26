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

function build_versions()
{
  if [ "${TARGET_PLATFORM}" == "win32" ]
  then
    LLVM_BRANDING="${BRANDING_PREFIX} MinGW-w64 ${APP_NAME} ${TARGET_BITS}-bit"
    BINUTILS_BRANDING="${BRANDING_PREFIX} MinGW-w64 binutils ${TARGET_BITS}-bit"
  else
    LLVM_BRANDING="${BRANDING_PREFIX} ${APP_NAME} ${TARGET_BITS}-bit"
    BINUTILS_BRANDING="${BRANDING_PREFIX} binutils ${TARGET_BITS}-bit"
  fi

  LLVM_VERSION="$(echo "${RELEASE_VERSION}" | sed -e 's|-[0-9]*||')"

# -----------------------------------------------------------------------------
  
  if [[ "${RELEASE_VERSION}" =~ 11\.1\.0-[1] ]]
  then

    build_zlib "1.2.11"
    build_libffi "3.3"

    build_ncurses "6.2"
    build_libiconv "1.16"

    if [ "${TARGET_PLATFORM}" != "win32" ]
    then
      # On macOS it refers to libiconv
      build_libxml2 "2.9.11"

      build_libedit "20210522-3.1"
    fi

    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      # Also used in -DLLVM_BINUTILS_INCDIR
      BINUTILS_VERSION="2.36.1"
      
      build_binutils_ld_gold "2.36.1"
    fi

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      (
        # Build a native toolchain, mainly for the *-tblgen tools, but
        # since it's already in, also use it to build the final llvm & mingw.
        build_native_llvm_mingw "12.0.0"

        # build_native_llvm "${LLVM_VERSION}"

        build_llvm "12.0.0" # "${LLVM_VERSION}"

        # Prefer the native-llvm-mingw binaries.
        export PATH="${INSTALL_FOLDER_PATH}/native-llvm-mingw/bin:${PATH}"

        build_mingw "8.0.2"

        build_llvm_compiler_rt

        build_mingw_libraries

        build_mingw_tools

        build_llvm_libcxx
      )
    else
      build_llvm "${LLVM_VERSION}"
    fi

    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${APP_LC_NAME} version ${RELEASE_VERSION}."
    exit 1
  fi
}

# -----------------------------------------------------------------------------
