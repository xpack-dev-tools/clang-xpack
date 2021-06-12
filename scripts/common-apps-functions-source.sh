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

  local binutils_version="$1"

  local binutils_src_folder_name="binutils-${binutils_version}"
  local binutils_folder_name="binutils-ld.gold-${binutils_version}"

  local binutils_archive="${binutils_src_folder_name}.tar.xz"
  local binutils_url="https://ftp.gnu.org/gnu/binutils/${binutils_archive}"

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

      mkdir -pv "${LOGS_FOLDER_PATH}/${binutils_folder_name}"

      xbb_activate
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP}" 

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

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort

      if [ ! -f "config.status" ]
      then
        (
          echo
          echo "Running binutils ld.gold configure..."
      
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

          bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/configure" \
            ${config_options[@]}
            
          cp "config.log" "${LOGS_FOLDER_PATH}/${binutils_folder_name}/config-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${binutils_folder_name}/configure-output.txt"
      fi

      (
        echo
        echo "Running binutils ld.gold make..."
      
        # Build.
        make -j ${JOBS} all-gold

        if [ "${WITH_TESTS}" == "y" ]
        then
          # gcctestdir/collect-ld: relocation error: gcctestdir/collect-ld: symbol _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm, version GLIBCXX_3.4.21 not defined in file libstdc++.so.6 with link time reference
          : # make maybe-check-gold
        fi
      
        # Avoid strip here, it may interfere with patchelf.
        # make install-strip
        make maybe-install-gold

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
            make maybe-pdf-gold
            make maybe-install-pdf-gold
          fi

          if [ "${WITH_HTML}" == "y" ]
          then
            make maybe-htmp-gold
            make maybe-install-html-gold
          fi
        )

        show_libs "${APP_PREFIX}/bin/ld.gold"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${binutils_folder_name}/make-output.txt"

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
    show_libs "${APP_PREFIX}/bin/ld.gold"

    echo
    echo "Testing if binutils ld.gold starts properly..."

    run_app "${APP_PREFIX}/bin/ld.gold" --version
  )

  echo
  echo "Local binutils ld.gold tests completed successfuly."
}

# -----------------------------------------------------------------------------

function build_llvm() 
{
  # https://llvm.org
  # https://llvm.org/docs/GettingStarted.html
  # https://github.com/llvm/llvm-project/
  # https://github.com/llvm/llvm-project/releases/
  # https://github.com/llvm/llvm-project/releases/tag/llvmorg-11.1.0/
  # https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/llvm-project-11.1.0.src.tar.xz

  # https://archlinuxarm.org/packages/aarch64/llvm/files/PKGBUILD

  # https://llvm.org/docs/GoldPlugin.html#lto-how-to-build
  # https://llvm.org/docs/BuildingADistribution.html

  # 17 Feb 2021, "11.1.0"

  local llvm_version="$1"

  local llvm_version_major=$(echo ${llvm_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')
  local llvm_version_minor=$(echo ${llvm_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')

  local llvm_src_folder_name="llvm-project-${llvm_version}.src"
  local llvm_folder_name="llvm-${llvm_version}"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/${llvm_archive}"

  local llvm_patch_file_name="llvm-${llvm_version}.patch"

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

    mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_folder_name}"

      xbb_activate
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      
      if [ "${TARGET_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,-rpath,${LD_LIBRARY_PATH}"
      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        LDFLAGS+=" -Wl,-search_paths_first"
      fi

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort

      if [ ! -f "config.status" ]
      then
        (
          echo
          echo "Running llvm cmake..."

          config_options=()

          config_options+=("-GNinja")

          # https://llvm.org/docs/GettingStarted.html
          # https://llvm.org/docs/CMake.html

          # Many options copied from HomeBrew.

          # Colon separated list of directories clang will search for headers.
          # config_options+=("-DC_INCLUDE_DIRS=:")


          config_options+=("-DCLANG_EXECUTABLE_VERSION=${llvm_version_major}")

          # Please note the trailing space.
          config_options+=("-DCLANG_VENDOR=${LLVM_BRANDING} ")
          config_options+=("-DFLANG_VENDOR=${LLVM_BRANDING} ")
          config_options+=("-DLLD_VENDOR=${LLVM_BRANDING} ")
          config_options+=("-DPACKAGE_VENDOR=${LLVM_BRANDING} ")

          config_options+=("-DCLANG_INCLUDE_TESTS=OFF")

          config_options+=("-DCMAKE_BUILD_TYPE=Release")
          config_options+=("-DCMAKE_C_COMPILER=${CC}")
          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}")
          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")

          # In case it does not pick the XBB ones on Linux
          # config_options+=("-DCMAKE_LIBTOOL=$(which libtool)")
          # config_options+=("-DCMAKE_NM=$(which nm)")
          # config_options+=("-DCMAKE_AR=$(which ar)")
          # config_options+=("-DCMAKE_OBJCOPY=$(which objcopy)")
          # config_options+=("-DCMAKE_OBJDUMP=$(which objdump)")
          # config_options+=("-DCMAKE_RANLIB=$(which ranlib)")
          # config_options+=("-DCMAKE_STRIP=$(which strip)")
          # config_options+=("-DGIT_EXECUTABLE=$(which git)")

          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")

          config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=OFF")
          config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

          config_options+=("-DLLDB_ENABLE_LUA=OFF")
          config_options+=("-DLLDB_ENABLE_LZMA=OFF")
          config_options+=("-DLLDB_ENABLE_PYTHON=OFF")
          config_options+=("-DLLDB_USE_SYSTEM_DEBUGSERVER=ON")

          config_options+=("-DLLVM_BUILD_DOCS=OFF")
          config_options+=("-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON")

          if true
          then
            config_options+=("-DLLVM_BUILD_TESTS=OFF")
          else
            config_options+=("-DLLVM_BUILD_TESTS=ON")
          fi

          config_options+=("-DLLVM_ENABLE_BACKTRACES=OFF")
          config_options+=("-DLLVM_ENABLE_DOXYGEN=OFF")
          config_options+=("-DLLVM_ENABLE_EH=ON")
          config_options+=("-DLLVM_ENABLE_FFI=ON")
          config_options+=("-DFFI_INCLUDE_DIR=${LIBS_INSTALL_FOLDER_PATH}/include")
          # https://cmake.org/cmake/help/v3.4/command/find_library.html
          config_options+=("-DFFI_LIBRARY_DIR=${LIBS_INSTALL_FOLDER_PATH}/lib64;${LIBS_INSTALL_FOLDER_PATH}/lib")

          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("-DLLVM_ENABLE_LTO=OFF")
          else
            # Build LLVM with -flto.
            config_options+=("-DLLVM_ENABLE_LTO=ON")
          fi

          # No openmp,mlir
          # flang fails:
          # .../flang/runtime/io-stmt.h:65:17: error: 'visit<(lambda at /Users/ilg/Work/clang-11.1.0-1/darwin-x64/sources/llvm-project-11.1.0.src/flang/runtime/io-stmt.h:66:9), const std::__1::variant<std::__1::reference_wrapper<Fortran::runtime::io::OpenStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::CloseStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::NoopCloseStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::InternalFormattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalFormattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalListIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalListIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalFormattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalFormattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalListIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalListIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::UnformattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::UnformattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalMiscIoStatementState>> &>' is unavailable: introduced in macOS 10.13

          config_options+=("-DLLVM_ENABLE_RTTI=ON")
          config_options+=("-DLLVM_ENABLE_SPHINX=OFF")
          config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")
          config_options+=("-DLLVM_ENABLE_Z3_SOLVER=OFF")

          config_options+=("-DLLVM_INCLUDE_DOCS=OFF") # No docs
          config_options+=("-DLLVM_INCLUDE_TESTS=OFF") # No tests
          config_options+=("-DLLVM_INCLUDE_EXAMPLES=OFF") # No examples

          config_options+=("-DLLVM_INSTALL_UTILS=ON")
          config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
          config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
          config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")

          # config_options+=("-DPYTHON_EXECUTABLE=${INSTALL_FOLDER_PATH}/bin/python3")
          # config_options+=("-DPython3_EXECUTABLE=python3")

          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          # Better not, and use the explicit `llvm-*` names.
          # config_options+=("-DLLVM_INSTALL_BINUTILS_SYMLINKS=ON")

          # Distributions should never be built using the 
          # BUILD_SHARED_LIBS CMake option.
          # https://llvm.org/docs/BuildingADistribution.html
          config_options+=("-DBUILD_SHARED_LIBS=OFF")

          # Prefer the locally compiled libraries.
          config_options+=("-DCMAKE_LIBRARY_PATH=${LIBS_INSTALL_FOLDER_PATH}/lib")

          # Remove many of the LLVM development and testing tools as
          # well as component libraries from the default install target
          # Unfortunately the LTO test fails with missing LLVMgold.so.
          # config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")

          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then

            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly")
            # config_options+=("-DLLVM_ENABLE_RUNTIMES=compiler-rt;libcxx;libcxxabi;libunwind")

            MACOS_SDK_PATH=$(get_macos_sdk_path)
            echo "copy_macos_sdk=${MACOS_SDK_PATH}"

            local dest_sdk_folder_path="${APP_PREFIX}/macOS.sdk"

            # Copy the SDK in the distribution, to have a standalone package.
            copy_macos_sdk "${MACOS_SDK_PATH}" "${dest_sdk_folder_path}"

            config_options+=("-DDEFAULT_SYSROOT=../macOS.sdk")

            # TODO
            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            # config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")

            # Fails on macOS
            # config_options+=("-DCLANG_DEFAULT_LINKER=lld")

            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

            # The macOS 10.10 xpc/xpc.h is very old and the build fails with
            # clang-tools-extra/clangd/xpc/XPCTransport.cpp:97:5: error: ‘xpc_connection_send_message’ was not declared in this scope; did you mean ‘xpc_connection_handler_t’?

            # config_options+=("-DCLANGD_BUILD_XPC=OFF")

            config_options+=("-DMACOSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}")
            config_options+=("-DCMAKE_MACOSX_RPATH=ON")

            # config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")

          elif [ "${TARGET_PLATFORM}" == "linux" ]
          then

            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")

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

            # Set the default linker to gold, otherwise `-flto`
            # requires an expicit `-fuse-ld=gold`.
            config_options+=("-DCLANG_DEFAULT_LINKER=gold")

            # The point below is to simplify the use of the clang libraries,
            # and to prevent having references to shared libraries located
            # in non-system folders.
            # This is achieved by disabling shared libraries and
            # grouping everything under a single libc++.a library.
            # Thee is also a small patch adding references to -lpthread -ldl.
            config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")
            config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")
            config_options+=("-DLIBCXX_USE_COMPILER_RT=ON")
            # config_options+=("-DLIBCXX_STATICALLY_LINK_ABI_IN_SHARED_LIBRARY=ON")
            # config_options+=("-DLIBCXX_STATICALLY_LINK_ABI_IN_STATIC_LIBRARY=ON")

            config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF")
            config_options+=("-DLIBCXXABI_ENABLE_STATIC_UNWINDER=ON")
            config_options+=("-DLIBCXXABI_INSTALL_LIBRARY=OFF")
            config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON")
            config_options+=("-DLIBCXXABI_USE_LLVM_UNWINDER=ON")

            # config_options+=("-DLIBCXXABI_STATICALLY_LINK_UNWINDER_IN_SHARED_LIBRARY=ON")
            # config_options+=("-DLIBCXXABI_STATICALLY_LINK_UNWINDER_IN_STATIC_LIBRARY=ON")

            config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")
            config_options+=("-DLIBUNWIND_INSTALL_LIBRARY=OFF")
            config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON")

            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=OFF")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

            config_options+=("-DLLVM_BINUTILS_INCDIR=${SOURCES_FOLDER_PATH}/binutils-${BINUTILS_VERSION}/include")

            config_options+=("-DLLVM_BUILTIN_TARGETS=${BUILD}")
            config_options+=("-DLLVM_RUNTIME_TARGETS=${BUILD}")

            config_options+=("-DLLVM_TOOL_GOLD_BUILD=ON")

          elif [ "${TARGET_PLATFORM}" == "win32" ]
          then

            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")

            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")

            # config_options+=("-DLLVM_USE_LINKER=gold")

            # set(BUILTINS_CMAKE_ARGS -DCMAKE_SYSTEM_NAME=Windows CACHE STRING "")
            # set(RUNTIMES_CMAKE_ARGS -DCMAKE_SYSTEM_NAME=Windows CACHE STRING "")

            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=OFF")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

            # config_options+=("-DLLVM_BUILTIN_TARGETS=${BUILD}")
            # config_options+=("-DLLVM_RUNTIME_TARGETS=${BUILD}")

            config_options+=("-DLLVM_TOOL_GOLD_BUILD=ON")

          else
            echo "Oops! Unsupported TARGET_PLATFORM=${TARGET_PLATFORM}."
            exit 1
          fi

          echo ${config_options[@]}

          echo
          ${CC} --version

          run_verbose_timed cmake \
            ${config_options[@]} \
            "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm"

          touch "config.status"

        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/cmake-output.txt"
      fi

      (
        echo
        echo "Running llvm build..."

        if [ "${IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake --build . --verbose
          run_verbose cmake --build .  --verbose  --target install
        else
          run_verbose_timed cmake --build . 
          run_verbose cmake --build . --target install
        fi

        (
          echo
          echo "Removing useless files..."

          # Remove useless LLVM libraries and leave only the toolchain.
          cd "${APP_PREFIX}/bin"
          rm -rf bugpoint c-index-test count dsymutil FileCheck \
            llc lli lli-child-target llvm-bcanalyzer llvm-c-test \
            llvm-cat llvm-cfi-verify llvm-cvtres \
            llvm-dwarfdump llvm-dwp \
            llvm-elfabi llvm-exegesis llvm-extract llvm-gsymutil \
            llvm-ifs llvm-install-name-tool llvm-jitlink llvm-link \
            llvm-lipo llvm-lto llvm-lto2 llvm-mc llvm-mca llvm-ml \
            llvm-modextract llvm-mt llvm-opt-report llvm-pdbutil \
            llvm-profdata \
            llvm-PerfectShuffle llvm-reduce llvm-rtdyld llvm-split \
            llvm-stress llvm-tblgen llvm-undname llvm-xray \
            not obj2yaml opt sancov sanstats \
            verify-uselistorder yaml-bench yaml2obj

          cd "${APP_PREFIX}/include"
          rm -rf clang clang-c clang-tidy lld lldb llvm llvm-c polly

          cd "${APP_PREFIX}/lib"
          rm -rf libclang*.a libClangdXPCLib* libf*.a liblld*.a libLLVM*.a libPolly*.a
          rm -rf cmake/lld cmake/llvm cmake/polly

          cd "${APP_PREFIX}/share"
          rm -rf man
        )

        show_libs "${APP_PREFIX}/bin/clang"
        show_libs "${APP_PREFIX}/bin/llvm-nm"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/make-output.txt"

      copy_license \
        "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm" \
        "${llvm_folder_name}"
    )

    touch "${llvm_stamp_file_path}"

  else
    echo "Component llvm already installed."
  fi

  tests_add "test_llvm"
}

function test_llvm()
{
  echo
  echo "Testing the llvm binaries..."

  (
    show_libs "${APP_PREFIX}/bin/clang"

    echo
    echo "Testing if llvm binaries start properly..."

    run_app "${APP_PREFIX}/bin/clang" --version
    run_app "${APP_PREFIX}/bin/clang++" --version

    run_app "${APP_PREFIX}/bin/clang-tidy" --version
    run_app "${APP_PREFIX}/bin/clang-format" --version

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    # run_app "${APP_PREFIX}/bin/lld" --version || true

    run_app "${APP_PREFIX}/bin/llvm-ar" --version
    run_app "${APP_PREFIX}/bin/llvm-nm" --version
    run_app "${APP_PREFIX}/bin/llvm-objcopy" --version
    run_app "${APP_PREFIX}/bin/llvm-objdump" --version
    run_app "${APP_PREFIX}/bin/llvm-ranlib" --version
    if [ -f "${APP_PREFIX}/bin/llvm-readelf" ]
    then
      run_app "${APP_PREFIX}/bin/llvm-readelf" --version
    fi
    run_app "${APP_PREFIX}/bin/llvm-size" --version
    run_app "${APP_PREFIX}/bin/llvm-strings" --version
    run_app "${APP_PREFIX}/bin/llvm-strip" --version

    echo
    echo "Testing clang configuration..."

    run_app "${APP_PREFIX}/bin/clang" -print-target-triple
    run_app "${APP_PREFIX}/bin/clang" -print-targets
    run_app "${APP_PREFIX}/bin/clang" -print-supported-cpus
    run_app "${APP_PREFIX}/bin/clang" -print-search-dirs
    run_app "${APP_PREFIX}/bin/clang" -print-resource-dir
    run_app "${APP_PREFIX}/bin/clang" -print-libgcc-file-name

    # run_app "${APP_PREFIX}/bin/llvm-config" --help

    # Cannot run the the compiler without a loader.
    if true # [ "${TARGET_PLATFORM}" != "win32" ]
    then

      echo
      echo "Testing if clang compiles simple Hello programs..."

      local tmp="$(mktemp ~/tmp/test-clang-XXXXXXXXXX)"
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
        GC_SECTION="-Wl,--gc-sections"
      elif [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        GC_SECTION="-Wl,-dead_strip"
      else
        GC_SECTION=""
      fi

      # Ask the compiler for the libraries locations.
      CLANG_LIB_PATH="$(${APP_PREFIX}/bin/clang -print-resource-dir)/../.."

      # -----------------------------------------------------------------------

      # Note: __EOF__ is quoted to prevent substitutions here.
      cat <<'__EOF__' > hello.c
#include <stdio.h>

int
main(int argc, char* argv[])
{
  printf("Hello\n");

  return 0;
}
__EOF__

      # Test C compile and link in a single step.
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o hello-c1 hello.c ${GC_SECTION}

      test_expect "hello-c1" "Hello"

      # Static links are not supported, at least not with the Apple linker:
      # "/usr/bin/ld" -demangle -lto_library /Users/ilg/Work/clang-11.1.0-1/darwin-x64/install/clang/lib/libLTO.dylib -no_deduplicate -static -arch x86_64 -platform_version macos 10.10.0 0.0.0 -syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -o static-hello-c1 -lcrt0.o /var/folders/3h/98gc9hrn3qnfm40q7_0rxczw0000gn/T/hello-4bed56.o
      # ld: library not found for -lcrt0.o
      # run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o static-hello-c1 hello.c -static
      # test_expect "static-hello-c1" "Hello"

      # Test C compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang" -o hello-c.o -c hello.c
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o hello-c2 hello-c.o ${GC_SECTION}

      test_expect "hello-c2" "Hello"

      # Test LTO C compile and link in a single step.
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o lto-hello-c1 hello.c ${GC_SECTION}

      test_expect "lto-hello-c1" "Hello"

      # Test LTO C compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang" -flto -o lto-hello-c.o -c hello.c
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o lto-hello-c2 lto-hello-c.o ${GC_SECTION}

      test_expect "lto-hello-c2" "Hello"

if true
then
      (
        # Test C compile and link in a single step.
        run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o rt-hello-c1 hello.c -rtlib=compiler-rt ${GC_SECTION}

        test_expect "rt-hello-c1" "Hello"


        # Test C compile and link in separate steps.
        run_app "${APP_PREFIX}/bin/clang" -o hello-c.o -c hello.c
        run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o rt-hello-c2 hello-c.o -rtlib=compiler-rt ${GC_SECTION}

        test_expect "rt-hello-c2" "Hello"

        # Test LTO C compile and link in a single step.
        run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o rt-lto-hello-c1 hello.c -rtlib=compiler-rt ${GC_SECTION}

        test_expect "rt-lto-hello-c1" "Hello"

        # Test LTO C compile and link in separate steps.
        run_app "${APP_PREFIX}/bin/clang" -flto -o lto-hello-c.o -c hello.c
        run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o rt-lto-hello-c2 lto-hello-c.o -rtlib=compiler-rt ${GC_SECTION}

        test_expect "rt-lto-hello-c2" "Hello"
      )
fi

      # -----------------------------------------------------------------------

      # Note: __EOF__ is quoted to prevent substitutions here.
      cat <<'__EOF__' > hello.cpp
#include <iostream>

int
main(int argc, char* argv[])
{
  std::cout << "Hello" << std::endl;

  return 0;
}
__EOF__

      # Test C++ compile and link in a single step.
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o hello-cpp1 hello.cpp ${GC_SECTION}

      test_expect "hello-cpp1" "Hello"

      # Test C++ compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang++" -o hello-cpp.o -c hello.cpp
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o hello-cpp2 hello-cpp.o ${GC_SECTION}

      test_expect "hello-cpp2" "Hello"

      # Test LTO C++ compile and link in a single step.
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -flto -o lto-hello-cpp1 hello.cpp ${GC_SECTION}

      test_expect "lto-hello-cpp1" "Hello"


      # Test LTO C++ compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang++" -flto -o lto-hello-cpp.o -c hello.cpp
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -flto -o lto-hello-cpp2 lto-hello-cpp.o ${GC_SECTION}

      test_expect "lto-hello-cpp2" "Hello"

if true
then
      (
        # export LD_LIBRARY_PATH="${CLANG_LIB_PATH}"

        # Test C++ compile and link in a single step.
        run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o rt-hello-cpp1 hello.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

        test_expect "rt-hello-cpp1" "Hello"

        # Test C++ compile and link in separate steps.
        run_app "${APP_PREFIX}/bin/clang++" -o hello-cpp.o -c hello.cpp -stdlib=libc++
        run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o rt-hello-cpp2 hello-cpp.o -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

        test_expect "rt-hello-cpp2" "Hello"

        # Test LTO C++ compile and link in a single step.
        run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -flto -o rt-lto-hello-cpp1 hello.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

        test_expect "rt-lto-hello-cpp1" "Hello"


        # Test LTO C++ compile and link in separate steps.
        run_app "${APP_PREFIX}/bin/clang++" -flto -o lto-hello-cpp.o -c hello.cpp -stdlib=libc++
        run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -flto -o rt-lto-hello-cpp2 lto-hello-cpp.o -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

        test_expect "rt-lto-hello-cpp2" "Hello"
      )
fi

      # -----------------------------------------------------------------------

      # Note: __EOF__ is quoted to prevent substitutions here.
      cat <<'__EOF__' > except.cpp
#include <iostream>
#include <exception>

struct MyException : public std::exception {
   const char* what() const throw () {
      return "MyException";
   }
};
 
void
func(void)
{
  throw MyException();
}

int
main(int argc, char* argv[])
{
  try {
    func();
  } catch(MyException& e) {
    std::cout << e.what() << std::endl;
  } catch(std::exception& e) {
    std::cout << "Other" << std::endl;
  }  

  return 0;
}
__EOF__

      # -O0 is an attempt to prevent any interferences with the optimiser.
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o except -O0 except.cpp ${GC_SECTION}

      if [ "${TARGET_PLATFORM}" != "darwin" ]
      then
        # on Darwin: 'Symbol not found: __ZdlPvm'
        test_expect "except" "MyException"
      fi

if true
then

      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o rt-except -O0 except.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

      if [ "${TARGET_PLATFORM}" != "darwin" ]
      then
        # on Darwin: 'Symbol not found: __ZdlPvm'
        test_expect "rt-except" "MyException"
      fi

fi

      # Note: __EOF__ is quoted to prevent substitutions here.
      cat <<'__EOF__' > str-except.cpp
#include <iostream>
#include <exception>
 
void
func(void)
{
  throw "MyStringException";
}

int
main(int argc, char* argv[])
{
  try {
    func();
  } catch(const char* msg) {
    std::cout << msg << std::endl;
  } catch(std::exception& e) {
    std::cout << "Other" << std::endl;
  } 

  return 0; 
}
__EOF__

      # -O0 is an attempt to prevent any interferences with the optimiser.
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o str-except -O0 str-except.cpp ${GC_SECTION}
      
      test_expect "str-except" "MyStringException"

if true
then

      # -O0 is an attempt to prevent any interferences with the optimiser.
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o rt-str-except -O0 str-except.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}
      
      test_expect "rt-str-except" "MyStringException"

fi

      # -----------------------------------------------------------------------

      # Note: __EOF__ is quoted to prevent substitutions here.
      cat <<'__EOF__' > add.c
// __declspec(dllexport)
int
add(int a, int b)
{
  return a + b;
}
__EOF__

      run_app "${APP_PREFIX}/bin/clang" -o add.o -fpic -c add.c

      rm -rf libadd.a
      run_app "${APP_PREFIX}/bin/llvm-ar" -r ${VERBOSE_FLAG} libadd-static.a add.o
      run_app "${APP_PREFIX}/bin/llvm-ranlib" libadd-static.a

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        run_app "${APP_PREFIX}/bin/clang" -o libadd-shared.dll -shared add.o -Wl,--subsystem,windows
      else
        run_app "${APP_PREFIX}/bin/clang" -o libadd-shared.so -shared add.o
      fi

if true
then

      run_app "${APP_PREFIX}/bin/clang" -o rt-add.o -fpic -c add.c

      rm -rf libadd.a
      run_app "${APP_PREFIX}/bin/llvm-ar" -r ${VERBOSE_FLAG} librt-add-static.a rt-add.o 
      run_app "${APP_PREFIX}/bin/llvm-ranlib" librt-add-static.a

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        run_app "${APP_PREFIX}/bin/clang" -o librt-add-shared.dll -shared rt-add.o -Wl,--subsystem,windows -rtlib=compiler-rt
      else
        run_app "${APP_PREFIX}/bin/clang" -o librt-add-shared.so -shared rt-add.o -rtlib=compiler-rt
      fi

fi

      # Note: __EOF__ is quoted to prevent substitutions here.
      cat <<'__EOF__' > adder.c
#include <stdio.h>
#include <stdlib.h>

extern int
add(int a, int b);

int
main(int argc, char* argv[])
{
  int sum = atoi(argv[1]) + atoi(argv[2]);
  printf("%d\n", sum);

  return 0;
}
__EOF__

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o static-adder adder.c -ladd-static -L . ${GC_SECTION}

      test_expect "static-adder" "42" 40 2

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o shared-adder adder.c -ladd-shared -L . ${GC_SECTION}

      (
        LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
        export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
        test_expect "shared-adder" "42" 40 2
      )

if true
then

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o rt-static-adder adder.c -lrt-add-static -L . -rtlib=compiler-rt ${GC_SECTION}

      test_expect "rt-static-adder" "42" 40 2

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o rt-shared-adder adder.c -lrt-add-shared -L . -rtlib=compiler-rt ${GC_SECTION}

      (
        LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
        export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
        test_expect "rt-shared-adder" "42" 40 2
      )

fi

    fi
  )

  echo
  echo "Local llvm tests completed successfuly."
}


function strip_libs()
{
  if [ "${WITH_STRIP}" == "y" ]
  then
    (
      xbb_activate

      PATH="${APP_PREFIX}/bin:${PATH}"

      echo
      echo "Stripping libraries..."

      cd "${APP_PREFIX}"

      local libs=$(find "${APP_PREFIX}" -type f -name '*.[ao]')
      for lib in ${libs}
      do
        if is_elf "${lib}" || is_ar "${lib}"
        then
          echo "strip -S ${lib}"
          strip -S "${lib}"
        fi
      done
    )
  fi
}

# -----------------------------------------------------------------------------

function build_mingw() 
{
  # http://mingw-w64.org/doku.php/start
  # https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/

  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-headers
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-crt
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-winpthreads
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-binutils
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-gcc

  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-headers-git/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-crt-git/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-winpthreads-git/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-binutils/PKGBUILD
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-gcc/PKGBUILD
  
  # https://github.com/msys2/MSYS2-packages/blob/master/gcc/PKGBUILD

  # https://github.com/StephanTLavavej/mingw-distro

  # 2018-06-03, "5.0.4"
  # 2018-09-16, "6.0.0"
  # 2019-11-11, "7.0.0"
  # 2020-09-18, "8.0.0"
  # 2021-05-09, "8.0.2"

  MINGW_VERSION="$1"

  # Number
  MINGW_VERSION_MAJOR=$(echo ${MINGW_VERSION} | sed -e 's|\([0-9][0-9]*\)\..*|\1|')

  # The original SourceForge location.
  local mingw_src_folder_name="mingw-w64-v${MINGW_VERSION}"
  local mingw_folder_name="${mingw_src_folder_name}"

  local mingw_archive="${mingw_folder_name}.tar.bz2"
  local mingw_url="https://sourceforge.net/projects/mingw-w64/files/mingw-w64/mingw-w64-release/${mingw_archive}"
  
  # If SourceForge is down, there is also a GitHub mirror.
  # https://github.com/mirror/mingw-w64
  # mingw_folder_name="mingw-w64-${MINGW_VERSION}"
  # mingw_archive="v${MINGW_VERSION}.tar.gz"
  # mingw_url="https://github.com/mirror/mingw-w64/archive/${mingw_archive}"
 
  # https://sourceforge.net/p/mingw-w64/wiki2/Cross%20Win32%20and%20Win64%20compiler/
  # https://sourceforge.net/p/mingw-w64/mingw-w64/ci/master/tree/configure

  # ---------------------------------------------------------------------------

  # The 'headers' step creates the 'include' folder.

  local mingw_headers_folder_name="mingw-${MINGW_VERSION}-headers"

  cd "${SOURCES_FOLDER_PATH}"

  download_and_extract "${mingw_url}" "${mingw_archive}" "${mingw_src_folder_name}"

  local mingw_headers_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_headers_folder_name}-installed"
  if [ ! -f "${mingw_headers_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${mingw_headers_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_headers_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${mingw_folder_name}"

      xbb_activate

      if [ ! -f "config.status" ]
      then
        (
          echo
          echo "Running mingw-w64 headers configure..."

          bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-headers/configure" --help

          config_options=()

          config_options+=("--prefix=${APP_PREFIX}")
                        
          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-tune=generic")

          # From mingw-w64-headers
          config_options+=("--enable-sdk=all")

          # https://docs.microsoft.com/en-us/cpp/porting/modifying-winver-and-win32-winnt?view=msvc-160
          # Windows 7
          config_options+=("--with-default-win32-winnt=0x601")

          config_options+=("--enable-idl")
          config_options+=("--without-widl")

          # From Arch
          config_options+=("--enable-secure-api")

          bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-headers/configure" \
            ${config_options[@]}

          cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_folder_name}/config-headers-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_folder_name}/configure-headers-output.txt"
      fi

      (
        echo
        echo "Running mingw-w64 headers make..."

        # Build.
        make -j ${JOBS}

        make install-strip

        # mingw-w64 and Arch do this.
        # rm -fv "${APP_PREFIX}/include/pthread_signal.h"
        # rm -fv "${APP_PREFIX}/include/pthread_time.h"
        # rm -fv "${APP_PREFIX}/include/pthread_unistd.h"

        echo
        echo "${APP_PREFIX}/include"
        ls -l "${APP_PREFIX}/include" 

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_folder_name}/make-headers-output.txt"

      # No need to do it again.
      copy_license \
        "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}" \
        "${mingw_folder_name}"

    )

    touch "${mingw_headers_stamp_file_path}"

  else
    echo "Component mingw-w64 headers already installed."
  fi

  # ---------------------------------------------------------------------------

  # The 'crt' step creates the C run-time in the 'lib' folder.

  local mingw_crt_folder_name="mingw-${MINGW_VERSION}-crt"

  local mingw_crt_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_crt_folder_name}-installed"
  if [ ! -f "${mingw_crt_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${mingw_crt_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_crt_folder_name}"

      xbb_activate
      # xbb_activate_installed_bin

      # Overwrite the flags, -ffunction-sections -fdata-sections result in
      # {standard input}: Assembler messages:
      # {standard input}:693: Error: CFI instruction used without previous .cfi_startproc
      # {standard input}:695: Error: .cfi_endproc without corresponding .cfi_startproc
      # {standard input}:697: Error: .seh_endproc used in segment '.text' instead of expected '.text$WinMainCRTStartup'
      # {standard input}: Error: open CFI at the end of file; missing .cfi_endproc directive
      # {standard input}:7150: Error: can't resolve `.text' {.text section} - `.LFB5156' {.text$WinMainCRTStartup section}
      # {standard input}:8937: Error: can't resolve `.text' {.text section} - `.LFB5156' {.text$WinMainCRTStartup section}

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"
      LDFLAGS=""

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      # Without it, apparently a bug in autoconf/c.m4, function AC_PROG_CC, results in:
      # checking for _mingw_mac.h... no
      # configure: error: Please check if the mingw-w64 header set and the build/host option are set properly.
      # (https://github.com/henry0312/build_gcc/issues/1)
      # export CC=""

      env | sort

      if [ ! -f "config.status" ]
      then
        (
          echo
          echo "Running mingw-w64 crt configure..."

          bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-crt/configure" --help

          config_options=()

          config_options+=("--prefix=${APP_PREFIX}")
                        
          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          if [ "${TARGET_ARCH}" == "x64" ]
          then
            config_options+=("--disable-lib32")
            config_options+=("--enable-lib64")
          elif [ "${TARGET_ARCH}" == "x32" -o "${TARGET_ARCH}" == "ia32" ]
          then
            config_options+=("--enable-lib32")
            config_options+=("--disable-lib64")
          else
            echo "Oops! Unsupported TARGET_ARCH=${TARGET_ARCH}."
            exit 1
          fi

          config_options+=("--with-sysroot=${APP_PREFIX}")
          config_options+=("--enable-wildcard")

          config_options+=("--enable-warnings=0")

          bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-crt/configure" \
            ${config_options[@]}

          cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_folder_name}/config-crt-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_folder_name}/configure-crt-output.txt"
      fi

      (
        echo
        echo "Running mingw-w64 crt make..."

        # Build.
        make -j ${JOBS}

        make install-strip

        echo
        echo "${APP_PREFIX}/lib"
        ls -l "${APP_PREFIX}/lib" 

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_folder_name}/make-crt-output.txt"
    )

    touch "${mingw_crt_stamp_file_path}"

  else
    echo "Component mingw-w64 crt already installed."
  fi

  # ---------------------------------------------------------------------------  

  local mingw_winpthreads_folder_name="mingw-${MINGW_VERSION}-winpthreads"

  local mingw_winpthreads_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${mingw_winpthreads_folder_name}-installed"
  if [ ! -f "${mingw_winpthreads_stamp_file_path}" ]
  then

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${mingw_winpthreads_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${mingw_winpthreads_folder_name}"

      xbb_activate
      xbb_activate_installed_bin

      CPPFLAGS=""
      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"
      LDFLAGS=""

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS
      
      env | sort

      if [ ! -f "config.status" ]
      then
        (
          echo
          echo "Running mingw-w64 winpthreads configure..."

          bash "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/winpthreads/configure" --help

          config_options=()

          config_options+=("--prefix=${APP_PREFIX}")
                        
          config_options+=("--build=${BUILD}")
          config_options+=("--host=${HOST}")
          config_options+=("--target=${TARGET}")

          config_options+=("--with-sysroot=${APP_PREFIX}")

          config_options+=("--enable-static")
          # Avoid a reference to 'DLL Name: libwinpthread-1.dll'
          config_options+=("--disable-shared")

          bash ${DEBUG} "${SOURCES_FOLDER_PATH}/${mingw_src_folder_name}/mingw-w64-libraries/winpthreads/configure" \
            ${config_options[@]}

         cp "config.log" "${LOGS_FOLDER_PATH}/${mingw_folder_name}/config-winpthreads-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_folder_name}/configure-winpthreads-output.txt"
      fi
      
      (
        echo
        echo "Running mingw-w64 winpthreads make..."

        # Build.
        make -j ${JOBS}

        make install-strip

        echo
        echo "${APP_PREFIX}/lib"
        ls -l "${APP_PREFIX}/lib"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${mingw_folder_name}/make-winpthreads-output.txt"
    )

    touch "${mingw_winpthreads_stamp_file_path}"

  else
    echo "Component mingw-w64 winpthreads already installed."
  fi
}

# -----------------------------------------------------------------------------
