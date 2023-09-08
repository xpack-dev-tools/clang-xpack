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

  local mingw_wrappers_folder_name="llvm-mingw-wrappers"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${mingw_wrappers_folder_name}"

  local mingw_wrappers_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${mingw_wrappers_folder_name}-installed"
  if [ ! -f "${mingw_wrappers_stamp_file_path}" ]
  then

    (
      # Add wrappers for the mingw-w64 binaries.
      run_verbose cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

      run_verbose cp -pv "${XBB_BUILD_GIT_PATH}/wrappers"/*-wrapper.sh .
      run_verbose chmod +x *-wrapper.sh

      for name in clang-target-wrapper llvm-wrapper
      do
        # -s for strip
        run_verbose ${CC} "${XBB_BUILD_GIT_PATH}/wrappers/${name}.c" -O2 -v -o ${name} -Wl,-s
      done

      for triplet in "${XBB_MINGW_TRIPLETS[@]}"
      do

        for name in clang clang++ gcc g++ c++ as
        do
          ln -sfv clang-target-wrapper.sh ${triplet}-${name}
        done

        for name in addr2line ar ranlib nm objcopy readelf size strings strip windres dlltool
        do
          ln -sfv llvm-${name} ${triplet}-${name}
        done

        ln -sfv ld-wrapper.sh ${triplet}-ld
        ln -sfv objdump-wrapper.sh ${triplet}-objdump

      done
    ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${mingw_wrappers_folder_name}/output-$(ndate).txt"

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${mingw_wrappers_stamp_file_path}"

  else
    echo "Component llvm-mingw-wrappers already installed"
  fi
}

function clang_build_mingw_bootstrap()
{
  # Build a bootstrap toolchain, that runs on Linux and creates Windows
  # binaries.
  # Inspired by https://github.com/mstorsjo/llvm-mingw.
  (
    # Build libraries refered by LLVM.
    zlib_build "${XBB_ZLIB_VERSION}"
    ncurses_build "${XBB_NCURSES_VERSION}"
    libiconv_build "${XBB_LIBICONV_VERSION}"
    xz_build "${XBB_XZ_VERSION}"

    # Build LLVM with the host XBB compiler.
    # Has a reference to /opt/xbb/lib/libncurses.so.
    # The result is installed in x86_64-pc-linux-gnu/install
    llvm_mingw_build_first "${XBB_LLVM_VERSION}"

    # Add wrappers to both i686-* and x64_64-* applications.
    clang_add_mingw_wrappers

    for triplet in "${XBB_MINGW_TRIPLETS[@]}"
    do
      (
        xbb_set_extra_target_env "${triplet}"

        # ---------------------------------------------------------------------
        # Use the native compiler

        # Deploy the headers, they are needed by the compiler.
        mingw_build_headers --triplet="${triplet}"

        # Build native widl & gendef.
        mingw_build_widl --triplet="${triplet}" # Refers to mingw headers.

        mingw_build_libmangle --triplet="${triplet}" # Refered by gendef
        mingw_build_gendef --triplet="${triplet}"

        # ---------------------------------------------------------------------
        # Use the mingw toolchain compiled above.

        xbb_activate_installed_bin

        # MS uses the clang names.
        # xbb_prepare_clang_env "${triplet}-"
        # For consistency with GCC, prefer them.
        xbb_prepare_gcc_env "${triplet}-"

        # The Windows object files (like CRT_glob.o) and libraries
        # like libmsvcrt70.a) are installed in
        # x86_64-pc-linux-gnu/install/i686-w64-mingw32
        mingw_build_crt --triplet="${triplet}"

        # The library is installed in
        # x86_64-pc-linux-gnu/install/lib/clang/16.0.6/lib/windows/libclang_rt.builtins-i386.a
        llvm_mingw_build_compiler_rt --triplet="${triplet}"

        llvm_mingw_build_libcxx --triplet="${triplet}"

        # Requires libunwind.
        mingw_build_winpthreads --triplet="${triplet}"
        # mingw_build_winstorecompat # Not needed by the bootstrap.
      )
    done
  )
}

function clang_build_common()
{

  if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
  then

    # The Windows build proved particularly difficult to master. The main
    # issue was cmake picking up unwanted tools. This was solved only with
    # explicit `CMAKE_*` variables to define the absolute paths to desired
    # tools. Attempts to simplify things by removing the top mingw-gcc
    # dependency failed, since some of the tools are needed in the post
    # processing step.

    # Number
    XBB_MINGW_VERSION_MAJOR=$(xbb_get_version_major "${XBB_MINGW_VERSION}")

    # XBB_MINGW_GCC_PATCH_FILE_NAME="gcc-${XBB_GCC_VERSION}-cross.git.patch"

    mingw_download "${XBB_MINGW_VERSION}"

    # -------------------------------------------------------------------------
    # Build the native dependencies.

    # Set the environment to initial values.
    xbb_reset_env
    xbb_set_target "mingw-w64-native"

    # Build a bootstrap toolchain, mainly for the *-tblgen tools, but
    # also because mixing with mingw-gcc may lead to unexpected results.

    clang_build_mingw_bootstrap

    # Switch used during development to test bootstrap.
    if [ -z ${XBB_APPLICATION_BOOTSTRAP_ONLY+x} ]
    then

      # -----------------------------------------------------------------------
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

      # -----------------------------------------------------------------------
      # Build the application binaries.

      xbb_set_executables_install_path "${XBB_APPLICATION_INSTALL_FOLDER_PATH}"
      xbb_set_libraries_install_path "${XBB_DEPENDENCIES_INSTALL_FOLDER_PATH}"

      for triplet in "${XBB_MINGW_TRIPLETS[@]}"
      do
        (
          xbb_prepare_gcc_env "${triplet}-"
          xbb_set_extra_target_env "${triplet}"

          # Build mingw-w64 components.
          mingw_build_headers --triplet="${triplet}"

          # widl & gendef actually do not need to be built for all triplets.
          mingw_build_widl  --triplet="${triplet}" --program-prefix=
          mingw_build_libmangle --triplet="${triplet}"
          mingw_build_gendef --triplet="${triplet}" --program-prefix=

          mingw_build_crt --triplet="${triplet}"
          mingw_build_winpthreads --triplet="${triplet}"
          mingw_build_winstorecompat --triplet="${triplet}"
        )
      done

      # xbb_prepare_clang_env "${XBB_TARGET_TRIPLET}-"
      xbb_prepare_gcc_env "${XBB_TARGET_TRIPLET}-"

      # Build LLVM clang.
      llvm_build "${XBB_LLVM_VERSION}"

      for triplet in "${XBB_MINGW_TRIPLETS[@]}"
      do
        (
          xbb_prepare_gcc_env "${triplet}-"
          xbb_set_extra_target_env "${triplet}"

          llvm_mingw_build_compiler_rt --triplet="${triplet}"
          # libunwind, libcxx, libcxxabi
          llvm_mingw_build_libcxx  --triplet="${triplet}"
        )
      done
    fi

  else # linux or darwin

    # -------------------------------------------------------------------------
    # Build the native dependencies.

    if false
    then
      # autoreconf required by libxml2.
      autotools_build
    fi

    # -------------------------------------------------------------------------
    # Build the target dependencies.

    xbb_reset_env
    # Before set target (to possibly update CC & co variables).
    xbb_activate_installed_bin

    xbb_set_target "requested"

    # xbb_prepare_gcc_env

    if true # [ "${XBB_REQUESTED_HOST_PLATFORM}" == "win32" ]
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

    if [ "${XBB_REQUESTED_HOST_PLATFORM}" == "darwin" ]
    then
      # Use it temporarily, to avoid bugs in previous binary packages.
      if [[ "${XBB_RELEASE_VERSION}" =~ 15[.]0[.]7[-][34] ]]
      then
	      xbb_prepare_apple_clang_env
      fi
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

  # 32-bit first, since it is more probable to fail.
  XBB_MINGW_TRIPLETS=( "i686-w64-mingw32" "x86_64-w64-mingw32" )
  # XBB_MINGW_TRIPLETS=( "x86_64-w64-mingw32" ) # Use it temporarily during tests.
  # XBB_MINGW_TRIPLETS=( "i686-w64-mingw32" ) # Use it temporarily during tests.

  # ---------------------------------------------------------------------------

  if [[ "${XBB_RELEASE_VERSION}" =~ 16[.].*[.].*-.* ]]
  then

    XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_RELEASE_VERSION}.git.patch"

    # XBB_DO_REQUIRE_RPATH="n"

    # Also used in -DLLVM_BINUTILS_INCDIR
    # https://ftp.gnu.org/gnu/binutils/
    XBB_BINUTILS_VERSION="2.40" # "2.39"

    # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/
    XBB_MINGW_VERSION="11.0.0" # "10.0.0"

    # https://zlib.net/fossils/
    XBB_ZLIB_VERSION="1.2.13"
    # https://github.com/libffi/libffi/releases
    XBB_LIBFFI_VERSION="3.4.4"
    # https://ftp.gnu.org/gnu/ncurses/
    XBB_NCURSES_VERSION="6.4"
    # https://ftp.gnu.org/pub/gnu/libiconv/
    XBB_LIBICONV_VERSION="1.17"
    # https://sourceforge.net/projects/lzmautils/files/
    XBB_XZ_VERSION="5.4.3" # "5.4.0"
    # https://download.gnome.org/sources/libxml2/
    XBB_LIBXML2_VERSION="2.11.4" # "2.10.3"
    # https://www.thrysoee.dk/editline/
    XBB_LIBEDIT_VERSION="20221030-3.1"

    clang_build_common

    # -------------------------------------------------------------------------
  elif [[ "${XBB_RELEASE_VERSION}" =~ 15[.].*[.].*-.* ]]
  then

    XBB_LLVM_PATCH_FILE_NAME="llvm-${XBB_RELEASE_VERSION}.git.patch"

    # XBB_DO_REQUIRE_RPATH="n"

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
  elif [[ "${XBB_RELEASE_VERSION}" =~ 14[.].*[.].*-.* ]]
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
  elif [[ "${XBB_RELEASE_VERSION}" =~ 13[.].*[.].*-.* ]]
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
  elif [[ "${XBB_RELEASE_VERSION}" =~ 12[.].*[.].*-.* ]]
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
