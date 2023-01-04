# -----------------------------------------------------------------------------
# This file is part of the xPacks distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function clang_add_mingw_wrappers()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  (
    # Add wrappers for the mingw-w64 binaries.
    cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

    cp "${XBB_BUILD_GIT_PATH}/wrappers"/*-wrapper.sh .

    for exec in clang-target-wrapper dlltool-wrapper windres-wrapper llvm-wrapper
    do
      ${CC} "${XBB_BUILD_GIT_PATH}/wrappers/${exec}.c" -O2 -v -o ${exec}
    done

    for exec in clang clang++ gcc g++ cc c99 c11 c++ as
    do
      ln -sf clang-target-wrapper.sh ${XBB_TARGET_TRIPLET}-${exec}
    done
    for exec in addr2line ar ranlib nm objcopy strings strip
    do
      ln -sf llvm-${exec} ${XBB_TARGET_TRIPLET}-${exec}
    done
    if [ -f "llvm-windres" ]
    then
      # windres can't use llvm-wrapper, as that loses the original
      # target arch prefix.
      ln -sf llvm-windres ${XBB_TARGET_TRIPLET}-windres
    else
      ln -sf windres-wrapper ${XBB_TARGET_TRIPLET}-windres
    fi
    ln -sf dlltool-wrapper ${XBB_TARGET_TRIPLET}-dlltool
    for exec in ld objdump
    do
      ln -sf ${exec}-wrapper.sh ${XBB_TARGET_TRIPLET}-${exec}
    done
  )
}

function clang_build_mingw_bootstrap()
{
  # Build a bootstrap toolchain, that runs on Linux and creates Windows
  # binaries.
  # Inspired from https://github.com/mstorsjo/llvm-mingw.
  (
    # Build libraries refered by LLVM.
    zlib_build "${XBB_ZLIB_VERSION}"
    ncurses_build "${XBB_NCURSES_VERSION}"
    libiconv_build "${XBB_LIBICONV_VERSION}"
    xz_build "${XBB_XZ_VERSION}"

    # Build LLVM with the host XBB compiler.
    # Has a reference to /opt/xbb/lib/libncurses.so.
    llvm_mingw_build_first "${XBB_LLVM_VERSION}"
    clang_add_mingw_wrappers

    # Deploy the headers, they are needed by the compiler.
    mingw_build_headers

    # Build native widl & gendef.
    mingw_build_widl # Refers to mingw headers.

    mingw_build_libmangle # Refered by gendef
    mingw_build_gendef

    xbb_activate_installed_bin

    xbb_prepare_clang_env "${XBB_TARGET_TRIPLET}-"

    llvm_mingw_build_compiler_rt

    mingw_build_crt
    mingw_build_winpthreads
    # mingw_build_winstorecompat # Not needed by the bootstrap.

    llvm_mingw_build_libcxx
  )
}

function clang_build_common()
{

  if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
  then

    # Build a bootstrap toolchain, mainly for the *-tblgen tools, but
    # also because mixing with mingw-gcc fails the build in
    # various weird ways.

    # Number
    XBB_MINGW_VERSION_MAJOR=$(echo ${XBB_MINGW_VERSION} | sed -e 's|\([0-9][0-9]*\)[.].*|\1|')

    # XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}-cross.git.patch"

    mingw_download "${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------
    # Build the native dependencies.

    # Set the environment to initial values.
    xbb_reset_env
    xbb_set_target "mingw-w64-native"

    clang_build_mingw_bootstrap

    # Switch used during development to test bootstrap.
    if [ -z ${XBB_APPLICATION_BOOTSTRAP_ONLY+x} ]
    then

      # -------------------------------------------------------------------------
      # Build the target dependencies.

      # Set the environment to initial values.
      xbb_reset_env
      # Before set target (to possibly update CC & co variables).
      xbb_activate_installed_bin

      xbb_set_target "requested"

      xbb_prepare_clang_env "${XBB_TARGET_TRIPLET}-"

      # All of the following are cross compiled with the bootstrap LLVM
      # and the results are Windows binaries.

      # Build libraries refered by LLVM.
      zlib_build "${XBB_ZLIB_VERSION}"
      ncurses_build "${XBB_NCURSES_VERSION}"
      libiconv_build "${XBB_LIBICONV_VERSION}"
      xz_build "${XBB_XZ_VERSION}"

      # -------------------------------------------------------------------------
      # Build the application binaries.

      xbb_set_executables_install_path "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
      xbb_set_libraries_install_path "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

      # Build mingw-w64 components.
      mingw_build_headers
      mingw_build_widl --program-prefix=
      mingw_build_libmangle
      mingw_build_gendef --program-prefix=

      mingw_build_crt
      mingw_build_winpthreads
      mingw_build_winstorecompat

      # Build LLVM clang.
      llvm_build "${XBB_LLVM_VERSION}"

      llvm_mingw_build_compiler_rt
      llvm_mingw_build_libcxx # libunwind, libcxx, libcxxabi

    fi

  else # linux or darwin

    # -------------------------------------------------------------------------
    # Build the native dependencies.

    # autoreconf required by libxml2.
    autotools_build

    # -------------------------------------------------------------------------
    # Build the target dependencies.

    xbb_reset_env
    # Before set target (to possibly update CC & co variables).
    xbb_activate_installed_bin

    xbb_set_target "requested"

    if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
    then
      libiconv_build "${XBB_LIBICONV_VERSION}"
    else
      # Already built with the native dependencies.
      :
    fi

    zlib_build "${XBB_ZLIB_VERSION}"
    libffi_build "${XBB_LIBFFI_VERSION}"

    XBB_NCURSES_DISABLE_WIDEC="y"
    ncurses_build "${XBB_NCURSES_VERSION}"

    xz_build "${XBB_XZ_VERSION}"
    libxml2_build "${XBB_LIBXML2_VERSION}"
    libedit_build "${XBB_LIBEDIT_VERSION}"

    # -------------------------------------------------------------------------
    # Build the application binaries.

    xbb_set_executables_install_path "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
    xbb_set_libraries_install_path "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

    # macOS has its own linker, cannot use the binutils ones.
    if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "linux" ]
    then
      # Build ld.gold to support LTO.
      binutils_build_ld_gold "${XBB_BINUTILS_VERSION}"
    fi

    # Finally build LLVM clang.
    llvm_build "${XBB_LLVM_VERSION}"

    # strip_libs

  fi

}

function application_build_versioned_components()
{
  if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
  then
    XBB_LLVM_BOOTSTRAP_BRANDING="${XBB_APPLICATION_DISTRO_NAME} bootstrap ${XBB_TARGET_MACHINE}"

    XBB_LLVM_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 ${XBB_REQUESTED_TARGET_MACHINE}"
    XBB_BINUTILS_BRANDING="${XBB_APPLICATION_DISTRO_NAME} MinGW-w64 binutils ${XBB_REQUESTED_TARGET_MACHINE}"
  else
    XBB_LLVM_BRANDING="${XBB_APPLICATION_DISTRO_NAME} ${XBB_REQUESTED_TARGET_MACHINE}"
    XBB_BINUTILS_BRANDING="${XBB_APPLICATION_DISTRO_NAME} binutils ${XBB_REQUESTED_TARGET_MACHINE}"
  fi

  # https://github.com/llvm/llvm-project/releases/
  # There are bug-fix releases every two weeks until X.0.5 or X.0.6 (if necessary).
  XBB_LLVM_VERSION="$(echo "${XBB_RELEASE_VERSION}" | sed -e 's|-.*||')"
  XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_LLVM_VERSION}.git.patch"

  export XBB_BOOTSTRAP_SUFFIX="-bootstrap"

  # ---------------------------------------------------------------------------

  if [[ "${XBB_RELEASE_VERSION}" =~ 15[.]0[.]6-[1] ]]
  then

    XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_RELEASE_VERSION}.git.patch"

    # Also used in -DLLVM_BINUTILS_INCDIR
    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.39" # "2.38"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="10.0.0"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.13" # "1.2.12"
    # https://github.com/libffi/libffi/releases
    XBB_LIBFFI_VERSION="3.4.4" # "3.4.2"
    # https://ftp.gnu.org/gnu/ncurses/
    XBB_NCURSES_VERSION="6.4" # "6.3"
    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17"
    # https://sourceforge.net/projects/lzmautils/files/
    XBB_XZ_VERSION="5.4.0" # "5.2.6"
    # https://download.gnome.org/sources/libxml2/
    XBB_LIBXML2_VERSION="2.10.3" # "2.10.0"
    # https://www.thrysoee.dk/editline/
    XBB_LIBEDIT_VERSION="20221030-3.1" # "20210910-3.1"

    clang_build_common

    # -------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 14[.]0[.]6-[123] ]]
  then

    XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_RELEASE_VERSION}.git.patch"

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

    clang_build_common

    # -------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 13[.]0[.]1-[1] ]]
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

    clang_build_common

    # -------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 12[.]0[.]1-[12] ]]
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

    clang_build_common

    # -------------------------------------------------------------------------
  else
    echo "Unsupported ${XBB_APPLICATION_LOWER_CASE_NAME} version ${XBB_RELEASE_VERSION}"
    exit 1
  fi
}

# -----------------------------------------------------------------------------
