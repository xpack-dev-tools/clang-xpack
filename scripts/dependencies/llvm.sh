# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

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
# 12 Jan 2023, "15.0.7"

# -----------------------------------------------------------------------------

# Environment variables:
# XBB_LLVM_PATCH_FILE_NAME

function llvm_build()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  export ACTUAL_LLVM_VERSION="$1"
  shift

  local llvm_version_major=$(xbb_get_version_major "${ACTUAL_LLVM_VERSION}")
  local llvm_version_minor=$(xbb_get_version_minor "${ACTUAL_LLVM_VERSION}")

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

    if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then
      # Disable the use of libxar.
      # It picks an unwanted system library, and compiling
      # it is too tedious.
      run_verbose sed -i.bak \
        -e 's|^check_library_exists(xar xar_open |# check_library_exists(xar xar_open |' \
        "${llvm_src_folder_name}/llvm/cmake/config-ix.cmake"
    fi

    # if [ "${XBB_HOST_PLATFORM}" == "linux" ]
    # then
    #   # Add -lpthread -ldl
    #   run_verbose sed -i.bak \
    #     -e 's|if (ToolChain.ShouldLinkCXXStdlib(Args)) {$|if (ToolChain.ShouldLinkCXXStdlib(Args)) { CmdArgs.push_back("-lpthread"); CmdArgs.push_back("-ldl");|' \
    #     "${llvm_src_folder_name}/clang/lib/Driver/ToolChains/Gnu.cpp"
    # fi

    # (
    #   cd "${llvm_src_folder_name}/llvm/tools"

    #   # This trick will allow to build the toolchain only and still get clang
    #   for p in clang lld lldb
    #   do
    #     if [ ! -e $p ]
    #     then
    #         ln -s ../../$p .
    #     fi
    #   done
    # )

    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"

      # Use install/libs/lib & include
      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # Non-static will have trouble to find the llvm bootstrap libc++.
      # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      LDFLAGS="${XBB_LDFLAGS_APP}"

      if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
      then
        # missing libclang_rt.profile_osx.a
        CFLAGS="$(xbb_strip_macosx_version_min "${CFLAGS}")"
        CXXFLAGS="$(xbb_strip_macosx_version_min "${CXXFLAGS}")"
        LDFLAGS="$(xbb_strip_macosx_version_min "${LDFLAGS}")"

        # TODO: check if still needed.
        LDFLAGS+=" -Wl,-search_paths_first"

        # For libc++.1.0.dylib to find libc++abi.1.dylib
        run_verbose mkdir -pv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib"
        XBB_LIBRARY_PATH="${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib:${XBB_LIBRARY_PATH}"
      elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
      then
        # For libc++abi to find libnunwind.so
        LDFLAGS+=" -L${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/lib"
        XBB_LIBRARY_PATH="${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/lib:${XBB_LIBRARY_PATH}"
      fi

      CMAKE=$(which cmake)

      xbb_adjust_ldflags_rpath

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

          if [ "${XBB_IS_DEVELOP}" == "y" ]
          then
            config_options+=("-LAH") # display help for each variable
          fi
          config_options+=("-G" "Ninja")
          # HomeBrew uses make files, but so far this does not seem necessary.
          # config_options+=("-G" "Unix Makefiles")

          # https://llvm.org/docs/GettingStarted.html
          # https://llvm.org/docs/CMake.html

          # flang fails:
          # .../flang/runtime/io-stmt.h:65:17: error: 'visit<(lambda at /Users/ilg/Work/clang-11.1.0-1/darwin-x64/sources/llvm-project-11.1.0.src/flang/runtime/io-stmt.h:66:9), const ..., std::__1::reference_wrapper<Fortran::runtime::io::ExternalMiscIoStatementState>> &>' is unavailable: introduced in macOS 10.13

          # Colon separated list of directories clang will search for headers.
          # It cannot be used instead of the patch, since it applies to C,
          # not C++.
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

          # Explicit,otherwise cmake picks the wrong ones.
          config_options+=("-DCMAKE_ADDR2LINE=${ADDR2LINE}")
          config_options+=("-DCMAKE_AR=${AR}")
          if [ ! -z "${DLLTOOL:-}" ]
          then
            config_options+=("-DCMAKE_DLLTOOL=${DLLTOOL}")
          fi
          config_options+=("-DCMAKE_NM=${NM}")
          if [ ! -z "${OBJCOPY:-}" ]
          then
            config_options+=("-DCMAKE_OBJCOPY=${OBJCOPY}")
          fi
          if [ ! -z "${OBJDUMP:-}" ]
          then
            config_options+=("-DCMAKE_OBJDUMP=${OBJDUMP}")
          fi
          config_options+=("-DCMAKE_RANLIB=${RANLIB}")
          if [ ! -z "${READELF:-}" ]
          then
            config_options+=("-DCMAKE_READELF=${READELF}")
          fi
          config_options+=("-DCMAKE_STRIP=${STRIP}")

          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")
          config_options+=("-DCMAKE_SHARED_LINKER_FLAGS=${LDFLAGS}")

          config_options+=("-DCMAKE_LINKER=ld") # HB

          # Please note the trailing space.
          config_options+=("-DCLANG_VENDOR=${XBB_LLVM_BRANDING} ")
          # config_options+=("-DFLANG_VENDOR=${XBB_LLVM_BRANDING} ")
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

          config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=OFF")

          config_options+=("-DCUDA_64_BIT_DEVICE_CODE=OFF")

          config_options+=("-DCURSES_INCLUDE_PATH=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include/ncurses")

          config_options+=("-DFFI_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")
          config_options+=("-DFFI_LIB_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib")

          config_options+=("-DLLDB_ENABLE_LUA=OFF") # HB
          config_options+=("-DLLDB_ENABLE_PYTHON=OFF") # HB uses ON
          config_options+=("-DLLDB_INCLUDE_TESTS=OFF")
          # config_options+=("-DLLDB_USE_SYSTEM_SIX=ON") # HB (?)

          config_options+=("-DLLVM_BUILD_DOCS=OFF")
          config_options+=("-DLLVM_BUILD_TESTS=OFF") # Arch uses ON
          config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF") # MS
          # config_options+=("-DLLVM_ENABLE_BACKTRACES=OFF")
          config_options+=("-DLLVM_ENABLE_DOXYGEN=OFF")

          config_options+=("-DLLVM_ENABLE_EH=ON") # HB

          # See platform specific
          # config_options+=("-DLLVM_ENABLE_LTO=OFF")

          config_options+=("-DLLVM_ENABLE_RTTI=ON") # HB, Arch

          config_options+=("-DLLVM_ENABLE_SPHINX=OFF") # Arch uses ON
          config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")
          config_options+=("-DLLVM_ENABLE_Z3_SOLVER=OFF") # HB uses ON

          config_options+=("-DLLVM_INCLUDE_DOCS=OFF") # No docs, HB
          config_options+=("-DLLVM_INCLUDE_TESTS=OFF") # No tests, HB
          config_options+=("-DLLVM_INCLUDE_EXAMPLES=OFF") # No examples

          # Keep the explicit `llvm-*` names.
          config_options+=("-DLLVM_INSTALL_BINUTILS_SYMLINKS=OFF")

          config_options+=("-DZLIB_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")

          # Links use huge amounts of memory.
          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
          then

            # HB/Arch do not define it, but windows does.
            if true
            then
              config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")

              # The available choices are libgcc, compiler-rt.
              config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")

              config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind")
            fi

            config_options+=("-DCLANG_FORCE_MATCHING_LIBCLANG_SOVERSION=OFF") # HB

            # To help find the locally compiled `ld.gold`.
            # https://cmake.org/cmake/help/v3.4/variable/CMAKE_PROGRAM_PATH.html
            # https://cmake.org/cmake/help/v3.4/command/find_program.html
            config_options+=("-DCMAKE_PROGRAM_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin")

            # config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

            config_options+=("-DCOMPILER_RT_ENABLE_IOS=OFF") # HB
            config_options+=("-DCOMPILER_RT_ENABLE_MACCATALYST=OFF")
            config_options+=("-DCOMPILER_RT_ENABLE_TVOS=OFF") # HB
            config_options+=("-DCOMPILER_RT_ENABLE_WATCHOS=OFF") # HB

            # This distribution expects the SDK to be in this location.
            config_options+=("-DDEFAULT_SYSROOT=/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk") # HB

            config_options+=("-DLLDB_ENABLE_LZMA=ON") # HB
            config_options+=("-DLLDB_USE_SYSTEM_DEBUGSERVER=ON") # HB (Darwin only)

            config_options+=("-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON") # HB
            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=ON") # HB (Darwin only)
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            # Fails with: LLVM_BUILTIN_TARGETS isn't implemented for Darwin platform!
            # config_options+=("-DLLVM_BUILTIN_TARGETS=${XBB_TARGET_TRIPLET}")
            config_options+=("-DLLVM_CREATE_XCODE_TOOLCHAIN=OFF") # HB

            config_options+=("-DLLVM_ENABLE_FFI=ON") # HB
            config_options+=("-DLLVM_ENABLE_LIBCXX=ON") # HB

            # This measn to use -flto during the build;
            # this fails with system libtool.
            config_options+=("-DLLVM_ENABLE_LTO=OFF") # HB uses Thin

            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra;polly;compiler-rt")
            config_options+=("-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx")

            config_options+=("-DLLVM_HOST_TRIPLE=${XBB_TARGET_TRIPLET}")
            config_options+=("-DLLVM_INSTALL_UTILS=ON") # HB
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON") # HB
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON") # HB
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON") # HB
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

            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size")

            # Prevent CMake from defaulting to `lld` when it's found next to `clang`.
            # This can be removed after CMake 3.25. See:
            # https://gitlab.kitware.com/cmake/cmake/-/merge_requests/7671
            config_options+=("-DLLVM_USE_LINKER=ld") # HB

            config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}")

            # macOS 10.13 libtool does not support recent format:
            # /Library/Developer/CommandLineTools/usr/bin/libtool: object: lib/builtins/CMakeFiles/clang_rt.builtins_i386_osx.dir/absvdi2.c.o malformed object (LC_BUILD_VERSION and some LC_VERSION_MIN load command also found)

            llvm_libtool_darwin_file_path="$(which llvm-libtool-darwin || echo llvm-libtool-darwin)"
            config_options+=("-DCMAKE_LIBTOOL=${llvm_libtool_darwin_file_path}")

          elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
          then

            if [ "${XBB_HOST_ARCH}" == "x64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${XBB_HOST_ARCH}" == "ia32" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            elif [ "${XBB_HOST_ARCH}" == "arm64" ]
            then
              # config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64;ARM")
              config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
            elif [ "${XBB_HOST_ARCH}" == "arm" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=ARM")
            else
              echo "Unsupported XBB_HOST_ARCH=${XBB_HOST_ARCH} in ${FUNCNAME[0]}()"
              exit 1
            fi

            # Arch/HB do not define them, but windows does.
            # meson requires the default compiler to work properly
            # with the defaults (libstdc++ & libgcc).
            if false
            then
              config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")

              # ld.gold has a problem with --gc-sections and fails
              # several tests on Ubuntu 18
              # https://sourceware.org/bugzilla/show_bug.cgi?id=23880
              # Better keep the system GNU linker (ld), and use lld only
              # when requested with -fuse-ld=lld.
              # config_options+=("-DCLANG_DEFAULT_LINKER=gold")

              config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")
              config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind")
            fi

            # To help find the just locally compiled `ld.gold`.
            # https://cmake.org/cmake/help/v3.4/variable/CMAKE_PROGRAM_PATH.html
            # https://cmake.org/cmake/help/v3.4/command/find_program.html
            config_options+=("-DCMAKE_PROGRAM_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin")

            # config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=OFF")

            config_options+=("-DLLDB_ENABLE_LZMA=ON")

            config_options+=("-DLLVM_BINUTILS_INCDIR=${XBB_SOURCES_FOLDER_PATH}/binutils-${XBB_BINUTILS_VERSION}/include")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON") # Arch

            config_options+=("-DLLVM_ENABLE_FFI=ON") # Arch

            config_options+=("-DLLVM_INSTALL_UTILS=ON") # HB
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON") # HB
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON") # HB

            # Starting with 15, the runtimes must be specified separately.
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra;polly;compiler-rt")
            config_options+=("-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx")

            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON") # Arch

            if [ "${XBB_HOST_ARCH}" == "x64" ]
            then
              # Do not use this for ARM targets, since the resulting triples
              # are not valid.
              config_options+=("-DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON")
              # Warning: i386-pc-linux-gnu;x86_64-pc-linux-gnu DO NOT work!
              config_options+=("-DLLVM_RUNTIME_TARGETS=i386-unknown-linux-gnu;x86_64-unknown-linux-gnu")
            elif [ "${XBB_HOST_ARCH}" == "arm64" ]
            then
              # config_options+=("-DLLVM_RUNTIME_TARGETS=armv7l-unknown-linux-gnueabihf;aarch64-unknown-linux-gnu")
              config_options+=("-DLLVM_RUNTIME_TARGETS=aarch64-unknown-linux-gnu")
            elif [ "${XBB_HOST_ARCH}" == "arm" ]
            then
              # https://github.com/llvm/llvm-project/issues/60115#issuecomment-1398288811
              config_options+=("-DLLVM_RUNTIME_TARGETS=armv7l-unknown-linux-gnueabihf")

              # https://github.com/llvm/llvm-project/issues/60115#issuecomment-1398640255
              # config_options+=("-DRUNTIMES_armv7l-unknown-linux-gnueabihf_COMPILER_RT_DEFAULT_TARGET_ONLY=ON")

              # https://github.com/llvm/llvm-project/issues/60115#issuecomment-1397024105
              # config_options+=("-DRUNTIMES_COMPILER_RT_BUILD_GWP_ASAN=OFF")
              # config_options+=("-DRUNTIMES_armv7l-unknown-linux-gnueabihf_COMPILER_RT_BUILD_GWP_ASAN=OFF")
            else
              echo "Unsupported XBB_HOST_ARCH=${XBB_HOST_ARCH} in ${FUNCNAME[0]}() "
              exit 1
            fi

            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size")

          elif [ "${XBB_HOST_PLATFORM}" == "win32" ]
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
            if [ -f "${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/clang-pseudo-gen" ]
            then
              config_options+=("-DCLANG_PSEUDO_GEN=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/clang-pseudo-gen") # MS
            fi
            if [ -f "${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/clang-tidy-confusable-chars-gen" ]
            then
              config_options+=("-DCLANG_TIDY_CONFUSABLE_CHARS_GEN=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/clang-tidy-confusable-chars-gen") # MS
            fi

            config_options+=("-DLLD_DEFAULT_LD_LLD_IS_MINGW=ON") # MS

            config_options+=("-DLLVM_CONFIG_PATH=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/llvm-config") # MS

            config_options+=("-DLLDB_ENABLE_LZMA=OFF")

            config_options+=("-DLLVM_HOST_TRIPLE=${XBB_TARGET_TRIPLET}") # MS

            # Mind the links in llvm to clang, lld, lldb.
            config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON") # MS

            # TODO
            config_options+=("-DLLVM_ENABLE_FFI=ON")

            # mlir fails on windows, it tries to build the NATIVE folder and fails.
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra;polly")
            # Keep the definitions separte for each platform, they are different.
            # On Windows, the runtimes are built in separate steps, together
            # with the mingw runtime. Do not enable them here, cmake will fail.
            # config_options+=("-DLLVM_ENABLE_RUNTIMES=compiler-rt;libcxx;libcxxabi;libunwind")

            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")

            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86") # MS (ARM;AArch64;X86)

            # config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf") # MS
            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size") # MS

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

          run_verbose "${CMAKE}" \
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
          run_verbose_timed "${CMAKE}" \
            --build . \
            --verbose \
            --parallel ${XBB_JOBS}

          run_verbose "${CMAKE}" \
            --build . \
            --verbose \
            --target install/strip
        else
          run_verbose "${CMAKE}" \
            --build .

          run_verbose "${CMAKE}" \
            --build . \
            --target install/strip
        fi

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          if [ ! -f "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/darwin/libclang_rt.profile_osx.a" ]
          then
            echo
            echo "Missing libclang_rt.profile_osx.a"
            exit 1
          fi
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
              lli-child-target llvm-bcanalyzer llvm-c-test \
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
            run_verbose rm -rfv libclang*.a libClangdXPCLib* libf*.a liblld*.a libLLVM*.a

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

        show_host_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/clang${XBB_HOST_DOT_EXE}"
        show_host_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/llvm-nm${XBB_HOST_DOT_EXE}"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}/build-output-$(ndate).txt"

      copy_license \
        "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm" \
        "${llvm_folder_name}"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_stamp_file_path}"

  else
    echo "Component llvm already installed"
  fi

  tests_add "llvm_test" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
}

function llvm_test()
{
  local test_bin_path="$1"
  shift

  local name_suffix=""
  local name_prefix=""

  echo
  echo "Testing the ${name_prefix}llvm binaries..."

  (
    run_verbose ls -l "${test_bin_path}"

    CC="${test_bin_path}/clang"
    CXX="${test_bin_path}/clang++"
    DLLTOOL="${test_bin_path}/llvm-dlltool"
    WIDL="${test_bin_path}/widl"
    GENDEF="${test_bin_path}/gendef"
    AR="${test_bin_path}/llvm-ar"
    RANLIB="${test_bin_path}/llvm-ranlib"

    if [ "${XBB_BUILD_PLATFORM}" != "win32" ]
    then
      show_host_libs "${test_bin_path}/clang"
      show_host_libs "${test_bin_path}/lld"
      if [ -f "${test_bin_path}/lldb" -o \
          -f "${test_bin_path}/lldb${XBB_HOST_DOT_EXE}" ]
      then
        # lldb not available on Ubuntu 16 Arm.
        show_host_libs "${test_bin_path}/lldb"
      fi
    fi

    echo
    echo "Testing if the ${name_prefix}llvm binaries start properly..."

    run_host_app_verbose "${CC}" --version
    run_host_app_verbose "${CXX}" --version

    if [ -f "${test_bin_path}/clang-format${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${test_bin_path}/clang-format" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    # run_host_app_verbose "${test_bin_path}/lld" --version || true
    if [ "${XBB_HOST_PLATFORM}" == "linux" ]
    then
      run_host_app_verbose "${test_bin_path}/ld.lld" --version || true
    elif [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then
      run_host_app_verbose "${test_bin_path}/ld64.lld" --version || true
    elif [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then
      # run_host_app_verbose "${test_bin_path}/ld-link" --version || true
      run_host_app_verbose "${test_bin_path}/ld.lld" --version || true
    fi

    run_host_app_verbose "${test_bin_path}/llvm-ar" --version
    run_host_app_verbose "${test_bin_path}/llvm-nm" --version
    run_host_app_verbose "${test_bin_path}/llvm-objcopy" --version
    run_host_app_verbose "${test_bin_path}/llvm-objdump" --version
    run_host_app_verbose "${test_bin_path}/llvm-ranlib" --version
    if [ -f "${test_bin_path}/llvm-readelf${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${test_bin_path}/llvm-readelf" --version
    fi
    if [ -f "${test_bin_path}/llvm-size" ]
    then
      run_host_app_verbose "${test_bin_path}/llvm-size" --version
    fi
    run_host_app_verbose "${test_bin_path}/llvm-strings" --version
    run_host_app_verbose "${test_bin_path}/llvm-strip" --version

    echo
    echo "Testing the ${name_prefix}clang configuration..."

    # Show the selected GCC & multilib.
    # There must be a g++ with that version installed,
    # otherwise the tests will not find the C++ headers and/or libraries.
    run_host_app_verbose "${test_bin_path}/clang" -v

    run_host_app_verbose "${test_bin_path}/clang" -print-target-triple
    run_host_app_verbose "${test_bin_path}/clang" -print-targets
    run_host_app_verbose "${test_bin_path}/clang" -print-supported-cpus
    run_host_app_verbose "${test_bin_path}/clang" -print-search-dirs
    run_host_app_verbose "${test_bin_path}/clang" -print-resource-dir
    run_host_app_verbose "${test_bin_path}/clang" -print-libgcc-file-name

    # run_app_verbose "${test_bin_path}/llvm-config" --help

    echo
    echo "Testing if ${name_prefix}clang compiles simple programs..."

    rm -rf "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"
    mkdir -pv "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"
    cd "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"

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

    xbb_show_env_develop

    run_verbose uname
    if [ "${XBB_BUILD_PLATFORM}" != "darwin" ]
    then
      run_verbose uname -o
    fi

    # -------------------------------------------------------------------------

    if [ "${XBB_HOST_PLATFORM}" == "win32" ]
    then

      # Defaults:
      # config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++") # MS
      # config_options+=("-DCLANG_DEFAULT_LINKER=lld") # MS
      # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt") # MS
      # config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind") # MS

      # LTO weak C++ tests fail with 15.0.7-1.
      # ld.lld: error: duplicate symbol: world()
      # >>> defined at hello-weak-cpp.cpp
      # >>>            lto-hello-weak-cpp-32.cpp.o
      # >>> defined at hello-f-weak-cpp.cpp
      # >>>            lto-hello-f-weak-cpp-32.cpp.o
      # clang-15: error: linker command failed with exit code 1 (use -v to see invocation)
      export XBB_SKIP_TEST_LTO_HELLO_WEAK_CPP_32="y"
      export XBB_SKIP_TEST_GC_LTO_HELLO_WEAK_CPP_32="y"

      export XBB_SKIP_TEST_STATIC_LIB_LTO_HELLO_WEAK_CPP_32="y"
      export XBB_SKIP_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK_CPP_32="y"

      export XBB_SKIP_TEST_STATIC_LTO_HELLO_WEAK_CPP_32="y"
      export XBB_SKIP_TEST_STATIC_GC_LTO_HELLO_WEAK_CPP_32="y"

      export XBB_SKIP_TEST_LTO_HELLO_WEAK_CPP_64="y"
      export XBB_SKIP_TEST_GC_LTO_HELLO_WEAK_CPP_64="y"

      export XBB_SKIP_TEST_STATIC_LIB_LTO_HELLO_WEAK_CPP_64="y"
      export XBB_SKIP_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK_CPP_64="y"

      export XBB_SKIP_TEST_STATIC_LTO_HELLO_WEAK_CPP_64="y"
      export XBB_SKIP_TEST_STATIC_GC_LTO_HELLO_WEAK_CPP_64="y"

      for bits in 32 64
      do
        # For libc++.dll & co.
        # The DLLs are available in the /lib folder.
        if [ "${XBB_BUILD_PLATFORM}" == "win32" ]
        then
          cxx_lib_path=$(dirname $(${CXX} -m${bits} -print-file-name=libc++.dll | sed -e 's|:||' | sed -e 's|^|/|'))
          export PATH="${cxx_lib_path}:${PATH:-}"
          echo "PATH=${PATH}"
        else
          cxx_lib_path=$(dirname $(wine64 ${CXX}.exe -m${bits} -print-file-name=libc++.dll | sed -e 's|[a-zA-Z]:||'))
          export WINEPATH="${cxx_lib_path};${WINEPATH:-}"
          echo "WINEPATH=${WINEPATH}"
        fi

        compiler-tests-single "${test_bin_path}" --${bits}
        compiler-tests-single "${test_bin_path}" --${bits} --gc
        compiler-tests-single "${test_bin_path}" --${bits} --lto
        compiler-tests-single "${test_bin_path}" --${bits} --gc --lto

        compiler-tests-single "${test_bin_path}" --${bits} --static-lib
        compiler-tests-single "${test_bin_path}" --${bits} --static-lib --gc
        compiler-tests-single "${test_bin_path}" --${bits} --static-lib --lto
        compiler-tests-single "${test_bin_path}" --${bits} --static-lib --gc --lto

        compiler-tests-single "${test_bin_path}" --${bits} --static
        compiler-tests-single "${test_bin_path}" --${bits} --static --gc
        compiler-tests-single "${test_bin_path}" --${bits} --static --lto
        compiler-tests-single "${test_bin_path}" --${bits} --static --gc --lto
      done

    elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
    then

      # Defaults:
      # config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libstdc++")
      # config_options+=("-DCLANG_DEFAULT_RTLIB=libgcc")

      # It is mandatory that the compiler runs properly without any
      # explicit libraries or other options, otherwise tools used
      # during configuration (like meson) will fail probing for
      # capabilities.
      compiler-tests-single "${test_bin_path}"

      # aarch64 multilib not yet available
      # if [ "${XBB_HOST_BITS}" == "64" ]
      if [ "${XBB_HOST_ARCH}" == "x64" ]
      then
        (
          # x64 & aarch64, both with multilib.

          export LD_LIBRARY_PATH="$(xbb_get_libs_path -m64)"
          echo
          echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

          # LTO global-terminate test fails on 15.0.7-1.
          # Segmentation fault (core dumped)
          # Program received signal SIGSEGV, Segmentation fault.
          # __strlen_avx2 () at ../sysdeps/x86_64/multiarch/strlen-avx2.S:65
          export XBB_SKIP_RUN_TEST_LTO_GLOBAL_TERMINATE_64="y"
          export XBB_SKIP_RUN_TEST_GC_LTO_GLOBAL_TERMINATE_64="y"

          compiler-tests-single "${test_bin_path}" --64
          compiler-tests-single "${test_bin_path}" --64 --gc
          compiler-tests-single "${test_bin_path}" --64 --lto --lld
          compiler-tests-single "${test_bin_path}" --64 --gc --lto --lld
        )

        local skip_32_tests=""
        if is_variable_set "XBB_SKIP_32_BIT_TESTS"
        then
          skip_32_tests="${XBB_SKIP_32_BIT_TESTS}"
        else
          local libstdcpp_file_path="$(${CXX} -m32 -print-file-name=libstdc++.so)"
          if [ "${libstdcpp_file_path}" == "libstdc++.so" ]
          then
            # If the compiler does not find the full path of the
            # 32-bit c++ library, multilib support is not installed; skip.
            skip_32_tests="y"
          fi
        fi

        if [ "${skip_32_tests}" == "y" ]
        then
          echo
          echo "Skipping clang -m32 tests..."
        else
          (
            export LD_LIBRARY_PATH="$(xbb_get_libs_path -m32)"
            echo
            echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

            compiler-tests-single "${test_bin_path}" --32
            compiler-tests-single "${test_bin_path}" --32 --gc
            compiler-tests-single "${test_bin_path}" --32 --lto --lld
            compiler-tests-single "${test_bin_path}" --32 --gc --lto --lld
          )
        fi
      else
        (
          # arm & aarch64.

          export LD_LIBRARY_PATH="$(xbb_get_libs_path)"
          echo
          echo "LD_LIBRARY_PATH=${LD_LIBRARY_PATH}"

          # The Linux system linker may fail with -flto, use the included lld.
          # For example, on Raspberry Pi OS 32-bit:
          # error: unable to execute command: Segmentation fault (core dumped)

          compiler-tests-single "${test_bin_path}"
          compiler-tests-single "${test_bin_path}" --gc
          compiler-tests-single "${test_bin_path}" --lto --lld
          compiler-tests-single "${test_bin_path}" --gc --lto --lld
        )
      fi

    elif [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then

      # It is mandatory that the compiler runs properly without any
      # explicit libraries or other options, otherwise tools used
      # during configuration (like meson) will fail probing for
      # capabilities.
      compiler-tests-single "${test_bin_path}"

      # Defaults: (different from HB)
      # config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
      # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")
      # config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind")

      # `-fuse-ld=lld` fails on macOS:
      # ld64.lld: warning: ignoring unknown argument: -no_deduplicate
      # ld64.lld: warning: -sdk_version is required when emitting min version load command.  Setting sdk version to match provided min version
      # For now use the system linker /usr/bin/ld.

      # -static-libstdc++ not available on macOS:
      # clang-11: warning: argument unused during compilation: '-static-libstdc++'

      if [ "${XBB_TARGET_ARCH}" == "x64" ]
      then
        # -flto fails at run on Intel.
        # Does not identify the custom exceptions:
        # [./lto-throwcatch-main ]
        # not throwing
        # throwing FirstException
        # caught std::exception <--
        # caught unexpected exception 3!
        # throwing SecondException
        # caught std::exception <--
        # caught unexpected exception 3!
        # throwing std::exception
        # caught std::exception
        # got errors

        # Expected behaviour:
        # [./throwcatch-main ]
        # not throwing
        # throwing FirstException
        # caught FirstException
        # throwing SecondException
        # caught SecondException
        # throwing std::exception
        # caught std::exception
        # all ok <--

        export XBB_SKIP_RUN_TEST_LTO_THROWCATCH_MAIN="y"
        export XBB_SKIP_RUN_TEST_GC_LTO_THROWCATCH_MAIN="y"
        export XBB_SKIP_RUN_TEST_LTO_CRT_THROWCATCH_MAIN="y"
        export XBB_SKIP_RUN_TEST_GC_LTO_CRT_THROWCATCH_MAIN="y"
      fi

      # Done before.
      # compiler-tests-single "${test_bin_path}"
      compiler-tests-single "${test_bin_path}" --gc
      compiler-tests-single "${test_bin_path}" --lto
      compiler-tests-single "${test_bin_path}" --gc --lto

      # Redundant, the current default is compiler-rt anyway.
      if false
      then
        compiler-tests-single "${test_bin_path}" --crt
        compiler-tests-single "${test_bin_path}" --gc --crt
        compiler-tests-single "${test_bin_path}" --lto --crt
        compiler-tests-single "${test_bin_path}" --gc --lto --crt
      fi

    fi

    # -------------------------------------------------------------------------

    (
      cd c-cpp

      if true
      then

        # Note: __EOF__ is NOT quoted to allow substitutions here.
        cat <<__EOF__ > "compile_commands.json"
[
  {
    "directory": "$(pwd)",
    "command": "${CXX} -c hello-cpp.cpp",
    "file": "hello-cpp.cpp"
  }
]
__EOF__

cat "compile_commands.json"

        run_host_app_verbose "${test_bin_path}/clangd" --check="hello-cpp.cpp"

        # Note: __EOF__ is quoted to prevent substitutions here.
        cat <<'__EOF__' > "unchecked-exception.cpp"
// repro for clangd crash from github.com/clangd/clangd issue #1072
#include <exception>
int main() {
    std::exception_ptr foo;
    try {} catch (...) { }
    return 0;
}
__EOF__

        # Note: __EOF__ is NOT quoted to allow substitutions here.
        cat <<__EOF__ > "compile_commands.json"
[
  {
    "directory": "$(pwd)",
    "command": "${CXX} -c unchecked-exception.cpp",
    "file": "unchecked-exception.cpp"
  }
]
__EOF__

cat "compile_commands.json"

        run_host_app_verbose "${test_bin_path}/clangd" --check="unchecked-exception.cpp"
      fi
    )

  )
}

# -----------------------------------------------------------------------------

function strip_libs()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

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
