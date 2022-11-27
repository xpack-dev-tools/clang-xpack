# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

# XBB_LLVM_PATCH_FILE_NAME

function build_llvm()
{
  # https://llvm.org
  # https://llvm.org/docs/GettingStarted.html
  # https://llvm.org/docs/CommandGuide/
  # https://github.com/llvm/llvm-project/
  # https://github.com/llvm/llvm-project/releases/
  # https://github.com/llvm/llvm-project/releases/tag/llvmorg-11.1.0/
  # https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/llvm-project-11.1.0.src.tar.xz

  # https://github.com/archlinux/svntogit-packages/blob/packages/llvm/trunk/PKGBUILD
  # https://archlinuxarm.org/packages/aarch64/llvm/files/PKGBUILD

  # https://github.com/Homebrew/homebrew-core/blob/master/Formula/llvm.rb

  # https://llvm.org/docs/GoldPlugin.html#lto-how-to-build
  # https://llvm.org/docs/BuildingADistribution.html

  # 17 Feb 2021, "11.1.0"
  # For GCC 11 it requires a patch to add <limits> to `benchmark_register.h`.
  # Fixed in 12.x.
  # 14 Apr 2021, "12.0.0"
  # 9 Jul 2021, "12.0.1"
  # 1 Oct 2021, "13.0.0"
  # 2 Feb 2022, "13.0.1"
  # 25 Jun 2022, "14.0.6"

  export ACTUAL_LLVM_VERSION="$1"
  shift

  local llvm_version_major=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')
  local llvm_version_minor=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')

  export llvm_src_folder_name="llvm-project-${ACTUAL_LLVM_VERSION}.src"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${ACTUAL_LLVM_VERSION}/${llvm_archive}"

  local llvm_folder_name="llvm-${ACTUAL_LLVM_VERSION}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}"

  local llvm_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_folder_name}-installed"
  if [ ! -f "${llvm_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
    cd "${XBB_SOURCES_FOLDER_PATH}"

    download_and_extract "${llvm_url}" "${llvm_archive}" \
      "${llvm_src_folder_name}" "${XBB_LLVM_PATCH_FILE_NAME}"

    # Disable the use of libxar.
    run_verbose sed -i.bak \
      -e 's|^check_library_exists(xar xar_open |# check_library_exists(xar xar_open |' \
      "${llvm_src_folder_name}/llvm/cmake/config-ix.cmake"

    if [ "${XBB_HOST_PLATFORM}" == "linux" ]
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
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"

      if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
      then

        # Use XBB libs in native-llvm
        # xbb_activate_dev

        # Required to satisfy the reference to /opt/xbb/lib/libncurses.so.
        # xbb_activate_libs

        xbb_activate_dependencies_dev

        # CPPFLAGS="${XBB_CPPFLAGS} -I${XBB_FOLDER_PATH}/include/ncurses"
        CPPFLAGS="${XBB_CPPFLAGS}"
        CFLAGS="${XBB_CFLAGS_NO_W}"
        CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

        # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
        LDFLAGS="${XBB_LDFLAGS_APP}"

      else

        # Use install/libs/lib & include
        xbb_activate_dependencies_dev

        CPPFLAGS="${XBB_CPPFLAGS}"
        CFLAGS="${XBB_CFLAGS_NO_W}"
        CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

        # Non-static will have trouble to find the llvm bootstrap libc++.
        # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
        LDFLAGS="${XBB_LDFLAGS_APP}"
        xbb_adjust_ldflags_rpath

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          LDFLAGS+=" -Wl,-search_paths_first"

          # clang: error: unsupported option '-static-libgcc'
          # LDFLAGS=$(echo ${LDFLAGS} | sed -e 's|-static-libgcc||')
        elif [ "${XBB_HOST_PLATFORM}" == "win32" ]
        then
          : # export CC="${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang"
          : # export CXX="${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang++"
        fi

      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "cmake.done" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running llvm cmake..."

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

          config_options+=("-DCMAKE_BUILD_TYPE=Release") # MS
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}") # MS

          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}") # MS
          config_options+=("-DCMAKE_C_COMPILER=${CC}") # MS

          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")

          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          if false # [ "${is_bootstrap}" == "y" ] # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
          then

            # Please note the trailing space.
            config_options+=("-DCLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
            config_options+=("-DFLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
            config_options+=("-DLLD_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
            config_options+=("-DPACKAGE_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")

            config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF")
            config_options+=("-DLLDB_INCLUDE_TESTS=OFF")

          else

            # Please note the trailing space.
            config_options+=("-DCLANG_VENDOR=${XBB_LLVM_BRANDING} ")
            config_options+=("-DFLANG_VENDOR=${XBB_LLVM_BRANDING} ")
            config_options+=("-DLLD_VENDOR=${XBB_LLVM_BRANDING} ")
            config_options+=("-DPACKAGE_VENDOR=${XBB_LLVM_BRANDING} ")

            config_options+=("-DCLANG_EXECUTABLE_VERSION=${llvm_version_major}")

            # Prefer the locally compiled libraries.
            config_options+=("-DCMAKE_INCLUDE_PATH=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")
            if [ -d "${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib64" ]
            then
              config_options+=("-DCMAKE_LIBRARY_PATH=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib64;${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib")
            else
              config_options+=("-DCMAKE_LIBRARY_PATH=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib")
            fi

            config_options+=("-DCURSES_INCLUDE_PATH=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include/ncurses")

            config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=OFF")

            config_options+=("-DCUDA_64_BIT_DEVICE_CODE=OFF")

            config_options+=("-DLLDB_ENABLE_LUA=OFF")
            config_options+=("-DLLDB_ENABLE_PYTHON=OFF")
            config_options+=("-DLLDB_INCLUDE_TESTS=OFF")
            config_options+=("-DLLDB_USE_SYSTEM_DEBUGSERVER=ON")

            config_options+=("-DLLVM_BUILD_DOCS=OFF")
            config_options+=("-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON")
            config_options+=("-DLLVM_BUILD_TESTS=OFF")
            config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF") # MS
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

          if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
          then

            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
            # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")

            # To help find the locally compiled `ld.gold`.
            # https://cmake.org/cmake/help/v3.4/variable/CMAKE_PROGRAM_PATH.html
            # https://cmake.org/cmake/help/v3.4/command/find_program.html
            config_options+=("-DCMAKE_PROGRAM_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin")

            config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

            # This distribution expects the SDK to be in this location.
            config_options+=("-DDEFAULT_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk")

            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=OFF")
            # Fails with: LLVM_BUILTIN_TARGETS isn't implemented for Darwin platform!
            # config_options+=("-DLLVM_BUILTIN_TARGETS=${XBB_TARGET_TRIPLET}")

            # The libc++ & Co are not included because the system dynamic
            # libraries are prefered by the linker anyway, and attempts to
            # force the inclusion of the static library failed:
            # ld: warning: linker symbol '$ld$hide$os10.4$__Unwind_Backtrace' hides a non-existent symbol '__Unwind_Backtrace'

            # config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt")

            config_options+=("-DLLVM_ENABLE_FFI=ON")
            config_options+=("-DLLVM_HOST_TRIPLE=${XBB_TARGET_TRIPLET}")
            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")
            # Fails with: Please use architecture with 4 or 8 byte pointers.
            # config_options+=("-DLLVM_RUNTIME_TARGETS=${XBB_TARGET_TRIPLET}")

            if [ "${XBB_HOST_ARCH}" == "x64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${XBB_HOST_ARCH}" == "arm64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
            else
              echo "Unsupported XBB_HOST_ARCH=${XBB_HOST_ARCH} in ${FUNCNAME[0]}()"
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

            # Otherwise it'll generate two -mmacosx-version-min
            config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
            config_options+=("-DMACOSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")

          elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
          then

            # LLVMgold.so
            # https://llvm.org/docs/GoldPlugin.html#how-to-build-it
            # /Host/home/ilg/Work/clang-11.1.0-1/linux-ia32/install/clang/bin/ld.gold: error: /Host/home/ilg/Work/clang-11.1.0-1/linux-ia32/install/clang/bin/../lib/LLVMgold.so: could not load plugin library: /Host/home/ilg/Work/clang-11.1.0-1/linux-ia32/install/clang/bin/../lib/LLVMgold.so: cannot open shared object file: No such file or directory
            # Then either gold was not configured with plugins enabled, or clang
            # was not built with `-DLLVM_BINUTILS_INCDIR` set properly.

            if [ "${XBB_HOST_ARCH}" == "x64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${XBB_HOST_ARCH}" == "ia32" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${XBB_HOST_ARCH}" == "arm64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
            elif [ "${XBB_HOST_ARCH}" == "arm" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=ARM")
            else
              echo "Unsupported XBB_HOST_ARCH=${XBB_HOST_ARCH} in ${FUNCNAME[0]}()"
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
            config_options+=("-DCMAKE_PROGRAM_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin")

            config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

            config_options+=("-DLLVM_BINUTILS_INCDIR=${XBB_SOURCES_FOLDER_PATH}/binutils-${XBB_BINUTILS_VERSION}/include")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=OFF")
            config_options+=("-DLLVM_BUILTIN_TARGETS=${XBB_TARGET_TRIPLET}")

            # Disabled once XBB moved to Ubuntu 18.
            if false # [ "${XBB_HOST_ARCH}" == "arm64" -o "${XBB_HOST_ARCH}" == "arm" ]
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
            config_options+=("-DLLVM_HOST_TRIPLE=${XBB_TARGET_TRIPLET}")
            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")
            config_options+=("-DLLVM_RUNTIME_TARGETS=${XBB_TARGET_TRIPLET}")
            config_options+=("-DLLVM_TOOL_GOLD_BUILD=ON")

            # For now keep the default configuration, which creates both
            # shred and static libs, but they are not directly
            # usable, since they require complex LD_LIBRARY_PATH and
            # explicit link options; the crt tests were disabled.
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

          elif [ "${XBB_HOST_PLATFORM}" == "win32" ]
          then

            # Mind the links in llvm to clang, lld, lldb.
            config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON") # MS
            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86") # MS (ARM;AArch64;X86)
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra")
            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf ") # MS

            if true # [ "${is_bootstrap}" != "y" ]
            then
              config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++") # MS
              config_options+=("-DCLANG_DEFAULT_LINKER=lld") # MS
              config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt") # MS
              config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind") # MS

              # config_options+=("-DCMAKE_CROSSCOMPILING=ON")

              config_options+=("-DCMAKE_RC_COMPILER=${RC}") # MS

              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY") # MS
              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY") # MS
              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER") # MS
              config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY") # MS

              config_options+=("-DCMAKE_SYSTEM_NAME=Windows") # MS

              config_options+=("-DCMAKE_FIND_ROOT_PATH=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}") # MS

              config_options+=("-DCLANG_TABLEGEN=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/clang-tblgen") # MS
              config_options+=("-DLLDB_TABLEGEN=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/lldb-tblgen") # MS
              config_options+=("-DLLVM_TABLEGEN=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/llvm-tblgen") # MS

              # -DCLANG_PSEUDO_GEN=/build/llvm-project/llvm/build/bin/clang-pseudo-gen # MS
              # -DCLANG_TIDY_CONFUSABLE_CHARS_GEN=/build/llvm-project/llvm/build/bin/clang-tidy-confusable-chars-gen # MS

              config_options+=("-DLLVM_CONFIG_PATH=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/llvm-config") # MS

              config_options+=("-DLLVM_HOST_TRIPLE=${XBB_TARGET_TRIPLET}") # MS
            fi

            # https://llvm.org/docs/BuildingADistribution.html#options-for-reducing-size
            # This option is not available on Windows
            # config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

            # libclang_rt.builtins-x86_64.a ...
            # ld.lld: error: too many exported symbols (max 65535)
            # config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON") # MS

            # compiler-rt, libunwind, libc++ and libc++-abi are built
            # in separate steps intertwined with mingw.

          else
            echo "Unsupported XBB_HOST_PLATFORM=${XBB_HOST_PLATFORM} in ${FUNCNAME[0]}()"
            exit 1
          fi

          echo
          which ${CC} && ${CC} --version && echo || true

          run_verbose cmake \
            "${config_options[@]}" \
            "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm"

          touch "cmake.done"

        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}/cmake-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running llvm build..."

        if [ "${XBB_IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake --build . --verbose
          run_verbose cmake --build .  --verbose  --target install/strip
        else
          run_verbose_timed cmake --build .
          run_verbose cmake --build . --target install/strip
        fi

        (
          if true # [ "${is_bootstrap}" != "y" ]
          then
            echo
            echo "Removing less used files..."

            # Remove less used LLVM libraries and leave only the toolchain.
            cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
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
              rm -rfv $f $f${XBB_HOST_DOT_EXE}
            done

            # So far not used.
            rm -rfv libclang.dll
            rm -rfv ld64.lld.exe ld64.lld.darwinnew.exe lld-link.exe wasm-ld.exe

            cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/include"
            run_verbose rm -rf clang clang-c clang-tidy lld lldb llvm llvm-c polly

            cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib"
            run_verbose rm -rfv libclang*.a libClangdXPCLib* libf*.a liblld*.a libLLVM*.a libPolly*.a
            # rm -rf cmake/lld cmake/llvm cmake/polly
          fi
          cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/share"
          run_verbose rm -rf man
        )

        if [ "${XBB_HOST_PLATFORM}" == "win32" ]
        then
          echo
          echo "Add wrappers instead of links..."

          cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

          # dlltool-wrapper windres-wrapper llvm-wrapper
          for exec in clang-target-wrapper
          do
            run_verbose ${CC} "${XBB_BUILD_GIT_PATH}/wrappers/${exec}.c" -o "${exec}.exe" -O2 -Wl,-s -municode -DCLANG=\"clang-${llvm_version_major}\" -DDEFAULT_TARGET=\"${XBB_TARGET_TRIPLET}\"
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

        if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          show_native_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/clang"
          show_native_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/llvm-nm"
        else
          local realpath=$(which grealpath || which realpath || echo realpath)

          show_host_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/clang${XBB_HOST_DOT_EXE}"
          show_host_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/llvm-nm${XBB_HOST_DOT_EXE}"
        fi

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}/build-output-$(ndate).txt"

      copy_license \
        "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm" \
        "${llvm_folder_name}"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_stamp_file_path}"

  else
    echo "Component llvm already installed."
  fi

  tests_add "test_llvm" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
}

function test_llvm()
{
  local test_bin_path="$1"
  shift

  local name_suffix=""

  local triplet="" # "x86_64-w64-mingw32"
  local name_prefix=""

  while [ $# -gt 0 ]
  do
    case "$1" in
      --triplet=* )
        triplet=$(xbb_parse_option "$1")
        name_prefix="${triplet}-"
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
    shift
  done

  echo
  echo "Testing the ${name_prefix}llvm binaries..."

  (

    run_verbose ls -l "${test_bin_path}"

    if false # [ "${is_bootstrap}" == "y" ]
    then
      # Help the loader find the .dll files if the native is not static.
      export WINEPATH=${test_bin_path}/${triplet}/bin

      CC="${test_bin_path}/${triplet}-clang"
      CXX="${test_bin_path}/${triplet}-clang++"
      DLLTOOL="${test_bin_path}/${triplet}-dlltool"
      WIDL="${test_bin_path}/${triplet}-widl"
      GENDEF="${test_bin_path}/gendef"
      AR="${test_bin_path}/${triplet}-ar"
      RANLIB="${test_bin_path}/${triplet}-ranlib"
    else
      CC="${test_bin_path}/clang"
      CXX="${test_bin_path}/clang++"
      DLLTOOL="${test_bin_path}/llvm-dlltool"
      WIDL="${test_bin_path}/widl"
      GENDEF="${test_bin_path}/gendef"
      AR="${test_bin_path}/llvm-ar"
      RANLIB="${test_bin_path}/llvm-ranlib"
    fi

    show_host_libs "${test_bin_path}/clang"
    show_host_libs "${test_bin_path}/lld"
    if [ -f "${test_bin_path}/lldb${XBB_HOST_DOT_EXE}" ]
    then
      # lldb not available on Ubuntu 16 Arm.
      show_host_libs "${test_bin_path}/lldb"
    fi

    echo
    echo "Testing if the llvm binaries start properly..."

    run_app_verbose "${CC}" --version
    run_app_verbose "${CXX}" --version

    if [ -f "${test_bin_path}/clang-format${XBB_HOST_DOT_EXE}" ]
    then
      run_app_verbose "${test_bin_path}/clang-format" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    # run_app_verbose "${test_bin_path}/lld" --version || true
    if [ "${XBB_HOST_PLATFORM}" == "linux" ]
    then
      run_app_verbose "${test_bin_path}/ld.lld" --version || true
    elif [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then
      run_app_verbose "${test_bin_path}/ld64.lld" --version || true
    elif [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose "${test_bin_path}/ld-link" --version || true
    fi

    run_app_verbose "${test_bin_path}/llvm-ar" --version
    run_app_verbose "${test_bin_path}/llvm-nm" --version
    run_app_verbose "${test_bin_path}/llvm-objcopy" --version
    run_app_verbose "${test_bin_path}/llvm-objdump" --version
    run_app_verbose "${test_bin_path}/llvm-ranlib" --version
    if [ -f "${test_bin_path}/llvm-readelf" ]
    then
      run_app_verbose "${test_bin_path}/llvm-readelf" --version
    fi
    if [ -f "${test_bin_path}/llvm-size" ]
    then
      run_app_verbose "${test_bin_path}/llvm-size" --version
    fi
    run_app_verbose "${test_bin_path}/llvm-strings" --version
    run_app_verbose "${test_bin_path}/llvm-strip" --version

    echo
    echo "Testing clang configuration..."

    run_app_verbose "${test_bin_path}/clang" -print-target-triple
    run_app_verbose "${test_bin_path}/clang" -print-targets
    run_app_verbose "${test_bin_path}/clang" -print-supported-cpus
    run_app_verbose "${test_bin_path}/clang" -print-search-dirs
    run_app_verbose "${test_bin_path}/clang" -print-resource-dir
    run_app_verbose "${test_bin_path}/clang" -print-libgcc-file-name

    # run_app_verbose "${test_bin_path}/llvm-config" --help

    echo
    echo "Testing if clang compiles simple Hello programs..."

    rm -rf "${XBB_TESTS_FOLDER_PATH}/clang${name_suffix}"
    mkdir -pv "${XBB_TESTS_FOLDER_PATH}/clang${name_suffix}"
    cd "${XBB_TESTS_FOLDER_PATH}/clang${name_suffix}"

    echo
    echo "pwd: $(pwd)"

    # -------------------------------------------------------------------------

    run_verbose cp -rv "${helper_folder_path}/tests/c-cpp" .
    chmod -R a+w c-cpp
    run_verbose cp -rv "${helper_folder_path}/tests/wine"/* c-cpp
    chmod -R a+w c-cpp

    # run_verbose cp -rv "${helper_folder_path}/tests/fortran" .
    # chmod -R a+w fortran

    # -------------------------------------------------------------------------

    local VERBOSE_FLAG=""
    if [ "${XBB_IS_DEVELOP}" == "y" ]
    then
      VERBOSE_FLAG="-v"
    fi

    if [ "${XBB_TARGET_PLATFORM}" == "linux" ]
    then
      LD_GC_SECTIONS="-Wl,--gc-sections"
    elif [ "${XBB_TARGET_PLATFORM}" == "darwin" ]
    then
      LD_GC_SECTIONS="-Wl,-dead_strip"
    else
      LD_GC_SECTIONS=""
    fi

    xbb_show_env_develop

    run_verbose uname
    if [ "${XBB_BUILD_PLATFORM}" != "darwin" ]
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

    (
      if [ "${XBB_HOST_PLATFORM}" == "linux" ]
      then
        # Instruct the linker to add a RPATH pointing to the folder with the
        # compiler shared libraries. Alternatelly -Wl,-rpath=xxx can be used
        # explicitly on each link command.
        export LD_RUN_PATH="$(dirname $(realpath $(${CC} --print-file-name=libgcc_s.so)))"
        echo
        echo "LD_RUN_PATH=${LD_RUN_PATH}"
      elif [ "${XBB_HOST_PLATFORM}" == "win32" ] # -a ! "${name_suffix}" == "${XBB_BOOTSTRAP_SUFFIX}" ]
      then
        # For libwinpthread-1.dll, possibly other.
        if [ "$(uname -o)" == "Msys" ]
        then
          export PATH="${test_bin_path}/../lib;${PATH:-}"
          echo "PATH=${PATH}"
        elif [ "$(uname)" == "Linux" ]
        then
          export WINEPATH="${test_bin_path}/../lib;${WINEPATH:-}"
          echo "WINEPATH=${WINEPATH}"
        fi
      fi

      test_clang_one "${name_suffix}"
      test_clang_one "${name_suffix}" --gc
      test_clang_one "${name_suffix}" --lto
      test_clang_one "${name_suffix}" --gc --lto

      # C++ with compiler-rt fails on Intel and Arm 32 Linux.
      if [ "${XBB_HOST_PLATFORM}" == "linux" ] # -a "${XBB_HOST_ARCH}" == "arm" ]
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

    if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
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
      if [ "${XBB_HOST_PLATFORM}" == "linux" ]
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

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then

      test_clang_one "${name_suffix}" --static
      test_clang_one "${name_suffix}" --static --gc
      test_clang_one "${name_suffix}" --static --lto
      test_clang_one "${name_suffix}" --static --gc --lto
      test_clang_one "${name_suffix}" --static --crt
      test_clang_one "${name_suffix}" --static --gc --crt
      test_clang_one "${name_suffix}" --static --lto --crt
      test_clang_one "${name_suffix}" --static --gc --lto --crt

    elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
    then

      # On Linux static linking is highly discouraged.
      # On RedHat and derived, the static libraries must be installed explicitly.

      echo
      echo "Skip all --static on Linux."

    elif [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then

      # On macOS static linking is not available at all.
      echo
      echo "Skip all --static on macOS."

    fi

    # -------------------------------------------------------------------------

    (
      cd c-cpp

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose "${CC}" -o add.o -c add.c -ffunction-sections -fdata-sections
    else
      run_app_verbose "${CC}" -o add.o -fpic -c add.c -ffunction-sections -fdata-sections
    fi

    rm -rf libadd-static.a
    run_app_verbose "${AR}" -r ${VERBOSE_FLAG} libadd-static.a add.o
    run_app_verbose "${RANLIB}" libadd-static.a

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      # The `--out-implib` creates an import library, which can be
      # directly used with -l.
      run_app_verbose "${CC}" ${VERBOSE_FLAG} -shared -o libadd-shared.dll -Wl,--out-implib,libadd-shared.dll.a add.o -Wl,--subsystem,windows
    else
      run_app_verbose "${CC}" -o libadd-shared.${XBB_HOST_SHLIB_EXT} -shared add.o
    fi

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose "${CC}" -o rt-add.o -c add.c -ffunction-sections -fdata-sections
    else
      run_app_verbose "${CC}" -o rt-add.o -fpic -c add.c -ffunction-sections -fdata-sections
    fi

    rm -rf libadd-add-static.a
    run_app_verbose "${AR}" -r ${VERBOSE_FLAG} librt-add-static.a rt-add.o
    run_app_verbose "${RANLIB}" librt-add-static.a

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose "${CC}" -shared -o librt-add-shared.dll -Wl,--out-implib,librt-add-shared.dll.a rt-add.o -rtlib=compiler-rt
    else
      run_app_verbose "${CC}" -o librt-add-shared.${XBB_HOST_SHLIB_EXT} -shared rt-add.o -rtlib=compiler-rt
    fi

    run_app_verbose "${CC}" ${VERBOSE_FLAG} -o static-adder${XBB_HOST_DOT_EXE} adder.c -ladd-static -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}

    test_expect "42" "static-adder" 40 2

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      # -ladd-shared is in fact libadd-shared.dll.a
      # The library does not show as DLL, it is loaded dynamically.
      run_app_verbose "${CC}" ${VERBOSE_FLAG} -o shared-adder${XBB_HOST_DOT_EXE} adder.c -ladd-shared -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    else
      run_app_verbose "${CC}" ${VERBOSE_FLAG} -o shared-adder adder.c -ladd-shared -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    fi

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
      test_expect "42" "shared-adder" 40 2
    )

    run_app_verbose "${CC}" ${VERBOSE_FLAG} -o rt-static-adder${XBB_HOST_DOT_EXE} adder.c -lrt-add-static -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}

    test_expect "42" "rt-static-adder" 40 2

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      # -lrt-add-shared is in fact librt-add-shared.dll.a
      # The library does not show as DLL, it is loaded dynamically.
      run_app_verbose "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder${XBB_HOST_DOT_EXE} adder.c -lrt-add-shared -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    else
      run_app_verbose "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder adder.c -lrt-add-shared -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
    fi

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
      test_expect "42" "rt-shared-adder" 40 2
    )

    # -------------------------------------------------------------------------
    # Tests borrowed from the llvm-mingw project.

    # run_app_verbose "${CC}" hello.c -o hello${XBB_HOST_DOT_EXE} ${VERBOSE_FLAG} -lm
    # show_target_libs hello
    # run_app_verbose ./hello

    # run_app_verbose "${CC}" setjmp-patched.c -o setjmp${XBB_HOST_DOT_EXE} ${VERBOSE_FLAG} -lm
    # show_target_libs setjmp
    # run_app_verbose ./setjmp

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose "${CC}" hello-tls.c -o hello-tls.exe ${VERBOSE_FLAG}
      show_target_libs hello-tls
      run_app_verbose ./hello-tls

      run_app_verbose "${CC}" crt-test.c -o crt-test.exe ${VERBOSE_FLAG}
      show_target_libs crt-test
      run_app_verbose ./crt-test

      run_app_verbose "${CC}" autoimport-lib.c -shared -o autoimport-lib.dll -Wl,--out-implib,libautoimport-lib.dll.a ${VERBOSE_FLAG}
      show_target_libs autoimport-lib.dll

      run_app_verbose "${CC}" autoimport-main.c -o autoimport-main.exe -L. -lautoimport-lib ${VERBOSE_FLAG}
      show_target_libs autoimport-main
      run_app_verbose ./autoimport-main

      # The IDL output isn't arch specific, but test each arch frontend
      run_app_verbose "${WIDL}" idltest.idl -h -o idltest.h
      run_app_verbose "${CC}" idltest.c -I. -o idltest.exe -lole32 ${VERBOSE_FLAG}
      show_target_libs idltest
      run_app_verbose ./idltest
    fi

    # for test in hello-cpp hello-exception exception-locale exception-reduced global-terminate longjmp-cleanup
    # do
    #   run_app_verbose ${CXX} $test.cpp -o $test${XBB_HOST_DOT_EXE} ${VERBOSE_FLAG}
    #   show_target_libs $test
    #   run_app_verbose ./$test
    # done

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose ${CXX} hello-exception.cpp -static -o hello-exception-static${XBB_HOST_DOT_EXE} ${VERBOSE_FLAG}

      show_target_libs hello-exception-static
      run_app_verbose ./hello-exception-static

      run_app_verbose ${CXX} tlstest-lib.cpp -shared -o tlstest-lib.dll -Wl,--out-implib,libtlstest-lib.dll.a ${VERBOSE_FLAG}
      show_target_libs tlstest-lib.dll

      run_app_verbose ${CXX} tlstest-main.cpp -o tlstest-main.exe ${VERBOSE_FLAG}
      show_target_libs tlstest-main
      run_app_verbose ./tlstest-main
    fi

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose ${CXX} throwcatch-lib.cpp -shared -o throwcatch-lib.dll -Wl,--out-implib,libthrowcatch-lib.dll.a ${VERBOSE_FLAG}
    elif [ "$(lsb_release -rs)" == "12.04" -a \( "$(uname -m)" == "x86_64" -o "$(uname -m)" == "i686" \) ]
    then
      run_app_verbose ${CXX} throwcatch-lib.cpp -shared -fpic -o libthrowcatch-lib.${XBB_HOST_SHLIB_EXT} ${VERBOSE_FLAG} -fuse-ld=lld
    else
      run_app_verbose ${CXX} throwcatch-lib.cpp -shared -fpic -o libthrowcatch-lib.${XBB_HOST_SHLIB_EXT} ${VERBOSE_FLAG}
    fi

    run_app_verbose ${CXX} throwcatch-main.cpp -o throwcatch-main${XBB_HOST_DOT_EXE} -L. -lthrowcatch-lib ${VERBOSE_FLAG}

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}

      show_target_libs throwcatch-main
      run_app_verbose ./throwcatch-main
    )
    # -------------------------------------------------------------------------

    # On Windows there is no clangd.exe. (Why?)
    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      run_app_verbose ${test_bin_path}/clangd --check=hello-cpp.cpp
      cat <<'__EOF__' > ${tmp}/unchecked-exception.cpp
// repro for clangd crash from github.com/clangd/clangd issue #1072
#include <exception>
int main() {
    std::exception_ptr foo;
    try {} catch (...) { }
    return 0;
}
__EOF__
      run_app_verbose ${test_bin_path}/clangd --check=${tmp}/unchecked-exception.cpp
    fi
    )
  )

  echo
  echo "Testing the llvm${name_suffix} binaries completed successfuly."
}

# ("" | "-bootstrap") [--lto] [--gc] [--crt] [--static|--static-lib]
function test_clang_one()
{
  echo_develop
  echo_develop "[test_clang_one $@]"

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
        echo "Unsupported action/option $1 in ${FUNCNAME[0]}()"
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
      if [ "${XBB_HOST_PLATFORM}" == "linux" ]
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
      if [ "${XBB_HOST_PLATFORM}" == "linux" ]
      then
        LDFLAGS+=" -Wl,--gc-sections"
        LDXXFLAGS+=" -Wl,--gc-sections"
      elif [ "${XBB_HOST_PLATFORM}" == "darwin" ]
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

    if [ "${XBB_IS_DEVELOP}" == "y" ]
    then
      CFLAGS+=" -v"
      CXXFLAGS+=" -v"
      LDFLAGS+=" -v"
      LDXXFLAGS+=" -v"
    fi

    (
      cd c-cpp

    # Test C compile and link in a single step.
    run_app_verbose "${CC}" simple-hello.c -o ${prefix}simple-hello-c-one${suffix}${XBB_HOST_DOT_EXE} ${LDFLAGS}
    test_expect "Hello" "${prefix}simple-hello-c-one${suffix}"

    # Test C compile and link in separate steps.
    run_app_verbose "${CC}" -c simple-hello.c -o simple-hello.c.o ${CFLAGS}
    run_app_verbose "${CC}" simple-hello.c.o -o ${prefix}simple-hello-c-two${suffix}${XBB_HOST_DOT_EXE} ${LDFLAGS}
    test_expect "Hello" "${prefix}simple-hello-c-two${suffix}"

    # -------------------------------------------------------------------------

    # Test C++ compile and link in a single step.
    run_app_verbose "${CXX}" simple-hello.cpp -o ${prefix}simple-hello-cpp-one${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
    test_expect "Hello" "${prefix}simple-hello-cpp-one${suffix}"

    # Test C++ compile and link in separate steps.
    run_app_verbose "${CXX}" -c simple-hello.cpp -o ${prefix}simple-hello${suffix}.cpp.o ${CXXFLAGS}
    run_app_verbose "${CXX}" ${prefix}simple-hello${suffix}.cpp.o -o ${prefix}simple-hello-cpp-two${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
    test_expect "Hello" "${prefix}simple-hello-cpp-two${suffix}"

    # -------------------------------------------------------------------------

    if [ \( "${XBB_HOST_PLATFORM}" == "linux"  -a "${is_crt}" == "y" \) ]
    then

      # On Linux it works only with the full LLVM runtime and lld

      run_app_verbose "${CXX}" simple-exception.cpp -o ${prefix}simple-exception${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld -v
      test_expect "MyException" "${prefix}simple-exception${suffix}"

      run_app_verbose "${CXX}" simple-str-exception.cpp -o ${prefix}simple-str-exception${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
      test_expect "MyStringException" "${prefix}simple-str-exception${suffix}"

      run_app_verbose "${CXX}" simple-int-exception.cpp -o ${prefix}simple-int-exception${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
      test_expect "42" "${prefix}simple-int-exception${suffix}"

    else

      run_app_verbose "${CXX}" simple-exception.cpp -o ${prefix}simple-exception${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
      test_expect "MyException" "${prefix}simple-exception${suffix}"

      run_app_verbose "${CXX}" simple-str-exception.cpp -o ${prefix}simple-str-exception${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
      test_expect "MyStringException" "${prefix}simple-str-exception${suffix}"

      run_app_verbose "${CXX}" simple-int-exception.cpp -o ${prefix}simple-int-exception${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
      test_expect "42" "${prefix}simple-int-exception${suffix}"

    fi

    # -------------------------------------------------------------------------
    # Tests borrowed from the llvm-mingw project.

    run_app_verbose "${CC}" hello.c -o ${prefix}hello${suffix}${XBB_HOST_DOT_EXE} ${LDFLAGS} -lm
    show_target_libs ${prefix}hello${suffix}
    run_app_verbose ./${prefix}hello${suffix}

    run_app_verbose "${CC}" setjmp-patched.c -o ${prefix}setjmp${suffix}${XBB_HOST_DOT_EXE} ${LDFLAGS} -lm
    show_target_libs ${prefix}setjmp${suffix}
    run_app_verbose ./${prefix}setjmp${suffix}

    for test in hello-cpp global-terminate
    do
      run_app_verbose ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
      show_target_libs ${prefix}${test}${suffix}
      run_app_verbose ./${prefix}${test}${suffix}
    done

    if [ \( "${XBB_HOST_PLATFORM}" == "linux"  -a "${is_crt}" == "y" \) ]
    then

      # /usr/bin/ld: /tmp/longjmp-cleanup-e3da32.o: undefined reference to symbol '_Unwind_Resume@@GCC_3.0'
      run_app_verbose ${CXX} longjmp-cleanup.cpp -o ${prefix}longjmp-cleanup${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
      show_target_libs ${prefix}longjmp-cleanup${suffix}
      run_app_verbose ./${prefix}longjmp-cleanup${suffix}

      for test in hello-exception exception-locale exception-reduced
      do
        run_app_verbose ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
        show_target_libs ${prefix}${test}${suffix}
        run_app_verbose ./${prefix}${test}${suffix}
      done

    else

      run_app_verbose ${CXX} longjmp-cleanup.cpp -o ${prefix}longjmp-cleanup${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
      show_target_libs ${prefix}longjmp-cleanup${suffix}
      run_app_verbose ./${prefix}longjmp-cleanup${suffix}

      for test in hello-exception exception-locale exception-reduced
      do
        run_app_verbose ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${XBB_HOST_DOT_EXE} ${LDXXFLAGS}
        show_target_libs ${prefix}${test}${suffix}
        run_app_verbose ./${prefix}${test}${suffix}
      done

    fi

    run_app_verbose "${CC}" -c -o ${prefix}hello-weak${suffix}.c.o hello-weak.c ${CFLAGS}
    run_app_verbose "${CC}" -c -o ${prefix}hello-f-weak${suffix}.c.o hello-f-weak.c ${CFLAGS}
    run_app_verbose "${CC}" -o ${prefix}hello-weak${suffix}${XBB_HOST_DOT_EXE} ${prefix}hello-weak${suffix}.c.o ${prefix}hello-f-weak${suffix}.c.o ${VERBOSE_FLAG} -lm ${LDFLAGS}
    test_expect "Hello World!" ./${prefix}hello-weak${suffix}

    if [ \( "${XBB_HOST_PLATFORM}" == "win32"  -a "${is_lto}" == "y" \) ]
    then
      # lld-link: error: duplicate symbol: world()
      # >>> defined at hello-weak-cpp.cpp
      # >>>            lto-hello-weak-cpp.cpp.o
      # >>> defined at hello-f-weak-cpp.cpp
      # >>>            lto-hello-f-weak-cpp.cpp.o
      # clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
      echo "Skip hello-weak-cpp with -flto on Windows."
    else
      run_app_verbose "${CXX}" -c -o ${prefix}hello-weak-cpp${suffix}.cpp.o hello-weak-cpp.cpp ${CXXFLAGS}
      run_app_verbose "${CXX}" -c -o ${prefix}hello-f-weak-cpp${suffix}.cpp.o hello-f-weak-cpp.cpp ${CXXFLAGS}
      run_app_verbose "${CXX}" -o ${prefix}hello-weak-cpp${suffix}${XBB_HOST_DOT_EXE} ${prefix}hello-weak-cpp${suffix}.cpp.o ${prefix}hello-f-weak-cpp${suffix}.cpp.o ${VERBOSE_FLAG} -lm ${LDXXFLAGS}
      test_expect "Hello World!" ./${prefix}hello-weak-cpp${suffix}
    fi

    # Test weak override.
    (
      cd weak-override

      run_app_verbose "${CC}" -c main-weak.c -o ${prefix}main-weak${suffix}.c.o ${CFLAGS}
      run_app_verbose "${CC}" -c add2.c -o ${prefix}add2${suffix}.c.o ${CFLAGS}
      run_app_verbose "${CC}" -c dummy.c -o ${prefix}dummy${suffix}.c.o ${CFLAGS}
      run_app_verbose "${CC}" -c expected3.c -o ${prefix}expected3${suffix}.c.o ${CFLAGS}

      run_app_verbose "${CC}" ${prefix}main-weak${suffix}.c.o ${prefix}add2${suffix}.c.o ${prefix}dummy${suffix}.c.o ${prefix}expected3${suffix}.c.o -o ${prefix}weak-override${suffix}${XBB_HOST_DOT_EXE} ${LDFLAGS}

      run_app_verbose ./${prefix}weak-override${suffix}
    )
    )

    # -------------------------------------------------------------------------
  )
}

# -----------------------------------------------------------------------------

function strip_libs()
{
  if [ "${XBB_WITH_STRIP}" == "y" ]
  then
    (
      echo
      echo "Stripping libraries..."

      cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}"

      if [ "${XBB_HOST_PLATFORM}" == "linux" ]
      then
        local libs=$(find "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}" -type f \( -name \*.a -o -name \*.o -o -name \*.so \))
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
