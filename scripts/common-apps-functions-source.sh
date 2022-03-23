# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# Helper script used in the second edition of the xPack build
# scripts. As the name implies, it should contain only functions and
# should be included with 'source' by the container build scripts.

# -----------------------------------------------------------------------------

function build_binutils_ld_gold()
{
  # https://www.gnu.org/software/binutils/
  # https://ftp.gnu.org/gnu/binutils/

  # https://archlinuxarm.org/packages/aarch64/binutils/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gdb-git

  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-binutils
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-binutils/PKGBUILD


  # 2017-07-24, "2.29"
  # 2018-01-28, "2.30"
  # 2018-07-18, "2.31.1"
  # 2019-02-02, "2.32"
  # 2019-10-12, "2.33.1"
  # 2020-02-01, "2.34"
  # 2020-07-24, "2.35"
  # 2020-09-19, "2.35.1"
  # 2021-01-24, "2.36"
  # 2021-01-30, "2.35.2"
  # 2021-02-06, "2.36.1"
  # 2021-07-18, "2.37"
  # 2022-02-09, "2.38"

  local binutils_version="$1"

  local binutils_src_folder_name="binutils-${binutils_version}"

  local binutils_archive="${binutils_src_folder_name}.tar.xz"
  local binutils_url="https://ftp.gnu.org/gnu/binutils/${binutils_archive}"

  local binutils_folder_name="binutils-ld.gold-${binutils_version}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${binutils_folder_name}"

  local binutils_patch_file_name="binutils-${binutils_version}.patch"
  local binutils_stamp_file_path="${INSTALL_FOLDER_PATH}/stamp-${binutils_folder_name}-installed"
  if [ ! -f "${binutils_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${binutils_url}" "${binutils_archive}" \
      "${binutils_src_folder_name}" "${binutils_patch_file_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${binutils_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${binutils_folder_name}"

      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        if [ "${TARGET_ARCH}" == "x32" -o "${TARGET_ARCH}" == "ia32" ]
        then
          # From MSYS2 MINGW
          LDFLAGS+=" -Wl,--large-address-aware"
        fi

        # Used to enable wildcard; inspired from arm-none-eabi-gcc.
        LDFLAGS+=" -Wl,${XBB_FOLDER_PATH}/usr/${CROSS_COMPILE_PREFIX}/lib/CRT_glob.o"
      elif [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running binutils-ld.gold configure..."

          bash "${SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/configure" --help
          bash "${SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/ld/configure" --help

          # ? --without-python --without-curses, --with-expat
          config_options=()

          config_options+=("--prefix=${APP_PREFIX}")

          config_options+=("--infodir=${APP_PREFIX_DOC}/info")
          config_options+=("--mandir=${APP_PREFIX_DOC}/man")
          config_options+=("--htmldir=${APP_PREFIX_DOC}/html")
          config_options+=("--pdfdir=${APP_PREFIX_DOC}/pdf")

          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--program-suffix=")
          config_options+=("--with-pkgversion=${BINUTILS_BRANDING}")

          # config_options+=("--with-lib-path=/usr/lib:/usr/local/lib")
          config_options+=("--with-sysroot=${APP_PREFIX}")

          config_options+=("--without-system-zlib")
          config_options+=("--with-pic")

          if [ "${TARGET_PLATFORM}" == "win32" ]
          then

            config_options+=("--enable-ld")

            if [ "${TARGET_ARCH}" == "x64" ]
            then
              # From MSYS2 MINGW
              config_options+=("--enable-64-bit-bfd")
            fi

            config_options+=("--enable-shared")
            config_options+=("--enable-shared-libgcc")

          elif [ "${TARGET_PLATFORM}" == "linux" ]
          then

            config_options+=("--enable-ld")

            config_options+=("--disable-shared")
            config_options+=("--disable-shared-libgcc")

          else
            echo "Oops! Unsupported ${TARGET_PLATFORM}."
            exit 1
          fi

          config_options+=("--enable-static")

          config_options+=("--enable-gold")
          config_options+=("--enable-lto")
          config_options+=("--enable-libssp")
          config_options+=("--enable-relro")
          config_options+=("--enable-threads")
          config_options+=("--enable-interwork")
          config_options+=("--enable-plugins")
          config_options+=("--enable-build-warnings=no")
          config_options+=("--enable-deterministic-archives")

          # TODO
          # config_options+=("--enable-nls")
          config_options+=("--disable-nls")

          config_options+=("--disable-werror")
          config_options+=("--disable-sim")
          config_options+=("--disable-gdb")

          run_verbose bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${LOGS_FOLDER_PATH}/${binutils_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${binutils_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running binutils-ld.gold make..."

        # Build.
        run_verbose make -j ${JOBS} all-gold

        if [ "${WITH_TESTS}" == "y" ]
        then
          # gcctestdir/collect-ld: relocation error: gcctestdir/collect-ld: symbol _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm, version GLIBCXX_3.4.21 not defined in file libstdc++.so.6 with link time reference
          : # make maybe-check-gold
        fi

        # Avoid strip here, it may interfere with patchelf.
        # make install-strip
        run_verbose make maybe-install-gold

        # Remove the separate folder, the xPack distribution is single target.
        rm -rf "${APP_PREFIX}/${BUILD}"

        if [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          : # rm -rv "${APP_PREFIX}/bin/strip"
        fi

        (
          xbb_activate_tex

          if [ "${WITH_PDF}" == "y" ]
          then
            run_verbose make maybe-pdf-gold
            run_verbose make maybe-install-pdf-gold
          fi

          if [ "${WITH_HTML}" == "y" ]
          then
            run_verbose make maybe-htmp-gold
            run_verbose make maybe-install-html-gold
          fi
        )

        show_libs "${APP_PREFIX}/bin/ld.gold"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${binutils_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${binutils_src_folder_name}" \
        "${binutils_folder_name}"

    )

    touch "${binutils_stamp_file_path}"
  else
    echo "Component binutils ld.gold already installed."
  fi

  tests_add "test_binutils_ld_gold"
}

function test_binutils_ld_gold()
{
  (
    if [ -d "xpacks/.bin" ]
    then
      TEST_BIN_PATH="$(pwd)/xpacks/.bin"
    elif [ -d "${APP_PREFIX}/bin" ]
    then
      TEST_BIN_PATH="${APP_PREFIX}/bin"
    else
      echo "Wrong folder."
      exit 1
    fi

    show_libs "${TEST_BIN_PATH}/ld.gold"

    echo
    echo "Testing if binutils ld.gold starts properly..."

    run_app "${TEST_BIN_PATH}/ld.gold" --version
  )

  echo
  echo "Local binutils ld.gold tests completed successfuly."
}

# -----------------------------------------------------------------------------

function build_llvm()
{
  # https://llvm.org
  # https://llvm.org/docs/GettingStarted.html
  # https://llvm.org/docs/CommandGuide/
  # https://github.com/llvm/llvm-project/
  # https://github.com/llvm/llvm-project/releases/
  # https://github.com/llvm/llvm-project/releases/tag/llvmorg-11.1.0/
  # https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/llvm-project-11.1.0.src.tar.xz

  # https://archlinuxarm.org/packages/aarch64/llvm/files/PKGBUILD

  # https://llvm.org/docs/GoldPlugin.html#lto-how-to-build
  # https://llvm.org/docs/BuildingADistribution.html

  # 17 Feb 2021, "11.1.0"
  # For GCC 11 it requires a patch to add <limits> to `benchmark_register.h`.
  # Fixed in 12.x.
  # 14 Apr 2021, "12.0.0"
  # 9 Jul 2021, "12.0.1"
  # 1 Oct 2021, "13.0.0"
  # 2 Feb 2022, "13.0.1"

  export ACTUAL_LLVM_VERSION="$1"
  local name_suffix=${2-''}

  if [ -n "${name_suffix}" -a "${TARGET_PLATFORM}" != "win32" ]
  then
    echo "Native supported only for Windows binaries."
    exit 1
  fi

  local llvm_version_major=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')
  local llvm_version_minor=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')

  export llvm_src_folder_name="llvm-project-${ACTUAL_LLVM_VERSION}.src"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${ACTUAL_LLVM_VERSION}/${llvm_archive}"

  local llvm_folder_name="llvm-${ACTUAL_LLVM_VERSION}${name_suffix}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_folder_name}"

  local llvm_patch_file_name="llvm-${ACTUAL_LLVM_VERSION}.patch.diff"
  local llvm_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_folder_name}-installed"
  if [ ! -f "${llvm_stamp_file_path}" ]
  then

    cd "${SOURCES_FOLDER_PATH}"

    download_and_extract "${llvm_url}" "${llvm_archive}" \
      "${llvm_src_folder_name}" "${llvm_patch_file_name}"

    # Disable the use of libxar.
    run_verbose sed -i.bak \
      -e 's|^check_library_exists(xar xar_open |# check_library_exists(xar xar_open |' \
      "${llvm_src_folder_name}/llvm/cmake/config-ix.cmake"

    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      # Add -lpthread -ldl
      run_verbose sed -i.bak \
        -e 's|if (ToolChain.ShouldLinkCXXStdlib(Args)) {$|if (ToolChain.ShouldLinkCXXStdlib(Args)) { CmdArgs.push_back("-lpthread"); CmdArgs.push_back("-ldl");|' \
        "${llvm_src_folder_name}/clang/lib/Driver/ToolChains/Gnu.cpp"
    fi

    (
      cd "${llvm_src_folder_name}/llvm/tools"

      # This trick will allow to build the toolchain only and still get clang
      for p in clang lld lldb
      do
        if [ ! -e $p ]
        then
            ln -s ../../$p .
        fi
      done
    )

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_folder_name}"

      if [ -n "${name_suffix}" ]
      then

        # Use XBB libs in native-llvm
        xbb_activate_dev

        # Required to satisfy the reference to /opt/xbb/lib/libncurses.so.
        xbb_activate_libs

        # CPPFLAGS="${XBB_CPPFLAGS} -I${XBB_FOLDER_PATH}/include/ncurses"
        CPPFLAGS="${XBB_CPPFLAGS}"
        CFLAGS="${XBB_CFLAGS_NO_W}"
        CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

        LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      else

        # Use install/libs/lib & include
        xbb_activate_installed_dev

        CPPFLAGS="${XBB_CPPFLAGS}"
        CFLAGS="${XBB_CFLAGS_NO_W}"
        CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

        # Non-static will have trouble to find the llvm bootstrap libc++.
        LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
        # LDFLAGS="${XBB_LDFLAGS_APP}"

        if [ "${TARGET_PLATFORM}" == "linux" ]
        then
          LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
        elif [ "${TARGET_PLATFORM}" == "darwin" ]
        then
          LDFLAGS+=" -Wl,-search_paths_first"

          # The macOS variant needs to compile lots of .mm files
          # (in lldb, for example HostThreadMacOSX.mm), and
          # GCC chokes at them, making clang mandatory.

          export CC=clang
          export CXX=clang++
        elif [ "${TARGET_PLATFORM}" == "win32" ]
        then
          export CC="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang"
          export CXX="${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang++"
        fi

      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "cmake.done" ]
      then
        (
          if [ "${IS_DEVELOP}" == "y" ]
          then
            env | sort
          fi

          echo
          echo "Running llvm${name_suffix} cmake..."

          config_options=()

          config_options+=("-G" "Ninja")

          # https://llvm.org/docs/GettingStarted.html
          # https://llvm.org/docs/CMake.html

          # flang fails:
          # .../flang/runtime/io-stmt.h:65:17: error: 'visit<(lambda at /Users/ilg/Work/clang-11.1.0-1/darwin-x64/sources/llvm-project-11.1.0.src/flang/runtime/io-stmt.h:66:9), const std::__1::variant<std::__1::reference_wrapper<Fortran::runtime::io::OpenStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::CloseStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::NoopCloseStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::InternalFormattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalFormattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalListIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalListIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalFormattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalFormattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalListIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalListIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::UnformattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::UnformattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalMiscIoStatementState>> &>' is unavailable: introduced in macOS 10.13

          # Colon separated list of directories clang will search for headers.
          # config_options+=("-DC_INCLUDE_DIRS=:")

          # Distributions should never be built using the
          # BUILD_SHARED_LIBS CMake option.
          # https://llvm.org/docs/BuildingADistribution.html
          config_options+=("-DBUILD_SHARED_LIBS=OFF")

          config_options+=("-DCLANG_INCLUDE_TESTS=OFF")

          config_options+=("-DCMAKE_BUILD_TYPE=Release")
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}${name_suffix}")

          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}")
          config_options+=("-DCMAKE_C_COMPILER=${CC}")

          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")

          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          if [ -n "${name_suffix}" ]
          then

            # Please note the trailing space.
            config_options+=("-DCLANG_VENDOR=${LLVM_BOOTSTRAP_BRANDING} ")
            config_options+=("-DFLANG_VENDOR=${LLVM_BOOTSTRAP_BRANDING} ")
            config_options+=("-DLLD_VENDOR=${LLVM_BOOTSTRAP_BRANDING} ")
            config_options+=("-DPACKAGE_VENDOR=${LLVM_BOOTSTRAP_BRANDING} ")

            config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF")
            config_options+=("-DLLDB_INCLUDE_TESTS=OFF")

          else

            # Please note the trailing space.
            config_options+=("-DCLANG_VENDOR=${LLVM_BRANDING} ")
            config_options+=("-DFLANG_VENDOR=${LLVM_BRANDING} ")
            config_options+=("-DLLD_VENDOR=${LLVM_BRANDING} ")
            config_options+=("-DPACKAGE_VENDOR=${LLVM_BRANDING} ")

            config_options+=("-DCLANG_EXECUTABLE_VERSION=${llvm_version_major}")

            # Prefer the locally compiled libraries.
            config_options+=("-DCMAKE_INCLUDE_PATH=${LIBS_INSTALL_FOLDER_PATH}/include")
            if [ -d "${LIBS_INSTALL_FOLDER_PATH}/lib64" ]
            then
              config_options+=("-DCMAKE_LIBRARY_PATH=${LIBS_INSTALL_FOLDER_PATH}/lib64;${LIBS_INSTALL_FOLDER_PATH}/lib")
            else
              config_options+=("-DCMAKE_LIBRARY_PATH=${LIBS_INSTALL_FOLDER_PATH}/lib")
            fi

            config_options+=("-DCURSES_INCLUDE_PATH=${LIBS_INSTALL_FOLDER_PATH}/include/ncurses")

            config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=OFF")

            config_options+=("-DCUDA_64_BIT_DEVICE_CODE=OFF")

            config_options+=("-DLLDB_ENABLE_LUA=OFF")
            config_options+=("-DLLDB_ENABLE_PYTHON=OFF")
            config_options+=("-DLLDB_INCLUDE_TESTS=OFF")
            config_options+=("-DLLDB_USE_SYSTEM_DEBUGSERVER=ON")

            config_options+=("-DLLVM_BUILD_DOCS=OFF")
            config_options+=("-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON")
            config_options+=("-DLLVM_BUILD_TESTS=OFF")
            config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF")
            config_options+=("-DLLVM_ENABLE_BACKTRACES=OFF")
            config_options+=("-DLLVM_ENABLE_DOXYGEN=OFF")
            config_options+=("-DLLVM_ENABLE_EH=ON")
            config_options+=("-DLLVM_ENABLE_LTO=OFF")
            config_options+=("-DLLVM_ENABLE_RTTI=ON")
            config_options+=("-DLLVM_ENABLE_SPHINX=OFF")
            config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")
            config_options+=("-DLLVM_ENABLE_Z3_SOLVER=OFF")
            config_options+=("-DLLVM_INCLUDE_DOCS=OFF") # No docs
            config_options+=("-DLLVM_INCLUDE_TESTS=OFF") # No tests
            config_options+=("-DLLVM_INCLUDE_EXAMPLES=OFF") # No examples
            # Better not, use the explicit `llvm-*` names.
            config_options+=("-DLLVM_INSTALL_BINUTILS_SYMLINKS=OFF")

          fi

          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then

            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
            # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")

            # To help find the locally compiled `ld.gold`.
            # https://cmake.org/cmake/help/v3.4/variable/CMAKE_PROGRAM_PATH.html
            # https://cmake.org/cmake/help/v3.4/command/find_program.html
            config_options+=("-DCMAKE_PROGRAM_PATH=${APP_PREFIX}/bin")

            config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

            # This distribution expects the SDK to be in this location.
            config_options+=("-DDEFAULT_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")

            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=OFF")
            # Fails with: LLVM_BUILTIN_TARGETS isn't implemented for Darwin platform!
            # config_options+=("-DLLVM_BUILTIN_TARGETS=${TARGET}")

            # The libc++ & Co are not included because the system dynamic
            # libraries are prefered by the linker anyway, and attempts to
            # force the inclusion of the static library failed:
            # ld: warning: linker symbol '$ld$hide$os10.4$__Unwind_Backtrace' hides a non-existent symbol '__Unwind_Backtrace'

            # config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt")

            config_options+=("-DLLVM_ENABLE_FFI=ON")
            config_options+=("-DLLVM_HOST_TRIPLE=${TARGET}")
            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")
            # Fails with: Please use architecture with 4 or 8 byte pointers.
            # config_options+=("-DLLVM_RUNTIME_TARGETS=${TARGET}")

            if [ "${TARGET_ARCH}" == "x64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${TARGET_ARCH}" == "arm64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
            else
              echo "Oops! Unsupported TARGET_ARCH=${TARGET_ARCH}."
              exit 1
            fi

            # No longer needed if disabled in LLVM_ENABLE_PROJECTS.
            if false
            then
            config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")
            config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")
            config_options+=("-DLIBCXX_USE_COMPILER_RT=ON")

            config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF")
            config_options+=("-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON")
            config_options+=("-DLIBCXXABI_INSTALL_LIBRARY=OFF")
            config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON")
            config_options+=("-DLIBCXXABI_USE_LLVM_UNWINDER=ON")

            config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")
            config_options+=("-DLIBUNWIND_INSTALL_LIBRARY=OFF")
            config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON")
            fi

            config_options+=("-DMACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}")

          elif [ "${TARGET_PLATFORM}" == "linux" ]
          then

            # LLVMgold.so
            # https://llvm.org/docs/GoldPlugin.html#how-to-build-it
            # /Host/home/ilg/Work/clang-11.1.0-1/linux-ia32/install/clang/bin/ld.gold: error: /Host/home/ilg/Work/clang-11.1.0-1/linux-ia32/install/clang/bin/../lib/LLVMgold.so: could not load plugin library: /Host/home/ilg/Work/clang-11.1.0-1/linux-ia32/install/clang/bin/../lib/LLVMgold.so: cannot open shared object file: No such file or directory
            # Then either gold was not configured with plugins enabled, or clang
            # was not built with `-DLLVM_BINUTILS_INCDIR` set properly.

            if [ "${TARGET_ARCH}" == "x64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${TARGET_ARCH}" == "ia32" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${TARGET_ARCH}" == "arm64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
            elif [ "${TARGET_ARCH}" == "arm" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=ARM")
            else
              echo "Oops! Unsupported TARGET_ARCH=${TARGET_ARCH}."
              exit 1
            fi

            # It is safer to use the system GNU C++ library.
            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libstdc++")

            # ld.gold has a problem with --gc-sections and fails
            # several tests on Ubuntu 18
            # https://sourceware.org/bugzilla/show_bug.cgi?id=23880
            # Better keep the system GNU linker (ld), and use lld only
            # when requested with -fuse-ld=lld.
            # config_options+=("-DCLANG_DEFAULT_LINKER=gold")

            # Fails late in the build!
            # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")

            # To help find the just locally compiled `ld.gold`.
            # https://cmake.org/cmake/help/v3.4/variable/CMAKE_PROGRAM_PATH.html
            # https://cmake.org/cmake/help/v3.4/command/find_program.html
            config_options+=("-DCMAKE_PROGRAM_PATH=${APP_PREFIX}/bin")

            config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

            config_options+=("-DLLVM_BINUTILS_INCDIR=${SOURCES_FOLDER_PATH}/binutils-${BINUTILS_VERSION}/include")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=OFF")
            config_options+=("-DLLVM_BUILTIN_TARGETS=${TARGET}")

            # Disabled once XBB moved to Ubuntu 18.
            if false # [ "${TARGET_ARCH}" == "arm64" -o "${TARGET_ARCH}" == "arm" ]
            then
              # lldb requires some ptrace definitions like SVE_PT_FPSIMD_OFFSET:
              # not available in Ubuntu 16;
              # llvm/tools/lldb/source/Plugins/Process/Linux/NativeRegisterContextLinux_arm64.cpp:1140:42: error: ‘SVE_PT_FPSIMD_OFFSET’ was not declared in this scope
              # Enable lldb when an Ubuntu 18 Docker XBB image will be available.
              config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;polly;compiler-rt;libcxx;libcxxabi;libunwind")
            else
              config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")
            fi

            # TOOLCHAIN_ONLY requires manual install for LLVMgold.so and
            # lots of other files; not worth the effort and risky.
            # config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")
            # config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres")

            config_options+=("-DLLVM_ENABLE_FFI=ON")
            config_options+=("-DLLVM_HOST_TRIPLE=${TARGET}")
            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")
            config_options+=("-DLLVM_RUNTIME_TARGETS=${TARGET}")
            config_options+=("-DLLVM_TOOL_GOLD_BUILD=ON")

            # For now keep the default configuration, which creates both
            # shred and static libs, but they are not directly
            # usable, since they require complex LD_LIBRARY_PATH and
            # explicit link optios; the crt tests were disabled.
            if false
            then
              config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")
              config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")
              config_options+=("-DLIBCXX_USE_COMPILER_RT=ON")

              config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF")
              config_options+=("-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON")
              config_options+=("-DLIBCXXABI_INSTALL_LIBRARY=OFF")
              config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON")
              config_options+=("-DLIBCXXABI_USE_LLVM_UNWINDER=ON")

              config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")
              config_options+=("-DLIBUNWIND_INSTALL_LIBRARY=OFF")
              config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON")
            fi

          elif [ "${TARGET_PLATFORM}" == "win32" ]
          then

            # Mind the links in llvm to clang, lld, lldb.
            config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")
            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres")

            if [ ! -n "${name_suffix}" ]
            then
              config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
              config_options+=("-DCLANG_DEFAULT_LINKER=lld")
              config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")

              config_options+=("-DCMAKE_CROSSCOMPILING=ON")

              config_options+=("-DCMAKE_FIND_ROOT_PATH=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/${TARGET}")
              config_options+=("-DCMAKE_RC_COMPILER=${RC}")

              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY")
              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY")
              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER")

              config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

              config_options+=("-DCLANG_TABLEGEN=${BUILD_FOLDER_PATH}/${llvm_folder_name}${BOOTSTRAP_SUFFIX}/bin/clang-tblgen")
              config_options+=("-DLLDB_TABLEGEN=${BUILD_FOLDER_PATH}/${llvm_folder_name}${BOOTSTRAP_SUFFIX}/bin/lldb-tblgen")
              config_options+=("-DLLVM_TABLEGEN=${BUILD_FOLDER_PATH}/${llvm_folder_name}${BOOTSTRAP_SUFFIX}/bin/llvm-tblgen")

              config_options+=("-DCROSS_TOOLCHAIN_FLAGS_NATIVE=")

              config_options+=("-DLLVM_CONFIG_PATH=${BUILD_FOLDER_PATH}/${llvm_folder_name}${BOOTSTRAP_SUFFIX}/bin/llvm-config")

              config_options+=("-DLLVM_HOST_TRIPLE=${TARGET}")
            fi

            # https://llvm.org/docs/BuildingADistribution.html#options-for-reducing-size
            # This option is not available on Windows
            # config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            # config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")

            # compiler-rt, libunwind, libc++ and libc++-abi are built
            # in separate steps intertwined with mingw.

          else
            echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
            exit 1
          fi

          echo
          which ${CC}
          ${CC} --version

          run_verbose_timed cmake \
            "${config_options[@]}" \
            "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm"

          touch "cmake.done"

        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/cmake-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running llvm${name_suffix} build..."

        if [ "${IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake --build . --verbose
          run_verbose cmake --build .  --verbose  --target install/strip
        else
          run_verbose_timed cmake --build .
          run_verbose cmake --build . --target install/strip
        fi

        if [ -n "${name_suffix}" ]
        then
          (
            # Add wrappers for the mingw-w64 binaries.
            cd "${APP_PREFIX}${name_suffix}/bin"

            cp "${BUILD_GIT_PATH}/wrappers"/*-wrapper.sh .

            for exec in clang-target-wrapper dlltool-wrapper windres-wrapper llvm-wrapper
            do
              ${CC} "${BUILD_GIT_PATH}/wrappers/${exec}.c" -O2 -v -o ${exec}
            done

            for exec in clang clang++ gcc g++ cc c99 c11 c++ as
            do
              ln -sf clang-target-wrapper.sh ${CROSS_COMPILE_PREFIX}-${exec}
            done
            for exec in addr2line ar ranlib nm objcopy strings strip
            do
              ln -sf llvm-${exec} ${CROSS_COMPILE_PREFIX}-${exec}
            done
            if [ -f "llvm-windres" ]
            then
              # windres can't use llvm-wrapper, as that loses the original
              # target arch prefix.
              ln -sf llvm-windres ${CROSS_COMPILE_PREFIX}-windres
            else
              ln -sf windres-wrapper ${CROSS_COMPILE_PREFIX}-windres
            fi
            ln -sf dlltool-wrapper ${CROSS_COMPILE_PREFIX}-dlltool
            for exec in ld objdump
            do
              ln -sf ${exec}-wrapper.sh ${CROSS_COMPILE_PREFIX}-${exec}
            done
          )
        else
          (
            echo
            echo "Removing less used files..."

            # Remove less used LLVM libraries and leave only the toolchain.
            cd "${APP_PREFIX}/bin"
            for f in bugpoint c-index-test \
              clang-apply-replacements clang-change-namespace \
              clang-extdef-mapping clang-include-fixer clang-move clang-query \
              clang-reorder-fields find-all-symbols \
              count dsymutil FileCheck \
              llc lli lli-child-target llvm-bcanalyzer llvm-c-test \
              llvm-cat llvm-cfi-verify llvm-cvtres \
              llvm-dwarfdump llvm-dwp \
              llvm-elfabi llvm-jitlink-executor llvm-exegesis llvm-extract llvm-gsymutil \
              llvm-ifs llvm-install-name-tool llvm-jitlink llvm-link \
              llvm-lipo llvm-lto llvm-lto2 llvm-mc llvm-mca llvm-ml \
              llvm-modextract llvm-mt llvm-opt-report llvm-pdbutil \
              llvm-profgen \
              llvm-PerfectShuffle llvm-reduce llvm-rtdyld llvm-split \
              llvm-stress llvm-undname llvm-xray \
              modularize not obj2yaml opt pp-trace sancov sanstats \
              scan-build scan-build.bat scan-view \
              verify-uselistorder yaml-bench yaml2obj
            do
              rm -rfv $f $f${DOT_EXE}
            done

            # So far not used.
            rm -rfv libclang.dll
            rm -rfv ld64.lld.exe ld64.lld.darwinnew.exe lld-link.exe wasm-ld.exe

            cd "${APP_PREFIX}/include"
            run_verbose rm -rf clang clang-c clang-tidy lld lldb llvm llvm-c polly

            cd "${APP_PREFIX}/lib"
            run_verbose rm -rfv libclang*.a libClangdXPCLib* libf*.a liblld*.a libLLVM*.a libPolly*.a
            # rm -rf cmake/lld cmake/llvm cmake/polly

            cd "${APP_PREFIX}/share"
            run_verbose rm -rf man
          )

          if [ "${TARGET_PLATFORM}" == "win32" ]
          then
            echo
            echo "Add wrappers instead of links..."

            cd "${APP_PREFIX}/bin"

            # dlltool-wrapper windres-wrapper llvm-wrapper
            for exec in clang-target-wrapper
            do
              run_verbose ${CC} "${BUILD_GIT_PATH}/wrappers/${exec}.c" -o "${exec}.exe" -O2 -Wl,-s -municode -DCLANG=\"clang-${llvm_version_major}\" -DDEFAULT_TARGET=\"${CROSS_COMPILE_PREFIX}\"
            done

            if [ ! -L clang.exe ] && [ -f clang.exe ] && [ ! -f clang-${llvm_version_major}.exe ]
            then
              mv -v clang.exe clang-${llvm_version_major}.exe
            fi

            # clang clang++ gcc g++ cc c99 c11 c++ addr2line ar
            # dlltool ranlib nm objcopy strings strip windres
            for exec in clang clang++ clang-cl clang-cpp
            do
                ln -sfv clang-target-wrapper.exe ${exec}.exe
            done
          fi
        fi

        if [ -n "${name_suffix}" ]
        then
          show_native_libs "${APP_PREFIX}${name_suffix}/bin/clang"
          show_native_libs "${APP_PREFIX}${name_suffix}/bin/llvm-nm"
        else
          show_libs "${APP_PREFIX}/bin/clang"
          show_libs "${APP_PREFIX}/bin/llvm-nm"
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/build-output-$(ndate).txt"

      if [ ! -n "${name_suffix}" ]
      then
        copy_license \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm" \
          "${llvm_folder_name}"
      fi
    )

    touch "${llvm_stamp_file_path}"

  else
    echo "Component llvm${name_suffix} already installed."
  fi

  if [ -n "${name_suffix}" ]
  then
    tests_add "test_llvm_bootstrap"
  else
    tests_add "test_llvm_final"
  fi
}

function test_llvm_bootstrap()
{
  (
    # Use XBB libs in native-llvm
    xbb_activate_libs

    test_llvm "${BOOTSTRAP_SUFFIX}"
  )
}

function test_llvm_final()
{
  (
    test_llvm
  )
}

function test_llvm()
{
  local name_suffix=${1-''}

  echo
  echo "Testing the llvm${name_suffix} binaries..."

  (
    if [ -d "xpacks/.bin" ]
    then
      TEST_BIN_PATH="$(pwd)/xpacks/.bin"
    elif [ -d "${APP_PREFIX}${name_suffix}/bin" ]
    then
      TEST_BIN_PATH="${APP_PREFIX}${name_suffix}/bin"
    else
      echo "Wrong folder."
      exit 1
    fi

    run_verbose ls -l "${TEST_BIN_PATH}"

    if [ -n "${name_suffix}" ]
    then
      # Help the loader find the .dll files if the native is not static.
      export WINEPATH=${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}/bin

      CC="${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}-clang"
      CXX="${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}-clang++"
      DLLTOOL="${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}-dlltool"
      WIDL="${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}-widl"
      GENDEF="${TEST_BIN_PATH}/gendef"
      AR="${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}-ar"
      RANLIB="${TEST_BIN_PATH}/${CROSS_COMPILE_PREFIX}-ranlib"
    else
      CC="${TEST_BIN_PATH}/clang"
      CXX="${TEST_BIN_PATH}/clang++"
      DLLTOOL="${TEST_BIN_PATH}/llvm-dlltool"
      WIDL="${TEST_BIN_PATH}/widl"
      GENDEF="${TEST_BIN_PATH}/gendef"
      AR="${TEST_BIN_PATH}/llvm-ar"
      RANLIB="${TEST_BIN_PATH}/llvm-ranlib"
    fi

    show_libs "${TEST_BIN_PATH}/clang"
    show_libs "${TEST_BIN_PATH}/lld"
    if [ -f "${TEST_BIN_PATH}/lldb" ]
    then
      # lldb not available on Ubuntu 16 Arm.
      show_libs "${TEST_BIN_PATH}/lldb"
    fi

    echo
    echo "Testing if llvm binaries start properly..."

    run_app "${TEST_BIN_PATH}/clang" --version
    run_app "${TEST_BIN_PATH}/clang++" --version

    if [ -f "${TEST_BIN_PATH}/clang-format${DOT_EXE}" ]
    then
      run_app "${TEST_BIN_PATH}/clang-format" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    run_app "${TEST_BIN_PATH}/lld" --version || true
    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      run_app "${TEST_BIN_PATH}/ld.lld" --version || true
    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      run_app "${TEST_BIN_PATH}/ld64.lld" --version || true
    elif [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${TEST_BIN_PATH}/ld-link" --version || true
    fi

    run_app "${TEST_BIN_PATH}/llvm-ar" --version
    run_app "${TEST_BIN_PATH}/llvm-nm" --version
    run_app "${TEST_BIN_PATH}/llvm-objcopy" --version
    run_app "${TEST_BIN_PATH}/llvm-objdump" --version
    run_app "${TEST_BIN_PATH}/llvm-ranlib" --version
    if [ -f "${TEST_BIN_PATH}/llvm-readelf" ]
    then
      run_app "${TEST_BIN_PATH}/llvm-readelf" --version
    fi
    if [ -f "${TEST_BIN_PATH}/llvm-size" ]
    then
      run_app "${TEST_BIN_PATH}/llvm-size" --version
    fi
    run_app "${TEST_BIN_PATH}/llvm-strings" --version
    run_app "${TEST_BIN_PATH}/llvm-strip" --version

    echo
    echo "Testing clang configuration..."

    run_app "${TEST_BIN_PATH}/clang" -print-target-triple
    run_app "${TEST_BIN_PATH}/clang" -print-targets
    run_app "${TEST_BIN_PATH}/clang" -print-supported-cpus
    run_app "${TEST_BIN_PATH}/clang" -print-search-dirs
    run_app "${TEST_BIN_PATH}/clang" -print-resource-dir
    run_app "${TEST_BIN_PATH}/clang" -print-libgcc-file-name

    # run_app "${TEST_BIN_PATH}/llvm-config" --help

    echo
    echo "Testing if clang compiles simple Hello programs..."

    local tests_folder_path="${WORK_FOLDER_PATH}/${TARGET_FOLDER_NAME}"
    mkdir -pv "${tests_folder_path}/tests"
    local tmp="$(mktemp "${tests_folder_path}/tests/test-clang${name_suffix}-XXXXXXXXXX")"
    rm -rf "${tmp}"

    mkdir -p "${tmp}"
    cd "${tmp}"

    echo
    echo "pwd: $(pwd)"

    local VERBOSE_FLAG=""
    if [ "${IS_DEVELOP}" == "y" ]
    then
      VERBOSE_FLAG="-v"
    fi

    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      LD_GC_SECTIONS="-Wl,--gc-sections"
    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      LD_GC_SECTIONS="-Wl,-dead_strip"
    else
      LD_GC_SECTIONS=""
    fi

    echo
    env | sort

    run_verbose uname
    if [ "${TARGET_PLATFORM}" != "darwin" ]
    then
      run_verbose uname -o
    fi

    # -------------------------------------------------------------------------

    # `-fuse-ld=lld` fails on macOS:
    # ld64.lld: warning: ignoring unknown argument: -no_deduplicate
    # ld64.lld: warning: -sdk_version is required when emitting min version load command.  Setting sdk version to match provided min version
    # For now use the system linker /usr/bin/ld.

    # -static-libstdc++ not available on macOS:
    # clang-11: warning: argument unused during compilation: '-static-libstdc++'

    # -------------------------------------------------------------------------

    run_verbose cp -v -r "${helper_folder_path}/tests/c-cpp"/* .

    # -------------------------------------------------------------------------

    (
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        # Instruct the linker to add a RPATH pointing to the folder with the
        # compiler shared libraries. Alternatelly -Wl,-rpath=xxx can be used
        # explicitly on each link command.
        export LD_RUN_PATH="$(dirname $(realpath $(${CC} --print-file-name=libgcc_s.so)))"
        echo
        echo "LD_RUN_PATH=${LD_RUN_PATH}"
      elif [ "${TARGET_PLATFORM}" == "win32" -a ! -n "${name_suffix}" ]
      then
        # For libwinpthread-1.dll, possibly other.
        if [ "$(uname -o)" == "Msys" ]
        then
          export PATH="${TEST_BIN_PATH}/lib;${PATH:-}"
          echo "PATH=${PATH}"
        elif [ "$(uname)" == "Linux" ]
        then
          export WINEPATH="${TEST_BIN_PATH}/lib;${WINEPATH:-}"
          echo "WINEPATH=${WINEPATH}"
        fi
      fi

      test_clang_one "${name_suffix}"
      test_clang_one "${name_suffix}" --gc
      test_clang_one "${name_suffix}" --lto
      test_clang_one "${name_suffix}" --gc --lto

      # C++ with compiler-rt fails on Intel and Arm 32 Linux.
      if [ "${TARGET_PLATFORM}" == "linux" ] # -a "${TARGET_ARCH}" == "arm" ]
      then
        echo
        echo "Skip all --crt on Linux."
      else
        test_clang_one "${name_suffix}" --crt
        test_clang_one "${name_suffix}" --gc --crt
        test_clang_one "${name_suffix}" --lto --crt
        test_clang_one "${name_suffix}" --gc --lto --crt
      fi
    )

    if [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      echo
      echo "Skip all --static-lib on macOS."
    else
      # Except on macOS, the recommended use case is with `-static-libgcc`,
      # and the following combinations are expected to work properly on
      # Linux and Windows.
      local distro=$(lsb_release -is)
      if [[ ${distro} == CentOS ]] || [[ ${distro} == RedHat* ]] || [[ ${distro} == Fedora ]]
      then
        # Unfortunatelly this is not true on RedHat, which has no libstdc++.a:
        # /usr/bin/ld: cannot find -lstdc++
        echo
        echo "Skip all --static-lib on RedHat & derived."
      else
        test_clang_one "${name_suffix}" --static-lib
        test_clang_one "${name_suffix}" --static-lib --gc
        test_clang_one "${name_suffix}" --static-lib --lto
        test_clang_one "${name_suffix}" --static-lib --gc --lto
      fi
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        # Static lib and compiler-rt fail on Linux x86_64 and ia32
        echo
        echo "Skip all --static-lib --crt on Linux."
      else
        test_clang_one "${name_suffix}" --static-lib --crt
        test_clang_one "${name_suffix}" --static-lib --gc --crt
        test_clang_one "${name_suffix}" --static-lib --lto --crt
        test_clang_one "${name_suffix}" --static-lib --gc --lto --crt
      fi
    fi

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then

      test_clang_one "${name_suffix}" --static
      test_clang_one "${name_suffix}" --static --gc
      test_clang_one "${name_suffix}" --static --lto
      test_clang_one "${name_suffix}" --static --gc --lto
      test_clang_one "${name_suffix}" --static --crt
      test_clang_one "${name_suffix}" --static --gc --crt
      test_clang_one "${name_suffix}" --static --lto --crt
      test_clang_one "${name_suffix}" --static --gc --lto --crt

    elif [ "${TARGET_PLATFORM}" == "linux" ]
    then

      # On Linux static linking is highly discouraged.
      # On RedHat and derived, the static libraries must be installed explicitly.

      echo
      echo "Skip all --static on Linux."

    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then

      # On macOS static linking is not available at all.
      echo
      echo "Skip all --static on macOS."

    fi

    # -------------------------------------------------------------------------

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" -o add.o -c add.c -ffunction-sections -fdata-sections
    else
      run_app "${CC}" -o add.o -fpic -c add.c -ffunction-sections -fdata-sections
    fi

    rm -rf libadd-static.a
    run_app "${AR}" -r ${VERBOSE_FLAG} libadd-static.a add.o
    run_app "${RANLIB}" libadd-static.a

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # The `--out-implib` creates an import library, which can be
      # directly used with -l.
      run_app "${CC}" ${VERBOSE_FLAG} -shared -o libadd-shared.dll -Wl,--out-implib,libadd-shared.dll.a add.o -Wl,--subsystem,windows
    else
      run_app "${CC}" -o libadd-shared.${SHLIB_EXT} -shared add.o
    fi

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" -o rt-add.o -c add.c -ffunction-sections -fdata-sections
    else
      run_app "${CC}" -o rt-add.o -fpic -c add.c -ffunction-sections -fdata-sections
    fi

    rm -rf libadd-add-static.a
    run_app "${AR}" -r ${VERBOSE_FLAG} librt-add-static.a rt-add.o
    run_app "${RANLIB}" librt-add-static.a

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" -shared -o librt-add-shared.dll -Wl,--out-implib,librt-add-shared.dll.a rt-add.o -rtlib=compiler-rt
    else
      run_app "${CC}" -o librt-add-shared.${SHLIB_EXT} -shared rt-add.o -rtlib=compiler-rt
    fi

    run_app "${CC}" ${VERBOSE_FLAG} -o static-adder${DOT_EXE} adder.c -ladd-static -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}

    test_expect "static-adder" "42" 40 2

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # -ladd-shared is in fact libadd-shared.dll.a
      # The library does not show as DLL, it is loaded dynamically.
      run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder${DOT_EXE} adder.c -ladd-shared -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    else
      run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder adder.c -ladd-shared -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    fi

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
      test_expect "shared-adder" "42" 40 2
    )

    run_app "${CC}" ${VERBOSE_FLAG} -o rt-static-adder${DOT_EXE} adder.c -lrt-add-static -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}

    test_expect "rt-static-adder" "42" 40 2

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # -lrt-add-shared is in fact librt-add-shared.dll.a
      # The library does not show as DLL, it is loaded dynamically.
      run_app "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder${DOT_EXE} adder.c -lrt-add-shared -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    else
      run_app "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder adder.c -lrt-add-shared -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    fi

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
      test_expect "rt-shared-adder" "42" 40 2
    )

    # -------------------------------------------------------------------------
    # Tests borrowed from the llvm-mingw project.

    # run_app "${CC}" hello.c -o hello${DOT_EXE} ${VERBOSE_FLAG} -lm
    # show_libs hello
    # run_app ./hello

    # run_app "${CC}" setjmp-patched.c -o setjmp${DOT_EXE} ${VERBOSE_FLAG} -lm
    # show_libs setjmp
    # run_app ./setjmp

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" hello-tls.c -o hello-tls.exe ${VERBOSE_FLAG}
      show_libs hello-tls
      run_app ./hello-tls

      run_app "${CC}" crt-test.c -o crt-test.exe ${VERBOSE_FLAG}
      show_libs crt-test
      run_app ./crt-test

      run_app "${CC}" autoimport-lib.c -shared -o autoimport-lib.dll -Wl,--out-implib,libautoimport-lib.dll.a ${VERBOSE_FLAG}
      show_libs autoimport-lib.dll

      run_app "${CC}" autoimport-main.c -o autoimport-main.exe -L. -lautoimport-lib ${VERBOSE_FLAG}
      show_libs autoimport-main
      run_app ./autoimport-main

      # The IDL output isn't arch specific, but test each arch frontend
      run_app "${WIDL}" idltest.idl -h -o idltest.h
      run_app "${CC}" idltest.c -I. -o idltest.exe -lole32 ${VERBOSE_FLAG}
      show_libs idltest
      run_app ./idltest
    fi

    # for test in hello-cpp hello-exception exception-locale exception-reduced global-terminate longjmp-cleanup
    # do
    #   run_app ${CXX} $test.cpp -o $test${DOT_EXE} ${VERBOSE_FLAG}
    #   show_libs $test
    #   run_app ./$test
    # done

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app ${CXX} hello-exception.cpp -static -o hello-exception-static${DOT_EXE} ${VERBOSE_FLAG}

      show_libs hello-exception-static
      run_app ./hello-exception-static

      run_app ${CXX} tlstest-lib.cpp -shared -o tlstest-lib.dll -Wl,--out-implib,libtlstest-lib.dll.a ${VERBOSE_FLAG}
      show_libs tlstest-lib.dll

      run_app ${CXX} tlstest-main.cpp -o tlstest-main.exe ${VERBOSE_FLAG}
      show_libs tlstest-main
      run_app ./tlstest-main
    fi

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app ${CXX} throwcatch-lib.cpp -shared -o throwcatch-lib.dll -Wl,--out-implib,libthrowcatch-lib.dll.a ${VERBOSE_FLAG}
    elif [ "$(lsb_release -rs)" == "12.04" -a \( "$(uname -m)" == "x86_64" -o "$(uname -m)" == "i686" \) ]
    then
      run_app ${CXX} throwcatch-lib.cpp -shared -fpic -o libthrowcatch-lib.${SHLIB_EXT} ${VERBOSE_FLAG} -fuse-ld=lld
    else
      run_app ${CXX} throwcatch-lib.cpp -shared -fpic -o libthrowcatch-lib.${SHLIB_EXT} ${VERBOSE_FLAG}
    fi

    run_app ${CXX} throwcatch-main.cpp -o throwcatch-main${DOT_EXE} -L. -lthrowcatch-lib ${VERBOSE_FLAG}

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}

      show_libs throwcatch-main
      run_app ./throwcatch-main
    )
    # -------------------------------------------------------------------------

  )

  echo
  echo "Testing the llvm${name_suffix} binaries completed successfuly."
}

# ("" | "-bootstrap") [--lto] [--gc] [--crt] [--static|--static-lib]
function test_clang_one()
{
  (
    unset IFS

    local is_gc=""
    local is_lto=""
    local is_crt=""
    local is_static=""
    local is_static_lib=""

    local prefix=""

    local suffix="$1"
    shift

    while [ $# -gt 0 ]
    do
      case "$1" in

        --gc)
        is_gc="y"
        shift
        ;;

        --lto)
        is_lto="y"
        shift
        ;;

        --crt)
        is_crt="y"
        shift
        ;;

        --static)
        is_static="y"
        shift
        ;;

        --static-lib)
        is_static_lib="y"
        shift
        ;;

      *)
        echo "Unknown action/option $1"
        exit 1
        ;;

      esac
    done

    CFLAGS=""
    CXXFLAGS=""
    LDFLAGS=""
    LDXXFLAGS=""

    if [ "${is_crt}" == "y" ]
    then
      LDFLAGS+=" -rtlib=compiler-rt"
      LDXXFLAGS+=" -rtlib=compiler-rt"
      prefix="crt-${prefix}"
    fi

    if [ "${is_lto}" == "y" ]
    then
      CFLAGS+=" -flto"
      CXXFLAGS+=" -flto"
      LDFLAGS+=" -flto"
      LDXXFLAGS+=" -flto"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -fuse-ld=lld"
        LDXXFLAGS+=" -fuse-ld=lld"
      fi
      prefix="lto-${prefix}"
    fi

    if [ "${is_gc}" == "y" ]
    then
      CFLAGS+=" -ffunction-sections -fdata-sections"
      CXXFLAGS+=" -ffunction-sections -fdata-sections"
      LDFLAGS+=" -ffunction-sections -fdata-sections"
      LDXXFLAGS+=" -ffunction-sections -fdata-sections"
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,--gc-sections"
        LDXXFLAGS+=" -Wl,--gc-sections"
      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        LDFLAGS+=" -Wl,-dead_strip"
        LDXXFLAGS+=" -Wl,-dead_strip"
      fi
      prefix="gc-${prefix}"
    fi

    # --static takes precedence over --static-lib.
    if [ "${is_static}" == "y" ]
    then
      LDFLAGS+=" -static"
      LDXXFLAGS+=" -static"
      prefix="static-${prefix}"
    elif [ "${is_static_lib}" == "y" ]
    then
      LDFLAGS+=" -static-libgcc"
      LDXXFLAGS+=" -static-libgcc -static-libstdc++"
      prefix="static-lib-${prefix}"
    fi

    if [ "${IS_DEVELOP}" == "y" ]
    then
      CFLAGS+=" -v"
      CXXFLAGS+=" -v"
      LDFLAGS+=" -v"
      LDXXFLAGS+=" -v"
    fi

    # Test C compile and link in a single step.
    run_app "${CC}" simple-hello.c -o ${prefix}simple-hello-c-one${suffix}${DOT_EXE} ${LDFLAGS}
    test_expect "${prefix}simple-hello-c-one${suffix}" "Hello"

    # Test C compile and link in separate steps.
    run_app "${CC}" -c simple-hello.c -o simple-hello.c.o ${CFLAGS}
    run_app "${CC}" simple-hello.c.o -o ${prefix}simple-hello-c-two${suffix}${DOT_EXE} ${LDFLAGS}
    test_expect "${prefix}simple-hello-c-two${suffix}" "Hello"

    # -------------------------------------------------------------------------

    # Test C++ compile and link in a single step.
    run_app "${CXX}" simple-hello.cpp -o ${prefix}simple-hello-cpp-one${suffix}${DOT_EXE} ${LDXXFLAGS}
    test_expect "${prefix}simple-hello-cpp-one${suffix}" "Hello"

    # Test C++ compile and link in separate steps.
    run_app "${CXX}" -c simple-hello.cpp -o ${prefix}simple-hello${suffix}.cpp.o ${CXXFLAGS}
    run_app "${CXX}" ${prefix}simple-hello${suffix}.cpp.o -o ${prefix}simple-hello-cpp-two${suffix}${DOT_EXE} ${LDXXFLAGS}
    test_expect "${prefix}simple-hello-cpp-two${suffix}" "Hello"

    # -------------------------------------------------------------------------

    if [ \( "${TARGET_PLATFORM}" == "linux"  -a "${is_crt}" == "y" \) ]
    then

      # On Linux it works only with the full LLVM runtime and lld

      run_app "${CXX}" simple-exception.cpp -o ${prefix}simple-exception${suffix}${DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld -v
      test_expect "${prefix}simple-exception${suffix}" "MyException"

      run_app "${CXX}" simple-str-exception.cpp -o ${prefix}simple-str-exception${suffix}${DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
      test_expect "${prefix}simple-str-exception${suffix}" "MyStringException"

      run_app "${CXX}" simple-int-exception.cpp -o ${prefix}simple-int-exception${suffix}${DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
      test_expect "${prefix}simple-int-exception${suffix}" "42"

    else

      run_app "${CXX}" simple-exception.cpp -o ${prefix}simple-exception${suffix}${DOT_EXE} ${LDXXFLAGS}
      test_expect "${prefix}simple-exception${suffix}" "MyException"

      run_app "${CXX}" simple-str-exception.cpp -o ${prefix}simple-str-exception${suffix}${DOT_EXE} ${LDXXFLAGS}
      test_expect "${prefix}simple-str-exception${suffix}" "MyStringException"

      run_app "${CXX}" simple-int-exception.cpp -o ${prefix}simple-int-exception${suffix}${DOT_EXE} ${LDXXFLAGS}
      test_expect "${prefix}simple-int-exception${suffix}" "42"

    fi

    # -------------------------------------------------------------------------
    # Tests borrowed from the llvm-mingw project.

    run_app "${CC}" hello.c -o ${prefix}hello${suffix}${DOT_EXE} ${LDFLAGS} -lm
    show_libs ${prefix}hello${suffix}
    run_app ./${prefix}hello${suffix}

    run_app "${CC}" setjmp-patched.c -o ${prefix}setjmp${suffix}${DOT_EXE} ${LDFLAGS} -lm
    show_libs ${prefix}setjmp${suffix}
    run_app ./${prefix}setjmp${suffix}

    for test in hello-cpp global-terminate
    do
      run_app ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${DOT_EXE} ${LDXXFLAGS}
      show_libs ${prefix}${test}${suffix}
      run_app ./${prefix}${test}${suffix}
    done

    if [ \( "${TARGET_PLATFORM}" == "linux"  -a "${is_crt}" == "y" \) ]
    then

      # /usr/bin/ld: /tmp/longjmp-cleanup-e3da32.o: undefined reference to symbol '_Unwind_Resume@@GCC_3.0'
      run_app ${CXX} longjmp-cleanup.cpp -o ${prefix}longjmp-cleanup${suffix}${DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
      show_libs ${prefix}longjmp-cleanup${suffix}
      run_app ./${prefix}longjmp-cleanup${suffix}

      for test in hello-exception exception-locale exception-reduced
      do
        run_app ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
        show_libs ${prefix}${test}${suffix}
        run_app ./${prefix}${test}${suffix}
      done

    else

      run_app ${CXX} longjmp-cleanup.cpp -o ${prefix}longjmp-cleanup${suffix}${DOT_EXE} ${LDXXFLAGS}
      show_libs ${prefix}longjmp-cleanup${suffix}
      run_app ./${prefix}longjmp-cleanup${suffix}

      for test in hello-exception exception-locale exception-reduced
      do
        run_app ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${DOT_EXE} ${LDXXFLAGS}
        show_libs ${prefix}${test}${suffix}
        run_app ./${prefix}${test}${suffix}
      done

    fi

    run_app "${CC}" -c -o ${prefix}hello-weak${suffix}.c.o hello-weak.c ${CFLAGS}
    run_app "${CC}" -c -o ${prefix}hello-f-weak${suffix}.c.o hello-f-weak.c ${CFLAGS}
    run_app "${CC}" -o ${prefix}hello-weak${suffix}${DOT_EXE} ${prefix}hello-weak${suffix}.c.o ${prefix}hello-f-weak${suffix}.c.o ${VERBOSE_FLAG} -lm ${LDFLAGS}
    test_expect ./${prefix}hello-weak${suffix} "Hello World!"

    if [ \( "${TARGET_PLATFORM}" == "win32"  -a "${is_lto}" == "y" \) ]
    then
      # lld-link: error: duplicate symbol: world()
      # >>> defined at hello-weak-cpp.cpp
      # >>>            lto-hello-weak-cpp.cpp.o
      # >>> defined at hello-f-weak-cpp.cpp
      # >>>            lto-hello-f-weak-cpp.cpp.o
      # clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
      echo "Skip hello-weak-cpp with -flto on Windows."
    else
      run_app "${CXX}" -c -o ${prefix}hello-weak-cpp${suffix}.cpp.o hello-weak-cpp.cpp ${CXXFLAGS}
      run_app "${CXX}" -c -o ${prefix}hello-f-weak-cpp${suffix}.cpp.o hello-f-weak-cpp.cpp ${CXXFLAGS}
      run_app "${CXX}" -o ${prefix}hello-weak-cpp${suffix}${DOT_EXE} ${prefix}hello-weak-cpp${suffix}.cpp.o ${prefix}hello-f-weak-cpp${suffix}.cpp.o ${VERBOSE_FLAG} -lm ${LDXXFLAGS}
      test_expect ./${prefix}hello-weak-cpp${suffix} "Hello World!"
    fi

    # Test weak override.
    (
      cd weak-override

      run_app "${CC}" -c main-weak.c -o ${prefix}main-weak${suffix}.c.o ${CFLAGS}
      run_app "${CC}" -c add2.c -o ${prefix}add2${suffix}.c.o ${CFLAGS}
      run_app "${CC}" -c dummy.c -o ${prefix}dummy${suffix}.c.o ${CFLAGS}
      run_app "${CC}" -c expected3.c -o ${prefix}expected3${suffix}.c.o ${CFLAGS}

      run_app "${CC}" ${prefix}main-weak${suffix}.c.o ${prefix}add2${suffix}.c.o ${prefix}dummy${suffix}.c.o ${prefix}expected3${suffix}.c.o -o ${prefix}weak-override${suffix}${DOT_EXE} ${LDFLAGS}

      run_app ./${prefix}weak-override${suffix}
    )


    # -------------------------------------------------------------------------
  )
}

# $1="${BOOTSTRAP_SUFFIX}"
function build_llvm_compiler_rt()
{
  local name_suffix=${1-''}

  local llvm_compiler_rt_folder_name="llvm-${ACTUAL_LLVM_VERSION}-compiler-rt${name_suffix}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

  local llvm_compiler_rt_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_compiler_rt_folder_name}-installed"
  if [ ! -f "${llvm_compiler_rt_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      if [ "${HOST_MACHINE}" == "i686" ]
      then
        # The 32-bit build fails to find assert.h
        if [ -n "${name_suffix}" ]
        then
          CFLAGS+=" -I${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}/include"
        else
          CFLAGS+=" -I${APP_PREFIX}${name_suffix}/include"
        fi
      fi
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running llvm-compiler-rt${name_suffix} cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if [ -n "${name_suffix}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}")
        else
          # Traditionally the runtime is in a versioned folder.
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}/lib/clang/${ACTUAL_LLVM_VERSION}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")

        if [ "${HOST_MACHINE}" == "x86_64" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=x86_64-windows-gnu")
        elif [ "${HOST_MACHINE}" == "i686" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=i386-windows-gnu")
        else
          echo "Oops! Unsupported HOST_MACHINE=${HOST_MACHINE}."
          exit 1
        fi

        config_options+=("-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON")
        config_options+=("-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON")
        config_options+=("-DSANITIZER_CXX_ABI=libc++")

        # Do not activate it, it fails. And be sure llvm-config is not in the PATH.
        # config_options+=("-DLLVM_CONFIG_PATH=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-config")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/compiler-rt/lib/builtins"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/cmake-output-$(ndate).txt"

      (
        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

        if [ -n "${name_suffix}" ]
        then
          mkdir -pv "${APP_PREFIX}${name_suffix}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/windows"
          for i in lib/windows/libclang_rt.*.a
          do
              cp -v $i "${APP_PREFIX}${name_suffix}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/windows/$(basename $i)"
          done

          mkdir -pv "${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}/bin"
          for i in lib/windows/libclang_rt.*.dll
          do
              if [ -f $i ]
              then
                  cp -v $i "${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}/bin"
              fi
          done
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/build-output-$(ndate).txt"
    )

    touch "${llvm_compiler_rt_stamp_file_path}"

  else
    echo "Component llvm-compiler-rt${name_suffix} already installed."
  fi

}

function build_llvm_libcxx()
{
  local name_suffix=${1-''}

  local llvm_libunwind_folder_name="llvm-${ACTUAL_LLVM_VERSION}-libunwind${name_suffix}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}"

  local llvm_libunwind_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libunwind_folder_name}-installed"
  if [ ! -f "${llvm_libunwind_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libunwind_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libunwind_folder_name}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # CFLAGS="${XBB_CFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"

      LDFLAGS="${XBB_LDFLAGS}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running llvm-libunwind${name_suffix} cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if [ -n "${name_suffix}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}")
        else
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")

        config_options+=("-DLIBUNWIND_ENABLE_THREADS=ON")
        config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")
        config_options+=("-DLIBUNWIND_ENABLE_STATIC=ON")
        config_options+=("-DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF")
        config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON")

        # When compiling the bootstrap, the compiler is not yet fully functional.
        config_options+=("-DLLVM_COMPILER_CHECKED=ON")
        config_options+=("-DLLVM_PATH=${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libunwind"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}/cmake-output-$(ndate).txt"

      (
        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}/build-output-$(ndate).txt"

    )

    touch "${llvm_libunwind_stamp_file_path}"

  else
    echo "Component llvm-libunwind${name_suffix} already installed."
  fi

  # ---------------------------------------------------------------------------

  # Define & prepare the folder, will be used later.
  local llvm_libcxxabi_folder_name="llvm-${ACTUAL_LLVM_VERSION}-libcxxabi${name_suffix}"
  mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

  local llvm_libcxx_folder_name="llvm-${ACTUAL_LLVM_VERSION}-libcxx${name_suffix}"

  mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}"

  local llvm_libcxx_headers_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-headers-installed"
  if [ ! -f "${llvm_libcxx_headers_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # CFLAGS="${XBB_CFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"

      LDFLAGS="${XBB_LDFLAGS}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running llvm-libcxx-headers${name_suffix} cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if [ -n "${name_suffix}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}")
        else
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")

        config_options+=("-DCMAKE_SHARED_LINKER_FLAGS=-lunwind")

        config_options+=("-DLIBCXX_INSTALL_HEADERS=ON")
        config_options+=("-DLIBCXX_ENABLE_EXCEPTIONS=ON")
        config_options+=("-DLIBCXX_ENABLE_THREADS=ON")
        config_options+=("-DLIBCXX_HAS_WIN32_THREAD_API=ON")
        config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")
        config_options+=("-DLIBCXX_ENABLE_STATIC=ON")
        config_options+=("-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF")
        config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")
        config_options+=("-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=OFF")
        config_options+=("-DLIBCXX_CXX_ABI=libcxxabi")
        config_options+=("-DLIBCXX_CXX_ABI_INCLUDE_PATHS=${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxxabi/include")
        config_options+=("-DLIBCXX_CXX_ABI_LIBRARY_PATH=${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/lib")
        config_options+=("-DLIBCXX_LIBDIR_SUFFIX=")
        config_options+=("-DLIBCXX_INCLUDE_TESTS=OFF")
        config_options+=("-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF")
        config_options+=("-DLIBCXX_USE_COMPILER_RT=ON")

        config_options+=("-DLLVM_PATH=${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxx"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/cmake-output-$(ndate).txt"

      (
        # Configure, but don't build libcxx yet, so that libcxxabi has
        # proper headers to refer to.
        run_verbose cmake --build . --verbose --target generate-cxx-headers

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/generate-cxx-headeres-output-$(ndate).txt"

    )

    touch "${llvm_libcxx_headers_stamp_file_path}"

  else
    echo "Component llvm-libcxx-headers${name_suffix} already installed."
  fi

  local llvm_libcxxabi_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libcxxabi_folder_name}-installed"
  if [ ! -f "${llvm_libcxxabi_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # CFLAGS="${XBB_CFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"

      LDFLAGS="${XBB_LDFLAGS}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS
      # Most probably not used

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        echo
        echo "Running llvm-libcxxabi${name_suffix} cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if [ -n "${name_suffix}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}")
        else
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")

        config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON")
        config_options+=("-DLIBCXXABI_ENABLE_EXCEPTIONS=ON")
        config_options+=("-DLIBCXXABI_ENABLE_THREADS=ON")
        config_options+=("-DLIBCXXABI_TARGET_TRIPLE=${TARGET}")
        config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF")
        config_options+=("-DLIBCXXABI_LIBCXX_INCLUDES=${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}/include/c++/v1")
        config_options+=("-DLIBCXXABI_LIBDIR_SUFFIX=")
        config_options+=("-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=ON")

        config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")
        config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")

        config_options+=("-DLLVM_PATH=${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxxabi"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/cmake-output-$(ndate).txt"

      (
        # Configure, but don't build libcxxabi yet, so that libcxxabi has
        # proper headers to refer to.
        run_verbose cmake --build . --verbose

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/build-output-$(ndate).txt"
    )

    touch "${llvm_libcxxabi_stamp_file_path}"

  else
    echo "Component llvm-libcxxabi${name_suffix} already installed."
  fi

  local llvm_libcxx_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-installed"
  if [ ! -f "${llvm_libcxx_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # CFLAGS="${XBB_CFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"

      LDFLAGS="${XBB_LDFLAGS}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS
      # Most probably not used

      (
        if [ "${IS_DEVELOP}" == "y" ]
        then
          env | sort
        fi

        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

        # Append libunwind to libc++.
        if [ -n "${name_suffix}" ]
        then
          run_verbose "${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ar" qcsL \
                  "${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}/lib/libc++.a" \
                  "${APP_PREFIX}${name_suffix}/${CROSS_COMPILE_PREFIX}/lib/libunwind.a"
        else
          run_verbose "${APP_PREFIX}${BOOTSTRAP_SUFFIX}/bin/llvm-ar" qcsL \
                  "${APP_PREFIX}/lib/libc++.a" \
                  "${APP_PREFIX}/lib/libunwind.a"
        fi

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/build-output-$(ndate).txt"

    )

    touch "${llvm_libcxx_stamp_file_path}"

  else
    echo "Component llvm-libcxx${name_suffix} already installed."
  fi
}


function strip_libs()
{
  if [ "${WITH_STRIP}" == "y" ]
  then
    (
      xbb_activate

      echo
      echo "Stripping libraries..."

      cd "${APP_PREFIX}"

      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        local libs=$(find "${APP_PREFIX}" -type f \( -name \*.a -o -name \*.o -o -name \*.so \))
        for lib in ${libs}
        do
          echo "strip -S ${lib}"
          strip -S "${lib}"
        done
      fi
    )
  fi
}

# -----------------------------------------------------------------------------
