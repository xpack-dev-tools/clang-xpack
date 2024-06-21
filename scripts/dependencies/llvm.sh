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

# https://gitlab.archlinux.org/archlinux/packaging/packages/clang/-/blob/main/PKGBUILD?ref_type=heads
# https://archlinuxarm.org/packages/aarch64/llvm/files/PKGBUILD

# https://github.com/Homebrew/homebrew-core/blob/master/Formula/l/llvm.rb
# https://github.com/Homebrew/homebrew-core/commits/master/Formula/llvm.rb

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

function llvm_download()
{
  local llvm_version="$1"

  # local llvm_src_folder_name_default="llvm-project-${llvm_version}.src"
  local llvm_src_folder_name_default="llvm-project-llvmorg-${llvm_version}"

  export llvm_src_folder_name="${XBB_LLVM_SRC_FOLDER_NAME:-${llvm_src_folder_name_default}}"

  # local llvm_archive="${llvm_src_folder_name}.tar.xz"
  # local llvm_url_default="https://github.com/llvm/llvm-project/releases/download/llvmorg-${XBB_ACTUAL_LLVM_VERSION}/${llvm_archive}"

  local llvm_archive="llvmorg-${llvm_version}.tar.gz"
  # https://github.com/llvm/llvm-project/archive/refs/tags/llvmorg-18.1.6.tar.gz
  local llvm_url_default="https://github.com/llvm/llvm-project/archive/refs/tags/${llvm_archive}"
  local llvm_url="${XBB_LLVM_URL:-${llvm_url_default}}"

  mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
  cd "${XBB_SOURCES_FOLDER_PATH}"

  download_and_extract "${llvm_url}" "${llvm_archive}" \
    "${llvm_src_folder_name}" "${XBB_LLVM_PATCH_FILE_NAME}"
}

# -----------------------------------------------------------------------------

# Environment variables:
# XBB_LLVM_PATCH_FILE_NAME

function llvm_build()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  export XBB_ACTUAL_LLVM_VERSION="$1"
  shift

  local llvm_version_major=$(xbb_get_version_major "${XBB_ACTUAL_LLVM_VERSION}")
  local llvm_version_minor=$(xbb_get_version_minor "${XBB_ACTUAL_LLVM_VERSION}")

  local llvm_enable_tests="${XBB_APPLICATION_LLVM_ENABLE_TESTS:-""}"

  local llvm_folder_name="llvm-${XBB_ACTUAL_LLVM_VERSION}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}"

  local llvm_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_folder_name}-installed"
  if [ ! -f "${llvm_stamp_file_path}" ]
  then

    llvm_download "${XBB_ACTUAL_LLVM_VERSION}"

    if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then
      # Disable the use of libxar.
      # It picks an unwanted system library, and compiling
      # it is too tedious.
      run_verbose sed -i.bak \
        -e 's|^check_library_exists(xar xar_open |# check_library_exists(xar xar_open |' \
        "${llvm_src_folder_name}/llvm/cmake/config-ix.cmake"

      run_verbose diff "${llvm_src_folder_name}/llvm/cmake/config-ix.cmake.bak" "${llvm_src_folder_name}/llvm/cmake/config-ix.cmake" || true
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

        # FAILED: tools/lldb/unittests/Editline/EditlineTests
        # Undefined symbols for architecture x86_64:
        #   "_setupterm", referenced from:
        #       lldb_private::Editline::Editline(char const*, __sFILE*, __sFILE*, __sFILE*, std::__1::recursive_mutex&, bool) in liblldbHost.a(Editline.cpp.o)
        # LDFLAGS+=" -lncurses"

        # To find libclang-cpp.dylib during compiler-rt build
        # run_verbose mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/lib"
        XBB_LIBRARY_PATH="${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/lib:${XBB_LIBRARY_PATH}"

        # For libc++.1.0.dylib to find libc++abi.1.dylib
        # run_verbose mkdir -pv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib"
        XBB_LIBRARY_PATH="${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib:${XBB_LIBRARY_PATH}"
      elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
      then
        # For libc++abi to find libunwind.so
        LDFLAGS+=" -L${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/lib"
        # run_verbose mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/lib"
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

          if is_develop
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

          config_options+=("-DCUDA_64_BIT_DEVICE_CODE=OFF")

          # config_options+=("-DCURSES_INCLUDE_PATH=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include/ncurses")

          config_options+=("-DFFI_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")
          config_options+=("-DFFI_LIB_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/lib")

          config_options+=("-DLLDB_ENABLE_LUA=OFF") # HB
          config_options+=("-DLLDB_ENABLE_PYTHON=OFF") # HB uses ON
          # config_options+=("-DLLDB_USE_SYSTEM_SIX=ON") # HB (?)

          config_options+=("-DLLVM_BUILD_DOCS=OFF")
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

            # https://gitlab.kitware.com/cmake/cmake/-/merge_requests/7671
            config_options+=("-DCMAKE_LINKER=ld") # HB

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

            # DO NOT!
            # compiler-rt is not built and later components fail with missing headers!

            # config_options+=("-DLLVM_BUILD_EXTERNAL_COMPILER_RT=ON") # HB

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

            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra;polly;")
            # HB builds the compiler-rt as RUNTIMES
            config_options+=("-DLLVM_ENABLE_RUNTIMES=compiler-rt;libunwind;libcxxabi;libcxx")

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
              config_options+=("-DDARWIN_osx_ARCHS=x86_64")
              config_options+=("-DDARWIN_osx_BUILTIN_ARCHS=i386;x86_64")
            elif [ "${XBB_HOST_ARCH}" == "arm64" ]
            then
              config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
              config_options+=("-DDARWIN_osx_ARCHS=arm64")
              config_options+=("-DDARWIN_osx_BUILTIN_ARCHS=arm64")
            else
              echo "Unsupported XBB_HOST_ARCH=${XBB_HOST_ARCH} in ${FUNCNAME[0]}()"
              exit 1
            fi

            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size;llvm-cxxfilt")

            # Prevent CMake from defaulting to `lld` when it's found next to `clang`.
            # This can be removed after CMake 3.25. See:
            # https://gitlab.kitware.com/cmake/cmake/-/merge_requests/7671
            # config_options+=("-DLLVM_USE_LINKER=ld") # HB

            if [ ! -z "${MACOSX_DEPLOYMENT_TARGET:-""}" ]
            then
              config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${MACOSX_DEPLOYMENT_TARGET}")
            fi

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

            config_options+=("-DCMAKE_LINKER=${LD}")

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
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra;polly;")
            config_options+=("-DLLVM_ENABLE_RUNTIMES=compiler-rt;libunwind;libcxxabi;libcxx")

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
              if [ ${llvm_version_major} -le 16 ]
              then
                # config_options+=("-DLLVM_RUNTIME_TARGETS=armv7l-unknown-linux-gnueabihf;aarch64-unknown-linux-gnu")
                config_options+=("-DLLVM_RUNTIME_TARGETS=aarch64-unknown-linux-gnu")
              fi
            elif [ "${XBB_HOST_ARCH}" == "arm" ]
            then
              if [ ${llvm_version_major} -le 16 ]
              then
                # https://github.com/llvm/llvm-project/issues/60115#issuecomment-1398288811
                config_options+=("-DLLVM_RUNTIME_TARGETS=armv7l-unknown-linux-gnueabihf")

                # https://github.com/llvm/llvm-project/issues/60115#issuecomment-1398640255
                # config_options+=("-DRUNTIMES_armv7l-unknown-linux-gnueabihf_COMPILER_RT_DEFAULT_TARGET_ONLY=ON")

                # https://github.com/llvm/llvm-project/issues/60115#issuecomment-1397024105
                # config_options+=("-DRUNTIMES_COMPILER_RT_BUILD_GWP_ASAN=OFF")
                # config_options+=("-DRUNTIMES_armv7l-unknown-linux-gnueabihf_COMPILER_RT_BUILD_GWP_ASAN=OFF")
              fi
            else
              echo "Unsupported XBB_HOST_ARCH=${XBB_HOST_ARCH} in ${FUNCNAME[0]}() "
              exit 1
            fi

            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size;llvm-cxxfilt")

          elif [ "${XBB_HOST_PLATFORM}" == "win32" ]
          then

            # CMake Error at cmake/modules/AddLLVM.cmake:967 (add_executable):
            #   The install of the llvm-tblgen target requires changing an RPATH from the
            #   build tree, but this is not supported with the Ninja generator unless on an
            #   ELF-based or XCOFF-based platform.  The CMAKE_BUILD_WITH_INSTALL_RPATH
            #   variable may be set to avoid this relinking step.
            # Call Stack (most recent call first):
            #   cmake/modules/TableGen.cmake:146 (add_llvm_executable)
            #   utils/TableGen/CMakeLists.txt:33 (add_tablegen)
            # Plus patch in llvm/cmake/modules/CrossCompile.cmake

            config_options+=("-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON")

            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++") # MS
            config_options+=("-DCLANG_DEFAULT_LINKER=lld") # MS
            config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt") # MS
            config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind") # MS

            # config_options+=("-DCMAKE_CROSSCOMPILING=ON")

            config_options+=("-DCMAKE_LINKER=${LD}")

            config_options+=("-DCMAKE_RC_COMPILER=${RC}") # MS

            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY") # MS
            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY") # MS
            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER") # MS
            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY") # MS

            config_options+=("-DCMAKE_SYSTEM_NAME=Windows") # MS

            config_options+=("-DCMAKE_FIND_ROOT_PATH=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}") # MS

            if [ ${llvm_version_major} -ge 16 ]
            then
              config_options+=("-DLLVM_NATIVE_TOOL_DIR=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin")
            else
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

              config_options+=("-DLLVM_CONFIG_PATH=${XBB_NATIVE_DEPENDENCIES_INSTALL_FOLDER_PATH}/bin/llvm-config") # MS
            fi

            config_options+=("-DLLD_DEFAULT_LD_LLD_IS_MINGW=ON") # MS

            config_options+=("-DLLDB_ENABLE_LZMA=OFF")

            config_options+=("-DLLVM_HOST_TRIPLE=${XBB_TARGET_TRIPLET}") # MS

            # Mind the links in llvm to clang, lld, lldb.
            config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON") # MS

            # TODO
            config_options+=("-DLLVM_ENABLE_FFI=ON")

            # mlir fails on windows, it tries to build the NATIVE folder and fails.
            # MS does not include polly
            # config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra")
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
            # "llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size;llvm-cxxfilt" # MS 20231128
            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size;llvm-cxxfilt") # MS

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

          if [ "${llvm_enable_tests}" == "y" ]
          then
            config_options+=("-DCLANG_INCLUDE_TESTS=ON")
            config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=ON")
            config_options+=("-DLLDB_INCLUDE_TESTS=ON")
            config_options+=("-DLLVM_BUILD_TESTS=ON")
            config_options+=("-DLLVM_INCLUDE_TESTS=ON")
          else
            config_options+=("-DCLANG_INCLUDE_TESTS=OFF")
            config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=OFF")
            config_options+=("-DLLDB_INCLUDE_TESTS=OFF")
            config_options+=("-DLLVM_BUILD_TESTS=OFF") # Arch uses ON
            config_options+=("-DLLVM_INCLUDE_TESTS=OFF") # No tests, HB
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

        if is_develop
        then
          run_verbose_timed "${CMAKE}" \
            --build . \
            --verbose \
            --parallel ${XBB_JOBS}

          if with_strip
          then
            run_verbose "${CMAKE}" \
              --build . \
              --verbose \
              --target install/strip
          else
            run_verbose "${CMAKE}" \
              --build . \
              --verbose \
              --target install
          fi

          if [ "${llvm_enable_tests}" == "y" ]
          then
            # FAILED: tools/lldb/unittests/Editline/EditlineTests
            # Undefined symbols for architecture x86_64:
            #   "_setupterm", referenced from:
            #       lldb_private::Editline::Editline(char const*, __sFILE*, __sFILE*, __sFILE*, std::__1::recursive_mutex&, bool) in liblldbHost.a(Editline.cpp.o)

            # Please note that a full check takes a lot of time.
            run_verbose "${CMAKE}" \
              --build . \
              --verbose \
              --target check-clang # check #$ check-clang-driver # || true
          fi

        else
          run_verbose "${CMAKE}" \
            --build .

          if with_strip
          then
            run_verbose "${CMAKE}" \
              --build . \
              --target install/strip
          else
            run_verbose "${CMAKE}" \
              --build . \
              --target install
          fi
        fi

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          if [ ${llvm_version_major} -ge 16 ]
          then
            # Starting with clang 16, only the major is used.
            if [ ! -f "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${llvm_version_major}/lib/darwin/libclang_rt.profile_osx.a" ]
            then
              echo
              echo "Missing libclang_rt.profile_osx.a"
              exit 1
            fi
          else
            # Up to clang 15, the full version number was used.
            if [ ! -f "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${XBB_ACTUAL_LLVM_VERSION}/lib/darwin/libclang_rt.profile_osx.a" ]
            then
              echo
              echo "Missing libclang_rt.profile_osx.a"
              exit 1
            fi
          fi
        fi

        (
          if true # [ "${is_bootstrap}" != "y" ]
          then
            echo
            echo "Removing less used files..."

            # Remove less used LLVM libraries and leave only the toolchain.
            cd "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
            for f in \
              amdgpu-arch \
              bugpoint c-index-test \
              clang-apply-replacements clang-change-namespace \
              clang-extdef-mapping clang-include-fixer clang-move \
              clang-offload-bundler clang-offload-packager clang-pseudo \
              clang-query \
              clang-reorder-fields find-all-symbols \
              clangd-xpc-test-client \
              count dsymutil FileCheck \
              intercept-build \
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
              modularize not nvptx-arch \
              obj2yaml opt pp-trace sancov sanstats \
              scan-build scan-build.bat scan-view \
              verify-uselistorder yaml-bench yaml2obj \
              UnicodeNameMappingGenerator
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

# =============================================================================

function llvm_test()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  local test_bin_path="$1"
  shift

  local name_suffix=""
  local name_prefix=""

  (
    echo
    echo "Testing the ${name_prefix}llvm binaries..."

    if [ "${XBB_TEST_SYSTEM_TOOLS:-""}" == "y" ]
    then
      # On Ubuntu requires
      # sudo apt-get install --yes clang lld libc++-dev libc++abi-dev

      CC="$(which clang)"
      CXX="$(which clang++)"

      AR="$(which llvm-ar || which ar)"
      RANLIB="$(which llvm-ranlib || which ranlib)"

      if [ "${XBB_BUILD_PLATFORM}" == "win32" ]
      then
        DLLTOOL="$(which llvm-dlltool)"
        WIDL="$(which widl)"
        GENDEF="$(which gendef)"
      fi

      LLD="$(which lld || true)"
      LLDB="$(which lldb || true)"
      CLANG_FORMAT="$(which clang-format || true)"

      LD_LLD="$(which ld.lld || true)"
      LD64_LLD="$(which ld64.lld || true)"

      CLANGD="$(which clangd || true)"

      LLVM_AR="$(which llvm-ar || true)"
      LLVM_NM="$(which llvm-nm || true)"
      LLVM_OBJCOPY="$(which llvm-objcopy || true)"
      LLVM_OBJDUMP="$(which llvm-objdump || true)"
      LLVM_RANLIB="$(which llvm-ranlib || true)"
      LLVM_READELF="$(which llvm-readelf || true)"
      LLVM_SIZE="$(which llvm-size || true)"
      LLVM_STRINGS="$(which llvm-strings || true)"
      LLVM_STRIP="$(which llvm-strip || true)"
    else
      run_verbose ls -l "${test_bin_path}"

      CC="${test_bin_path}/clang"
      CXX="${test_bin_path}/clang++"
      DLLTOOL="${test_bin_path}/llvm-dlltool"
      WIDL="${test_bin_path}/widl"
      GENDEF="${test_bin_path}/gendef"
      AR="${test_bin_path}/llvm-ar"
      RANLIB="${test_bin_path}/llvm-ranlib"

      LLD="${test_bin_path}/lld"
      LLDB="${test_bin_path}/lldb"
      CLANG_FORMAT="${test_bin_path}/clang-format"

      LD_LLD="${test_bin_path}/ld.lld"
      LD64_LLD="${test_bin_path}/ld64.lld"

      CLANGD="${test_bin_path}/clangd"

      LLVM_AR="${test_bin_path}/llvm-ar"
      LLVM_NM="${test_bin_path}/llvm-nm"
      LLVM_OBJCOPY="${test_bin_path}/llvm-objcopy"
      LLVM_OBJDUMP="${test_bin_path}/llvm-objdump"
      LLVM_RANLIB="${test_bin_path}/llvm-ranlib"
      LLVM_READELF="${test_bin_path}/llvm-readelf"
      LLVM_SIZE="${test_bin_path}/llvm-size"
      LLVM_STRINGS="${test_bin_path}/llvm-strings"
      LLVM_STRIP="${test_bin_path}/llvm-strip"
    fi

    # -------------------------------------------------------------------------

    export LLVM_VERSION=$(run_host_app "${CC}" -dumpversion)
    echo "clang: ${LLVM_VERSION}"

    export LLVM_VERSION_MAJOR=$(xbb_get_version_major "${LLVM_VERSION}")

    # -------------------------------------------------------------------------

    if [ "${XBB_BUILD_PLATFORM}" != "win32" ]
    then
      show_host_libs "${CC}"
      if [ -f "${LLD}${XBB_HOST_DOT_EXE}" ]
      then
        show_host_libs "${LLD}"
      fi
      if [ -f "${LLDB}${XBB_HOST_DOT_EXE}" ]
      then
        # lldb not available on Ubuntu 16 Arm.
        show_host_libs "${LLDB}"
      fi
    fi

    test_case_llvm_binaries_start

    test_case_clang_configuration

    # -------------------------------------------------------------------------

    echo
    echo "Testing if ${name_prefix}clang compiles simple programs..."

    rm -rf "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"
    mkdir -pv "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"
    cd "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"

    echo
    echo "pwd: $(pwd)"

    # -------------------------------------------------------------------------

    source "${helper_folder_path}/tests/c-cpp/test-compiler.sh"
    run_verbose cp -Rv "${helper_folder_path}/tests/c-cpp" .
    chmod -R a+w c-cpp

    run_verbose cp -Rv "${helper_folder_path}/tests/wine"/* c-cpp
    chmod -R a+w c-cpp

    # source "${helper_folder_path}/tests/fortran/test-compiler.sh"
    # run_verbose cp -Rv "${helper_folder_path}/tests/fortran" .
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
      test_win32
    elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
    then
      test_linux
    elif [ "${XBB_HOST_PLATFORM}" == "darwin" ]
    then
      test_darwin
    fi

    # -------------------------------------------------------------------------

    (
      cd c-cpp

      if [ -f "${CLANGD}${XBB_HOST_DOT_EXE}" ]
      then

        test_case_clangd_hello

        # Segmentation fault (core dumped) on 13 & 14
        test_case_clangd_unchecked_exception

      fi
    )

  )
}

# -----------------------------------------------------------------------------

function test_case_llvm_binaries_start()
{
  local test_case_name="$(test_case_get_name)"

  local prefix=${PREFIX:-""}
  local suffix=${SUFFIX:-""}

  (
    trap 'test_case_trap_handler ${test_case_name} $? $LINENO; return 0' ERR

    echo
    echo "Testing if the ${prefix}llvm binaries start properly..."

    run_host_app_verbose "${CC}" --version
    run_host_app_verbose "${CXX}" --version

    if [ -f "${CLANG_FORMAT}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${CLANG_FORMAT}" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    # run_host_app_verbose "${LLD}" --version || true
    if [ "${XBB_HOST_PLATFORM}" == "linux" ] && [ -f "${LD_LLD}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LD_LLD}" --version || true
    elif [ "${XBB_HOST_PLATFORM}" == "darwin" ] && [ -f "${LD64_LLD}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LD64_LLD}" --version || true
    elif [ "${XBB_HOST_PLATFORM}" == "win32" ] && [ -f "${LD_LLD}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LD_LLD}" --version || true
    fi

    if [ -f "${LLVM_AR}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_AR}" --version
    fi
    if [ "${LLVM_NM}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_NM}" --version
    fi
    if [ -f "${LLVM_OBJCOPY}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_OBJCOPY}" --version
    fi
    if [ -f "${LLVM_OBJDUMP}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_OBJDUMP}" --version
    fi
    if [ -f "${LLVM_RANLIB}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_RANLIB}" --version
    fi
    if [ -f "${LLVM_READELF}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_READELF}" --version
    fi
    if [ -f "${LLVM_SIZE}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_SIZE}" --version
    fi
    if [ -f "${LLVM_STRINGS}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_STRINGS}" --version
    fi
    if [ -f "${LLVM_STRIP}${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${LLVM_STRIP}" --version
    fi

    test_case_pass "${test_case_name}"
  ) 2>&1 | tee "${XBB_TEST_RESULTS_FOLDER_PATH}/${prefix}${test_case_name}${suffix}.txt"
}


function test_case_clang_configuration()
{
  local test_case_name="$(test_case_get_name)"

  local prefix=${PREFIX:-""}
  local suffix=${SUFFIX:-""}

  (
    trap 'test_case_trap_handler ${test_case_name} $? $LINENO; return 0' ERR

    echo
    echo "Testing the ${prefix}clang configuration..."

    # Show the selected GCC & multilib.
    # There must be a g++ with that version installed,
    # otherwise the tests will not find the C++ headers and/or libraries.
    run_host_app_verbose "${CC}" -v

    if [ ${LLVM_VERSION_MAJOR} -gt 10 ]
    then
      run_host_app_verbose "${CC}" -print-target-triple
      run_host_app_verbose "${CC}" -print-targets
      run_host_app_verbose "${CC}" -print-supported-cpus
    fi
    run_host_app_verbose "${CC}" -print-search-dirs
    run_host_app_verbose "${CC}" -print-resource-dir
    run_host_app_verbose "${CC}" -print-libgcc-file-name

    # run_app_verbose "${test_bin_path}/llvm-config" --help

    test_case_pass "${test_case_name}"
  ) 2>&1 | tee "${XBB_TEST_RESULTS_FOLDER_PATH}/${prefix}${test_case_name}${suffix}.txt"
}

# -----------------------------------------------------------------------------

function test_win32()
{
  # Defaults:
  # config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++") # MS
  # config_options+=("-DCLANG_DEFAULT_LINKER=lld") # MS
  # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt") # MS
  # config_options+=("-DCLANG_DEFAULT_UNWINDLIB=libunwind") # MS

  if [ ${LLVM_VERSION_MAJOR} -eq 14 ] || \
     [ ${LLVM_VERSION_MAJOR} -eq 15 ]
  then
    # export XBB_IGNORE_TEST_ALL_BUFFEROVERFLOW="y"
    export XBB_SKIP_TEST_ALL_BUFFEROVERFLOW="y"

    # LTO weak C++ tests fail with 14.0.6-3 & 15.0.7-1.
    # ld.lld: error: duplicate symbol: world()
    # >>> defined at hello-weak-cpp.cpp
    # >>>            lto-hello-weak-cpp-32.cpp.o
    # >>> defined at hello-f-weak-cpp.cpp
    # >>>            lto-hello-f-weak-cpp-32.cpp.o
    # clang-15: error: linker command failed with exit code 1 (use -v to see invocation)

    # Skip the same tests for both triplets.
    export XBB_IGNORE_TEST_LTO_HELLO_WEAK2_CPP="y"
    export XBB_IGNORE_TEST_GC_LTO_HELLO_WEAK2_CPP="y"

    export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO_WEAK2_CPP="y"
    export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK2_CPP="y"

    export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK2_CPP="y"
    export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO_WEAK2_CPP="y"
  elif [ ${LLVM_VERSION_MAJOR} -eq 16 ]
  then
    # bufferoverflow.
    # error: unable to find library -lssp
    # export XBB_IGNORE_TEST_ALL_BUFFEROVERFLOW="y"
    export XBB_SKIP_TEST_ALL_BUFFEROVERFLOW="y"

    # Both 32 & 64-bit are affected.
    # Surprisingly, the non LTO variant is functional.
    export XBB_IGNORE_TEST_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LTO_WEAK_UNDEF_C="y"

    export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_UNDEF_C="y"

    export XBB_IGNORE_TEST_STATIC_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_UNDEF_C="y"
  elif [ ${LLVM_VERSION_MAJOR} -eq 17 ]
  then

    # fail: lto-weak-undef-c-32
    # fail: gc-lto-weak-undef-c-32
    # fail: static-lib-lto-weak-undef-c-32
    # fail: static-lib-gc-lto-weak-undef-c-32
    # fail: static-lto-weak-undef-c-32
    # fail: static-gc-lto-weak-undef-c-32
    # fail: lto-weak-undef-c-64
    # fail: gc-lto-weak-undef-c-64
    # fail: static-lib-lto-weak-undef-c-64
    # fail: static-lib-gc-lto-weak-undef-c-64
    # fail: static-lto-weak-undef-c-64
    # fail: static-gc-lto-weak-undef-c-64

    # bufferoverflow.
    # error: unable to find library -lssp
    # export XBB_IGNORE_TEST_ALL_BUFFEROVERFLOW="y"
    export XBB_SKIP_TEST_ALL_BUFFEROVERFLOW="y"

    # weak-undef
    # Surprisingly, the non LTO variant is functional.
    # export XBB_IGNORE_TEST_WEAK_UNDEF_C_32="y"
    # export XBB_IGNORE_TEST_GC_WEAK_UNDEF_C="y"

    # ... but fails with LTO, even with lld.
    # ld.lld: error: undefined symbol: _func
    # >>> referenced by main-weak.c
    # >>>               lto-main-weak-32.c.o

    # Both 32 & 64-bit are affected.
    export XBB_IGNORE_TEST_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LTO_WEAK_UNDEF_C="y"

    export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_UNDEF_C="y"

    export XBB_IGNORE_TEST_STATIC_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_UNDEF_C="y"
  elif [ ${LLVM_VERSION_MAJOR} -eq 18 ]
  then
    # bufferoverflow.
    # error: unable to find library -lssp
    # export XBB_IGNORE_TEST_ALL_BUFFEROVERFLOW="y"
    : # export XBB_SKIP_TEST_ALL_BUFFEROVERFLOW="y"
  fi

  for bits in 32 64
  do
    (
      # For libc++.dll & co.
      # The DLLs are usually in bin, but for consistency within GCC, they are
      # also copied to lib; it is recommended to ask the compiler for the
      # actual path.
      if [ "${XBB_BUILD_PLATFORM}" == "win32" ]
      then
        # When running natively, set the PATH.
        libcxx_file_path="$(${CXX} -m${bits} -print-file-name=libc++.dll)"
        if [ "${libcxx_file_path}" == "libc++.dll" ]
        then
          echo "Cannot get libc++.dll path"
          exit 1
        fi
        cxx_lib_path=$(dirname $(echo "${libcxx_file_path}" | sed -e 's|:||' | sed -e 's|^|/|'))
        export PATH="${cxx_lib_path}:${PATH:-}"
        echo
        echo "${bits}-bits libs"
        echo "PATH=${PATH}"
      elif [ "${XBB_BUILD_PLATFORM}" == "linux" ]
      then
        # When running via wine, set WINEPATH.
        libcxx_file_path="$(wine64 ${CXX}.exe -m${bits} -print-file-name=libc++.dll)"
        if [ "${libcxx_file_path}" == "libc++.dll" ]
        then
          echo "Cannot get libc++.dll path"
          exit 1
        fi
        cxx_lib_path=$(dirname $(echo "${libcxx_file_path}" | sed -e 's|[a-zA-Z]:||'))
        export WINEPATH="${cxx_lib_path};${WINEPATH:-}"
        echo
        echo "${bits}-bits libs"
        echo "WINEPATH=${WINEPATH}"
      else
        echo "Unsupported XBB_BUILD_PLATFORM=${XBB_BUILD_PLATFORM} in ${FUNCNAME[0]}()"
        exit 1
      fi

      test_compiler_c_cpp --${bits}

      test_compiler_c_cpp --${bits} --gc
      test_compiler_c_cpp --${bits} --lto
      test_compiler_c_cpp --${bits} --gc --lto
    )

    # All static variants should need no special paths to DLLs.
    test_compiler_c_cpp --${bits} --static-lib
    test_compiler_c_cpp --${bits} --static-lib --gc
    test_compiler_c_cpp --${bits} --static-lib --lto
    test_compiler_c_cpp --${bits} --static-lib --gc --lto

    test_compiler_c_cpp --${bits} --static
    test_compiler_c_cpp --${bits} --static --gc
    test_compiler_c_cpp --${bits} --static --lto
    test_compiler_c_cpp --${bits} --static --gc --lto

  done
}

# -----------------------------------------------------------------------------

function test_linux()
{
  local distro=$(lsb_release -is)
  echo
  run_verbose lsb_release -a

  # Defaults:
  # config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libstdc++")
  # config_options+=("-DCLANG_DEFAULT_RTLIB=libgcc")

  if [ ${LLVM_VERSION_MAJOR} -eq 15 ]
  then
    # LTO global-terminate test fails on 15.0.7-1.
    # Segmentation fault (core dumped)
    # Program received signal SIGSEGV, Segmentation fault.
    # __strlen_avx2 () at ../sysdeps/x86_64/multiarch/strlen-avx2.S:65

    export XBB_IGNORE_TEST_LTO_GLOBAL_TERMINATE_64="y"
    export XBB_IGNORE_TEST_GC_LTO_GLOBAL_TERMINATE_64="y"
  elif [ ${LLVM_VERSION_MAJOR} -eq 16 ]
  then
    if [ "${XBB_HOST_ARCH}" == "arm" ]
    then
      # adder-shared.
      export XBB_IGNORE_TEST_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_GC_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_LTO_CRT_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_ADDER_SHARED="y"

      # adder-static.
      export XBB_IGNORE_TEST_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_GC_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_LTO_CRT_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_ADDER_STATIC="y"

      # cnrt-test.
      export XBB_IGNORE_TEST_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_GC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_LTO_CRT_CNRT_TEST="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_CNRT_TEST="y"

      # exception-locale.
      export XBB_IGNORE_TEST_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_LTO_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_CRT_LLD_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_CRT_LLD_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_LTO_CRT_LLD_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LLD_EXCEPTION_LOCALE="y"

      # exception-reduced.
      export XBB_IGNORE_TEST_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_LTO_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_CRT_LLD_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_CRT_LLD_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_LTO_CRT_LLD_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LLD_EXCEPTION_REDUCED="y"

      # global-terminate.
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_STATIC_LTO_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_LTO_CRT_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_GLOBAL_TERMINATE="y"

      # hello-exception.
      export XBB_IGNORE_TEST_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_CRT_LLD_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_CRT_LLD_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_LTO_CRT_LLD_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LLD_HELLO_EXCEPTION="y"

      # hello-weak1-c.
      export XBB_IGNORE_TEST_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_GC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_WEAK1_C="y"

      # hello-weak2-cpp.
      export XBB_IGNORE_TEST_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_WEAK2_CPP="y"

      # hello1-c.
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO1_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO1_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO1_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO1_C="y"

      # normal.
      export XBB_IGNORE_TEST_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_GC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_LTO_CRT_NORMAL="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_NORMAL="y"

      # simple-hello-printf-one.
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_HELLO_PRINTF_ONE="y"

      # simple-hello-printf-two.
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_HELLO_PRINTF_TWO="y"

      # simple-objc.
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_OBJC="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_OBJC="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_OBJC="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_OBJC="y"

      # sleepy-threads-cv.
      export XBB_IGNORE_TEST_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_GC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_SLEEPY_THREADS_CV="y"

      # throwcatch-main.
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_LTO_CRT_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_THROWCATCH_MAIN="y"

      # unwind-strong-cpp.
      export XBB_IGNORE_TEST_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_UNWIND_STRONG_CPP="y"

      # unwind-weak-cpp.
      export XBB_IGNORE_TEST_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_UNWIND_WEAK_CPP="y"

      # weak-defined-c.
      export XBB_IGNORE_TEST_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_DEFINED_C="y"

      # weak-duplicate-c.
      export XBB_IGNORE_TEST_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_DUPLICATE_C="y"

      # weak-override-c.
      export XBB_IGNORE_TEST_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_OVERRIDE_C="y"

      # weak-undef-c.
      export XBB_IGNORE_TEST_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_UNDEF_C="y"

      # weak-use-c.
      export XBB_IGNORE_TEST_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_USE_C="y"
    fi
  elif [ ${LLVM_VERSION_MAJOR} -eq 17 ] || \
       [ ${LLVM_VERSION_MAJOR} -eq 18 ]
  then
    if [ "${XBB_HOST_ARCH}" == "x64" ]
    then

      # x64
      # 72 test(s) failed:

      # fail: static-sleepy-threads-64
      # fail: static-sleepy-threads-cv-64
      # fail: static-gc-sleepy-threads-64
      # fail: static-gc-sleepy-threads-cv-64
      # fail: static-lto-sleepy-threads-64
      # fail: static-lto-sleepy-threads-cv-64
      # fail: static-gc-lto-sleepy-threads-64
      # fail: static-gc-lto-sleepy-threads-cv-64
      # fail: static-lld-sleepy-threads-64
      # fail: static-lld-sleepy-threads-cv-64
      # fail: static-gc-lld-sleepy-threads-64
      # fail: static-gc-lld-sleepy-threads-cv-64
      # fail: static-lto-lld-sleepy-threads-64
      # fail: static-lto-lld-sleepy-threads-cv-64
      # fail: static-gc-lto-lld-sleepy-threads-64
      # fail: static-gc-lto-lld-sleepy-threads-cv-64
      # fail: static-sleepy-threads-32
      # fail: static-sleepy-threads-cv-32
      # fail: static-gc-sleepy-threads-32
      # fail: static-gc-sleepy-threads-cv-32
      # fail: static-lto-sleepy-threads-32
      # fail: static-lto-sleepy-threads-cv-32
      # fail: static-gc-lto-sleepy-threads-32
      # fail: static-gc-lto-sleepy-threads-cv-32
      # fail: static-lld-simple-hello1-cpp-one-32
      # fail: static-lld-simple-hello1-cpp-two-32
      # fail: static-lld-simple-exception-32
      # fail: static-lld-simple-str-exception-32
      # fail: static-lld-simple-int-exception-32
      # fail: static-lld-sleepy-threads-32
      # fail: static-lld-sleepy-threads-cv-32
      # fail: static-lld-hello-cpp-32
      # fail: static-lld-exception-locale-32
      # fail: static-lld-crt-test-32
      # fail: static-lld-hello-weak-cpp-32
      # fail: static-lld-overload-new-cpp-32
      # fail: static-gc-lld-simple-hello1-cpp-one-32
      # fail: static-gc-lld-simple-hello1-cpp-two-32
      # fail: static-gc-lld-simple-exception-32
      # fail: static-gc-lld-simple-str-exception-32
      # fail: static-gc-lld-simple-int-exception-32
      # fail: static-gc-lld-sleepy-threads-32
      # fail: static-gc-lld-sleepy-threads-cv-32
      # fail: static-gc-lld-hello-cpp-32
      # fail: static-gc-lld-exception-locale-32
      # fail: static-gc-lld-crt-test-32
      # fail: static-gc-lld-hello-weak-cpp-32
      # fail: static-gc-lld-overload-new-cpp-32
      # fail: static-lto-lld-simple-hello1-cpp-one-32
      # fail: static-lto-lld-simple-hello1-cpp-two-32
      # fail: static-lto-lld-simple-exception-32
      # fail: static-lto-lld-simple-str-exception-32
      # fail: static-lto-lld-simple-int-exception-32
      # fail: static-lto-lld-sleepy-threads-32
      # fail: static-lto-lld-sleepy-threads-cv-32
      # fail: static-lto-lld-hello-cpp-32
      # fail: static-lto-lld-exception-locale-32
      # fail: static-lto-lld-crt-test-32
      # fail: static-lto-lld-hello-weak-cpp-32
      # fail: static-lto-lld-overload-new-cpp-32
      # fail: static-gc-lto-lld-simple-hello1-cpp-one-32
      # fail: static-gc-lto-lld-simple-hello1-cpp-two-32
      # fail: static-gc-lto-lld-simple-exception-32
      # fail: static-gc-lto-lld-simple-str-exception-32
      # fail: static-gc-lto-lld-simple-int-exception-32
      # fail: static-gc-lto-lld-sleepy-threads-32
      # fail: static-gc-lto-lld-sleepy-threads-cv-32
      # fail: static-gc-lto-lld-hello-cpp-32
      # fail: static-gc-lto-lld-exception-locale-32
      # fail: static-gc-lto-lld-crt-test-32
      # fail: static-gc-lto-lld-hello-weak-cpp-32
      # fail: static-gc-lto-lld-overload-new-cpp-32

      # Weird, -static crashes the threads.
      # 201486 Segmentation fault      (core dumped)

      # sleepy-threads.
      export XBB_IGNORE_TEST_STATIC_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SLEEPY_THREADS_SL="y"

      export XBB_IGNORE_TEST_STATIC_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SLEEPY_THREADS_SL="y"

      # sleepy-threads-cv.
      export XBB_IGNORE_TEST_STATIC_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SLEEPY_THREADS_CV="y"

      export XBB_IGNORE_TEST_STATIC_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SLEEPY_THREADS_CV="y"

      # -------------------------------------------------------------------
      # -static and lld seem to have a problem with C++, but only on 32-bit.

      # ld.lld: error: duplicate symbol: __x86.get_pc_thunk.cx
      # >>> defined at locale.o:(.text.__x86.get_pc_thunk.cx+0x0) in archive /usr/lib/gcc/x86_64-linux-gnu/7/32/libstdc++.a
      # >>> defined at stpncpy-sse2.o:(.gnu.linkonce.t.__x86.get_pc_thunk.cx+0x0) in archive /usr/lib/gcc/x86_64-linux-gnu/7/../../../../lib32/libc.a
      # clang++: error: linker command failed with exit code 1 (use -v to see invocation)

      # simple-hello1-cpp-one.
      export XBB_IGNORE_TEST_STATIC_LLD_SIMPLE_HELLO_COUT_ONE_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SIMPLE_HELLO_COUT_ONE_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SIMPLE_HELLO_COUT_ONE_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SIMPLE_HELLO_COUT_ONE_32="y"

      # simple-hello1-cpp-two.
      export XBB_IGNORE_TEST_STATIC_LLD_SIMPLE_HELLO_COUT_TWO_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SIMPLE_HELLO_COUT_TWO_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SIMPLE_HELLO_COUT_TWO_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SIMPLE_HELLO_COUT_TWO_32="y"

      # simple-exception.
      export XBB_IGNORE_TEST_STATIC_LLD_SIMPLE_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SIMPLE_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SIMPLE_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SIMPLE_EXCEPTION_32="y"

      # simple-str-exception.
      export XBB_IGNORE_TEST_STATIC_LLD_SIMPLE_STR_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SIMPLE_STR_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SIMPLE_STR_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SIMPLE_STR_EXCEPTION_32="y"

      # simple-int-exception.
      export XBB_IGNORE_TEST_STATIC_LLD_SIMPLE_INT_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SIMPLE_INT_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SIMPLE_INT_EXCEPTION_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SIMPLE_INT_EXCEPTION_32="y"

      # hello-cpp.
      export XBB_IGNORE_TEST_STATIC_LLD_HELLO2_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_HELLO2_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_HELLO2_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_HELLO2_CPP_32="y"

      # exception-locale.
      export XBB_IGNORE_TEST_STATIC_LLD_EXCEPTION_LOCALE_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_EXCEPTION_LOCALE_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_EXCEPTION_LOCALE_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_EXCEPTION_LOCALE_32="y"

      # crt-test.
      export XBB_IGNORE_TEST_STATIC_LLD_CNRT_TEST_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_CNRT_TEST_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_CNRT_TEST_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_CNRT_TEST_32="y"

      # hello-weak-cpp.
      export XBB_IGNORE_TEST_STATIC_LLD_HELLO_WEAK2_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_HELLO_WEAK2_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_HELLO_WEAK2_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_HELLO_WEAK2_CPP_32="y"

      # overload-new-cpp.
      export XBB_IGNORE_TEST_STATIC_LLD_OVERLOAD_NEW_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_OVERLOAD_NEW_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_OVERLOAD_NEW_CPP_32="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_OVERLOAD_NEW_CPP_32="y"
    elif [ "${XBB_HOST_ARCH}" == "arm64" ]
    then
      # arm64
      # 16 test(s) failed:

      # fail: static-sleepy-threads
      # fail: static-sleepy-threads-cv
      # fail: static-gc-sleepy-threads
      # fail: static-gc-sleepy-threads-cv
      # fail: static-lto-sleepy-threads
      # fail: static-lto-sleepy-threads-cv
      # fail: static-gc-lto-sleepy-threads
      # fail: static-gc-lto-sleepy-threads-cv
      # fail: static-lld-sleepy-threads
      # fail: static-lld-sleepy-threads-cv
      # fail: static-gc-lld-sleepy-threads
      # fail: static-gc-lld-sleepy-threads-cv
      # fail: static-lto-lld-sleepy-threads
      # fail: static-lto-lld-sleepy-threads-cv
      # fail: static-gc-lto-lld-sleepy-threads
      # fail: static-gc-lto-lld-sleepy-threads-cv

      # sleepy-threads.
      export XBB_IGNORE_TEST_STATIC_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SLEEPY_THREADS_SL="y"

      export XBB_IGNORE_TEST_STATIC_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SLEEPY_THREADS_SL="y"

      # sleepy-threads-cv.
      # terminate called after throwing an instance of 'std::system_error'
      #   what():  Unknown error 5774344

      export XBB_IGNORE_TEST_STATIC_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SLEEPY_THREADS_CV="y"

      export XBB_IGNORE_TEST_STATIC_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SLEEPY_THREADS_CV="y"
    elif [ "${XBB_HOST_ARCH}" == "arm" ]
    then

      # arm
      # Basically LTO is unreliable, use LLD.
      # Static is also unreliable.

      # 1246 test(s) passed, 130 failed:

      # fail: lto-adder-shared
      # fail: lto-simple-exception
      # fail: lto-sleepy-threads
      # fail: lto-hello-cpp
      # fail: lto-longjmp-cleanup
      # fail: lto-hello-weak-cpp
      # fail: lto-normal
      # fail: lto-weak-undef-c
      # fail: lto-weak-defined-c
      # fail: lto-weak-use-c
      # fail: lto-weak-override-c
      # fail: gc-lto-adder-shared
      # fail: gc-lto-simple-exception
      # fail: gc-lto-sleepy-threads
      # fail: gc-lto-hello-cpp
      # fail: gc-lto-longjmp-cleanup
      # fail: gc-lto-hello-weak-c
      # fail: gc-lto-hello-weak-cpp
      # fail: gc-lto-normal
      # fail: gc-lto-weak-undef-c
      # fail: gc-lto-weak-defined-c
      # fail: gc-lto-weak-use-c
      # fail: gc-lto-weak-override-c
      # fail: static-lib-lto-adder-shared
      # fail: static-lib-lto-simple-exception
      # fail: static-lib-lto-sleepy-threads
      # fail: static-lib-lto-longjmp-cleanup
      # fail: static-lib-lto-hello-weak-c
      # fail: static-lib-lto-normal
      # fail: static-lib-lto-weak-undef-c
      # fail: static-lib-lto-weak-defined-c
      # fail: static-lib-lto-weak-use-c
      # fail: static-lib-lto-weak-override-c
      # fail: static-lib-gc-lto-adder-shared
      # fail: static-lib-gc-lto-simple-exception
      # fail: static-lib-gc-lto-sleepy-threads
      # fail: static-lib-gc-lto-hello-cpp
      # fail: static-lib-gc-lto-longjmp-cleanup
      # fail: static-lib-gc-lto-hello-weak-c
      # fail: static-lib-gc-lto-hello-weak-cpp
      # fail: static-lib-gc-lto-normal
      # fail: static-lib-gc-lto-weak-undef-c
      # fail: static-lib-gc-lto-weak-defined-c
      # fail: static-lib-gc-lto-weak-use-c
      # fail: static-lib-gc-lto-weak-override-c
      # fail: static-sleepy-threads
      # fail: static-sleepy-threads-cv
      # fail: static-gc-sleepy-threads
      # fail: static-gc-sleepy-threads-cv
      # fail: static-lto-simple-exception
      # fail: static-lto-sleepy-threads
      # fail: static-lto-sleepy-threads-cv
      # fail: static-lto-longjmp-cleanup
      # fail: static-lto-exception-reduced
      # fail: static-lto-hello-weak-c
      # fail: static-lto-normal
      # fail: static-lto-weak-undef-c
      # fail: static-lto-weak-defined-c
      # fail: static-lto-weak-use-c
      # fail: static-lto-weak-override-c
      # fail: static-gc-lto-simple-exception
      # fail: static-gc-lto-simple-str-exception
      # fail: static-gc-lto-sleepy-threads
      # fail: static-gc-lto-sleepy-threads-cv
      # fail: static-gc-lto-hello-cpp
      # fail: static-gc-lto-longjmp-cleanup
      # fail: static-gc-lto-exception-reduced
      # fail: static-gc-lto-hello-weak-c
      # fail: static-gc-lto-normal
      # fail: static-gc-lto-weak-undef-c
      # fail: static-gc-lto-weak-defined-c
      # fail: static-gc-lto-weak-use-c
      # fail: static-gc-lto-weak-override-c
      # fail: static-lld-sleepy-threads
      # fail: static-lld-sleepy-threads-cv
      # fail: static-gc-lld-sleepy-threads
      # fail: static-gc-lld-sleepy-threads-cv
      # fail: static-lto-lld-sleepy-threads
      # fail: static-lto-lld-sleepy-threads-cv
      # fail: static-gc-lto-lld-sleepy-threads
      # fail: static-gc-lto-lld-sleepy-threads-cv
      # fail: crt-hello-exception
      # fail: crt-exception-locale
      # fail: crt-exception-reduced
      # fail: gc-crt-hello-exception
      # fail: gc-crt-exception-locale
      # fail: gc-crt-exception-reduced
      # fail: lto-crt-adder-shared
      # fail: lto-crt-simple-exception
      # fail: lto-crt-sleepy-threads
      # fail: lto-crt-hello-cpp
      # fail: lto-crt-longjmp-cleanup
      # fail: lto-crt-hello-exception
      # fail: lto-crt-exception-locale
      # fail: lto-crt-exception-reduced
      # fail: lto-crt-hello-weak-c
      # fail: lto-crt-normal
      # fail: lto-crt-weak-undef-c
      # fail: lto-crt-weak-defined-c
      # fail: lto-crt-weak-use-c
      # fail: lto-crt-weak-override-c
      # fail: lto-crt-weak-duplicate-c
      # fail: gc-lto-crt-adder-shared
      # fail: gc-lto-crt-simple-exception
      # fail: gc-lto-crt-sleepy-threads
      # fail: gc-lto-crt-hello-cpp
      # fail: gc-lto-crt-longjmp-cleanup
      # fail: gc-lto-crt-hello-exception
      # fail: gc-lto-crt-exception-locale
      # fail: gc-lto-crt-exception-reduced
      # fail: gc-lto-crt-hello-weak-c
      # fail: gc-lto-crt-hello-weak-cpp
      # fail: gc-lto-crt-normal
      # fail: gc-lto-crt-weak-undef-c
      # fail: gc-lto-crt-weak-defined-c
      # fail: gc-lto-crt-weak-use-c
      # fail: gc-lto-crt-weak-override-c
      # fail: gc-lto-crt-weak-duplicate-c
      # fail: crt-lld-hello-exception
      # fail: crt-lld-exception-locale
      # fail: crt-lld-exception-reduced
      # fail: gc-crt-lld-hello-exception
      # fail: gc-crt-lld-exception-locale
      # fail: gc-crt-lld-exception-reduced
      # fail: lto-crt-lld-hello-exception
      # fail: lto-crt-lld-exception-locale
      # fail: lto-crt-lld-exception-reduced
      # fail: gc-lto-crt-lld-hello-exception
      # fail: gc-lto-crt-lld-exception-locale
      # fail: gc-lto-crt-lld-exception-reduced

      # adder-shared.
      # clang lto-add.c.o -shared -o liblto-add-shared.so -flto -g -v
      # clang: error: unable to execute command: Segmentation fault (core dumped)
      # clang: error: linker command failed due to signal (use -v to see invocation)
      export XBB_IGNORE_TEST_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_GC_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_LTO_CRT_ADDER_SHARED="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_ADDER_SHARED="y"

      # adder-static.
      export XBB_IGNORE_TEST_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_GC_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_LTO_CRT_ADDER_STATIC="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_ADDER_STATIC="y"

      # atomic.
      export XBB_IGNORE_TEST_LTO_CRT_ATOMIC="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_ATOMIC="y"

      # cnrt-test.
      export XBB_IGNORE_TEST_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_GC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_CNRT_TEST="y"
      export XBB_IGNORE_TEST_LTO_CRT_CNRT_TEST="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_CNRT_TEST="y"

      # exception-locale.
      export XBB_IGNORE_TEST_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_LTO_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_CRT_LLD_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_CRT_LLD_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_LTO_CRT_LLD_EXCEPTION_LOCALE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LLD_EXCEPTION_LOCALE="y"

      # exception-reduced.
      # /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm/xpacks/.bin/ld: /tmp/exception-reduced-290bc9.o (symbol from plugin): Number of symbols in input file has increased from 0 to 1
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_STATIC_LTO_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_LTO_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_CRT_LLD_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_CRT_LLD_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_LTO_CRT_LLD_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LLD_EXCEPTION_REDUCED="y"

      # global-terminate.
      export XBB_IGNORE_TEST_LTO_CRT_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_STATIC_LTO_GLOBAL_TERMINATE="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_GLOBAL_TERMINATE="y"

      # hello-c.
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO1_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO1_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO1_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO1_C="y"

      # hello-c-one.
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"

      # hello-c-two.
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_HELLO_PRINTF_TWO="y"

      # hello-cpp.
      # clang++ hello-cpp.cpp -o lto-hello-cpp -flto -g -v
      # clang++: error: unable to execute command: Segmentation fault (core dumped)
      # clang++: error: linker command failed due to signal (use -v to see invocation)
      export XBB_IGNORE_TEST_LTO_HELLO2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_HELLO2_CPP="y"
      # export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_HELLO2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO2_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO2_CPP="y"

      # hello-exception.
      export XBB_IGNORE_TEST_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_CRT_LLD_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_CRT_LLD_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_LTO_CRT_LLD_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LLD_HELLO_EXCEPTION="y"

      # hello-weak-c.
      export XBB_IGNORE_TEST_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK1_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_WEAK1_C="y"

      # hello-weak-cpp.
      # clang++: error: unable to execute command: Segmentation fault (core dumped)
      # clang++: error: linker command failed due to signal (use -v to see invocation)
      export XBB_IGNORE_TEST_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK2_CPP="y"

      # longjmp-cleanup.
      # clang++ simple-exception.cpp -o lto-simple-exception -flto -g -v
      # clang++: error: unable to execute command: Segmentation fault (core dumped)
      # clang++: error: linker command failed due to signal (use -v to see invocation)
      export XBB_IGNORE_TEST_LTO_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_GC_LTO_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_LTO_CRT_LONGJMP_CLEANUP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_LONGJMP_CLEANUP="y"

      # normal.
      export XBB_IGNORE_TEST_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_GC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_NORMAL="y"
      export XBB_IGNORE_TEST_LTO_CRT_NORMAL="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_NORMAL="y"

      # simple-exception.
      # clang++ simple-exception.cpp -o lto-simple-exception -flto -g -v
      # clang++: error: unable to execute command: Segmentation fault (core dumped)
      # clang++: error: linker command failed due to signal (use -v to see
      export XBB_IGNORE_TEST_LTO_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_EXCEPTION="y"

      # simple-hello-printf-one.
      export XBB_IGNORE_TEST_LTO_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_GC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_HELLO_PRINTF_ONE="y"

      # simple-hello-printf-two.
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_HELLO_PRINTF_TWO="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_HELLO_PRINTF_TWO="y"

      # simple-int-exception.
      # /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm/xpacks/.bin/ld: /tmp/simple-int-exception-aef398.o (symbol from plugin): Number of symbols in input file has increased from 0 to 1
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_SIMPLE_INT_EXCEPTION="y"

      # simple-objc.
      export XBB_IGNORE_TEST_STATIC_LTO_SIMPLE_OBJC="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_OBJC="y"
      export XBB_IGNORE_TEST_LTO_CRT_SIMPLE_OBJC="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SIMPLE_OBJC="y"

      # simple-str-exception.
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SIMPLE_STR_EXCEPTION="y"

      # sleepy-threads.
      export XBB_IGNORE_TEST_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_GC_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_LTO_CRT_SLEEPY_THREADS_SL="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_SLEEPY_THREADS_SL="y"

      # sleepy-threads-cv.
      export XBB_IGNORE_TEST_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_GC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_LTO_LLD_SLEEPY_THREADS_CV="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_LLD_SLEEPY_THREADS_CV="y"

      # throwcatch-main.
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_LTO_CRT_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_THROWCATCH_MAIN="y"

      # unwind-strong-cpp.
      export XBB_IGNORE_TEST_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_UNWIND_STRONG_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_UNWIND_STRONG_CPP="y"

      # unwind-weak-cpp.
      export XBB_IGNORE_TEST_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_LTO_CRT_UNWIND_WEAK_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_UNWIND_WEAK_CPP="y"

      # weak-undef-c.
      export XBB_IGNORE_TEST_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_UNDEF_C="y"

      # weak-defined-c.
      export XBB_IGNORE_TEST_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_DEFINED_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_DEFINED_C="y"

      # weak-duplicate-c.
      export XBB_IGNORE_TEST_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_DUPLICATE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_DUPLICATE_C="y"

      # weak-override-c.
      export XBB_IGNORE_TEST_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_OVERRIDE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_OVERRIDE_C="y"

      # weak-use-c.
      export XBB_IGNORE_TEST_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_LTO_CRT_WEAK_USE_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_USE_C="y"
    fi

    if [[ ${distro} == CentOS ]] || \
       [[ ${distro} == RedHat* ]] || \
       [[ ${distro} == Fedora ]] || \
       [[ ${distro} == openSUSE ]] || \
       [[ ${distro} == Arch ]]
    then
      export XBB_SKIP_TEST_ALL_STATIC_ATOMIC="y"
    fi
  fi

  # It is mandatory for the compiler to run properly without any
  # explicit libraries or other options, otherwise tools used
  # during configuration (like meson) might fail probing for
  # capabilities.
  test_compiler_c_cpp

  # aarch64 multilib not yet available
  # if [ "${XBB_HOST_BITS}" == "64" ]
  if [ "${XBB_HOST_ARCH}" == "x64" ]
  then
    # x64 with multilib. Two runs, -m64 & -m32.

    for bits in 32 64
    do
      (
        if [ ${bits} -eq 32 ]
        then
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
            continue
          fi
        fi

        # ---------------------------------------------------------------------
        # First test using the system GCC runtime and libstdc++.

        test_compiler_c_cpp --${bits}
        test_compiler_c_cpp --${bits} --gc
        test_compiler_c_cpp --${bits} --lto
        test_compiler_c_cpp --${bits} --gc --lto

        # Again with lld.
        test_compiler_c_cpp --${bits} --lld
        test_compiler_c_cpp --${bits} --gc --lld
        test_compiler_c_cpp --${bits} --lto --lld
        test_compiler_c_cpp --${bits} --gc --lto --lld

        # -static-libgcc -static-libgcc.
        test_compiler_c_cpp --${bits} --static-lib
        test_compiler_c_cpp --${bits} --gc --static-lib
        test_compiler_c_cpp --${bits} --lto --static-lib
        test_compiler_c_cpp --${bits} --gc --lto --static-lib

        # Again with lld.
        test_compiler_c_cpp --${bits} --lld --static-lib
        test_compiler_c_cpp --${bits} --gc --lld --static-lib
        test_compiler_c_cpp --${bits} --lto --lld --static-lib
        test_compiler_c_cpp --${bits} --gc --lto --lld --static-lib

        if [[ ${distro} == Arch ]]
        then
          # Arch: undefined reference to `fmod' (static)
          # Arch: cannot find -latomic (static)
          echo
          echo "Skipping all static on ${distro}..."
        else
          # -static.
          test_compiler_c_cpp --${bits} --static
          test_compiler_c_cpp --${bits} --gc --static
          test_compiler_c_cpp --${bits} --lto --static
          test_compiler_c_cpp --${bits} --gc --lto --static

          # Again with lld.
          test_compiler_c_cpp --${bits} --lld --static
          test_compiler_c_cpp --${bits} --gc --lld --static
          test_compiler_c_cpp --${bits} --lto --lld --static
          test_compiler_c_cpp --${bits} --gc --lto --lld --static
        fi

        # ---------------------------------------------------------------------
        # Second test LLVM runtime and libc++.

        (
          # The shared libraries are in a custom location and require setting
          # the path explicitly.

          local toolchain_library_path="$(xbb_get_toolchain_library_path "${CXX}" -m${bits})"
          LDFLAGS+=" $(xbb_expand_linker_library_paths "${toolchain_library_path}")"
          export LDFLAGS+=" $(xbb_expand_linker_rpaths "${toolchain_library_path}")"
          LDXXFLAGS+=" $(xbb_expand_linker_library_paths "${toolchain_library_path}")"
          export LDXXFLAGS+=" $(xbb_expand_linker_rpaths "${toolchain_library_path}")"
          echo
          echo "LDFLAGS=${LDFLAGS}"

          # With compiler-rt.
          test_compiler_c_cpp --${bits} --crt --libunwind
          test_compiler_c_cpp --${bits} --gc --crt --libunwind
          test_compiler_c_cpp --${bits} --lto --crt --libunwind
          test_compiler_c_cpp --${bits} --gc --lto --crt --libunwind

          # Again with lld.
          test_compiler_c_cpp --${bits} --crt --libunwind --lld
          test_compiler_c_cpp --${bits} --gc --crt --libunwind --lld
          test_compiler_c_cpp --${bits} --lto --crt --libunwind --lld
          test_compiler_c_cpp --${bits} --gc --lto --crt --libunwind --lld

          # With compiler-rt & libc++.
          test_compiler_c_cpp --${bits} --libc++ --crt --libunwind
          test_compiler_c_cpp --${bits} --gc --libc++ --crt --libunwind
          test_compiler_c_cpp --${bits} --lto --libc++ --crt --libunwind
          test_compiler_c_cpp --${bits} --gc --lto --libc++ --crt --libunwind

          # Again with lld.
          test_compiler_c_cpp --${bits} --libc++ --crt --libunwind --lld
          test_compiler_c_cpp --${bits} --gc --libc++ --crt --libunwind --lld
          test_compiler_c_cpp --${bits} --lto --libc++ --crt --libunwind --lld
          test_compiler_c_cpp --${bits} --gc --lto --libc++ --crt --libunwind --lld
        )

        if false
        then
          # -static-libgcc -static-libgcc.
          # This combination seems not supported.

          # clang++: warning: argument unused during compilation: '-static-libgcc'

          # /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm64/xpacks/.bin/ld: /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm64/application/bin/../lib/aarch64-unknown-linux-gnu/libc++.a(iostream.cpp.o): in function `std::__1::ios_base::Init::Init()':
          # iostream.cpp:(.text._ZNSt3__18ios_base4InitC2Ev+0x30): undefined reference to `__cxa_guard_acquire'

          # With compiler-rt & libc++.
          test_compiler_c_cpp --${bits} --libc++ --crt --libunwind --static-lib
          test_compiler_c_cpp --${bits} --gc --libc++ --crt --libunwind --static-lib
          test_compiler_c_cpp --${bits} --lto --lld --libc++ --crt --libunwind --static-lib
          test_compiler_c_cpp --${bits} --gc --lto --lld --libc++ --crt --libunwind --static-lib

          # Again with lld.
          test_compiler_c_cpp --${bits} --libc++ --crt --libunwind --lld --static-lib
          test_compiler_c_cpp --${bits} --gc --libc++ --crt --libunwind --lld --static-lib
          test_compiler_c_cpp --${bits} --lto --libc++ --crt --libunwind --lld --static-lib
          test_compiler_c_cpp --${bits} --gc --lto --libc++ --crt --libunwind --lld --static-lib
        fi

        if false
        then
          # -static.
          # This combination also seems not supported.

          # With compiler-rt & libc++.
          test_compiler_c_cpp --${bits} --libc++ --crt --libunwind --static
          test_compiler_c_cpp --${bits} --gc --libc++ --crt --libunwind --static
          test_compiler_c_cpp --${bits} --lto --lld --libc++ --crt --libunwind --static
          test_compiler_c_cpp --${bits} --gc --lto --lld --libc++ --crt --libunwind --static

          # Again with lld.
          test_compiler_c_cpp --${bits} --libc++ --crt --libunwind --lld --static
          test_compiler_c_cpp --${bits} --gc --libc++ --crt --libunwind --lld --static
          test_compiler_c_cpp --${bits} --lto --libc++ --crt --libunwind --lld --static
          test_compiler_c_cpp --${bits} --gc --lto --libc++ --crt --libunwind --lld --static
        fi
      )
    done

  else
    # arm & aarch64, non-multilib, no explicit -m32/-m64.

    # ---------------------------------------------------------------------
    # First test using the system GCC runtime and libstdc++.

    # test_compiler_c_cpp # Already done.
    test_compiler_c_cpp --gc
    test_compiler_c_cpp --lto
    test_compiler_c_cpp --gc --lto

    # Again with lld.
    test_compiler_c_cpp --lld
    test_compiler_c_cpp --gc --lld
    test_compiler_c_cpp --lto --lld
    test_compiler_c_cpp --gc --lto --lld

    # -static-libgcc -static-libgcc.
    # WARNING: check if they run on RH!
    test_compiler_c_cpp --static-lib
    test_compiler_c_cpp --gc --static-lib
    test_compiler_c_cpp --lto --static-lib
    test_compiler_c_cpp --gc --lto --static-lib

    # Again with lld.
    test_compiler_c_cpp --lld --static-lib
    test_compiler_c_cpp --gc --lld --static-lib
    test_compiler_c_cpp --lto --lld --static-lib
    test_compiler_c_cpp --gc --lto --lld --static-lib

    # -static.
    test_compiler_c_cpp --static
    test_compiler_c_cpp --gc --static
    test_compiler_c_cpp --lto --static
    test_compiler_c_cpp --gc --lto --static

    # Again with lld.
    test_compiler_c_cpp --lld --static
    test_compiler_c_cpp --gc --lld --static
    test_compiler_c_cpp --lto --lld --static
    test_compiler_c_cpp --gc --lto --lld --static

    # ---------------------------------------------------------------------
    # Second test LLVM runtime and libc++.

    (
      # The shared libraries are in a custom location and require setting
      # the path explicitly.
      local toolchain_library_path="$(xbb_get_toolchain_library_path "${CXX}")"
      export LDFLAGS+=" $(xbb_expand_linker_rpaths "${toolchain_library_path}")"
      export LDXXFLAGS+=" $(xbb_expand_linker_rpaths "${toolchain_library_path}")"
      echo
      echo "LDFLAGS=${LDFLAGS}"

      # The Linux system linker may fail with -flto, use the included lld.
      # For example, on Raspberry Pi OS 32-bit:
      # error: unable to execute command: Segmentation fault (core dumped)

      # With compiler-rt.
      test_compiler_c_cpp --crt --libunwind
      test_compiler_c_cpp --gc --crt --libunwind
      test_compiler_c_cpp --lto --crt --libunwind
      test_compiler_c_cpp --gc --lto --crt --libunwind

      # Again with lld.
      test_compiler_c_cpp --crt --libunwind --lld
      test_compiler_c_cpp --gc --crt --libunwind --lld
      test_compiler_c_cpp --lto --crt --libunwind --lld
      test_compiler_c_cpp --gc --lto --crt --libunwind --lld

      # With compiler-rt & libc++.
      test_compiler_c_cpp --libc++ --crt --libunwind
      test_compiler_c_cpp --gc --libc++ --crt --libunwind
      test_compiler_c_cpp --lto --lld --libc++ --crt --libunwind
      test_compiler_c_cpp --gc --lto --lld --libc++ --crt --libunwind

      # Again with lld.
      test_compiler_c_cpp --libc++ --crt --libunwind --lld
      test_compiler_c_cpp --gc --libc++ --crt --libunwind --lld
      test_compiler_c_cpp --lto --libc++ --crt --libunwind --lld
      test_compiler_c_cpp --gc --lto --libc++ --crt --libunwind --lld
    )

    if false
    then
      # -static-libgcc -static-libgcc.
      # This combination seems not supported.

      # clang++: warning: argument unused during compilation: '-static-libgcc'

      # /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm64/xpacks/.bin/ld: /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm64/application/bin/../lib/aarch64-unknown-linux-gnu/libc++.a(iostream.cpp.o): in function `std::__1::ios_base::Init::Init()':
      # iostream.cpp:(.text._ZNSt3__18ios_base4InitC2Ev+0x30): undefined reference to `__cxa_guard_acquire'

      # With compiler-rt & libc++.
      test_compiler_c_cpp --libc++ --crt --libunwind --static-lib
      test_compiler_c_cpp --gc --libc++ --crt --libunwind --static-lib
      test_compiler_c_cpp --lto --lld --libc++ --crt --libunwind --static-lib
      test_compiler_c_cpp --gc --lto --lld --libc++ --crt --libunwind --static-lib

      # Again with lld.
      test_compiler_c_cpp --libc++ --crt --libunwind --lld --static-lib
      test_compiler_c_cpp --gc --libc++ --crt --libunwind --lld --static-lib
      test_compiler_c_cpp --lto --libc++ --crt --libunwind --lld --static-lib
      test_compiler_c_cpp --gc --lto --libc++ --crt --libunwind --lld --static-lib
    fi

    if false
    then
      # -static.
      # This combination also seems not supported.

      # With compiler-rt & libc++.
      test_compiler_c_cpp --libc++ --crt --libunwind --static
      test_compiler_c_cpp --gc --libc++ --crt --libunwind --static
      test_compiler_c_cpp --lto --lld --libc++ --crt --libunwind --static
      test_compiler_c_cpp --gc --lto --lld --libc++ --crt --libunwind --static

      # Again with lld.
      test_compiler_c_cpp --libc++ --crt --libunwind --lld --static
      test_compiler_c_cpp --gc --libc++ --crt --libunwind --lld --static
      test_compiler_c_cpp --lto --libc++ --crt --libunwind --lld --static
      test_compiler_c_cpp --gc --lto --libc++ --crt --libunwind --lld --static
    fi
  fi
}

# -----------------------------------------------------------------------------

function test_darwin()
{
  if false
  then
    touch sdk-check.cpp

    local first_path="$(run_host_app ${CXX} -v sdk-check.cpp -c 2>&1| grep -E '^ ' | grep  -E '^ /' | sed -e '2,$d')"
    if echo ${first_path} | grep MacOSX.sdk
    then
      echo "MacOSX.sdk test failed"
      exit 1
    fi
  fi

  show_host_libs "$(dirname $(dirname ${CXX}))/lib/libc++.dylib"

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

  # throwcatch-main with -flto fails to run on Intel.
  # Reproducible with the system compiler/linker too.

  # Does not identify the custom exceptions:
  # [./lto-throwcatch-main ]
  # not throwing
  # throwing FirstException
  # caught std::exception <-- instead of FirstException
  # caught unexpected exception 3!
  # throwing SecondException
  # caught std::exception <-- instead of SecondException
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

  # The clang version on macOS 10.14 is 4.
  if [ ${LLVM_VERSION_MAJOR} -eq 4 ] || \
     [ ${LLVM_VERSION_MAJOR} -eq 10 ] || \
     [ ${LLVM_VERSION_MAJOR} -eq 11 ] || \
     [ ${LLVM_VERSION_MAJOR} -eq 12 ]
  then
    if [ "${XBB_TARGET_ARCH}" == "x64" ]
    then
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"
    fi
  elif [ ${LLVM_VERSION_MAJOR} -eq 13 ] || \
       [ ${LLVM_VERSION_MAJOR} -eq 14 ] || \
       [ ${LLVM_VERSION_MAJOR} -eq 15 ]
  then
    if [ "${XBB_TARGET_ARCH}" == "x64" ]
    then
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"

      export XBB_IGNORE_TEST_LTO_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_LLD_THROWCATCH_MAIN="y"
    fi
  elif [ ${LLVM_VERSION_MAJOR} -eq 16 ]
  then
    if [ "${XBB_TARGET_ARCH}" == "x64" ]
    then
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"

      export XBB_IGNORE_TEST_LTO_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_LLD_THROWCATCH_MAIN="y"
    elif [ "${XBB_TARGET_ARCH}" == "arm64" ]
    then
      # 6083 Trace/BPT trap: 5
      # exception-reduced.
      export XBB_IGNORE_TEST_GC_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_LTO_EXCEPTION_REDUCED="y"
      export XBB_IGNORE_TEST_GC_LTO_EXCEPTION_REDUCED="y"

      # 6141 Trace/BPT trap: 5
      # hello-exception.
      export XBB_IGNORE_TEST_GC_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_LTO_HELLO_EXCEPTION="y"
      export XBB_IGNORE_TEST_GC_LTO_HELLO_EXCEPTION="y"
    fi
  elif [ ${LLVM_VERSION_MAJOR} -eq 17 ]
  then

    # x64
    # 14 test(s) failed:
    #
    # fail: weak-undef-c
    # fail: gc-weak-undef-c
    # fail: lto-weak-undef-c
    # fail: lto-throwcatch-main
    # fail: gc-lto-weak-undef-c
    # fail: gc-lto-throwcatch-main
    # fail: lld-weak-undef-c
    # fail: lld-throwcatch-main
    # fail: gc-lld-weak-undef-c
    # fail: gc-lld-throwcatch-main
    # fail: lto-lld-weak-undef-c
    # fail: lto-lld-throwcatch-main
    # fail: gc-lto-lld-weak-undef-c
    # fail: gc-lto-lld-throwcatch-main

    # arm64
    # 8 test(s) failed:
    #
    # fail: weak-undef-c
    # fail: gc-weak-undef-c
    # fail: lto-weak-undef-c
    # fail: gc-lto-weak-undef-c
    # fail: lld-weak-undef-c
    # fail: gc-lld-weak-undef-c
    # fail: lto-lld-weak-undef-c
    # fail: gc-lto-lld-weak-undef-c

    # exception-reduced.
    export XBB_IGNORE_TEST_GC_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_LTO_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_GC_LTO_EXCEPTION_REDUCED="y"

    # hello-exception.
    export XBB_IGNORE_TEST_GC_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_LTO_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_GC_LTO_HELLO_EXCEPTION="y"

    # weak-undef-c.
    # Undefined symbols for architecture x86_64:
    #   "_func", referenced from:
    export XBB_IGNORE_TEST_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LTO_WEAK_UNDEF_C="y"

    # ld64.lld: error: undefined symbol: func
    export XBB_IGNORE_TEST_LLD_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LLD_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_LTO_LLD_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LTO_LLD_WEAK_UNDEF_C="y"

    if [ "${XBB_HOST_ARCH}" == "x64" ]
    then
      # throwcatch-main.
      # Non LTO & non LLD are ok!
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_LTO_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_LLD_THROWCATCH_MAIN="y"
    fi

  elif [ ${LLVM_VERSION_MAJOR} -eq 18 ]
  then
    # weak-undef-c.
    # Most likely an incompatibility with the Apple linker.
    # Static tests pass.
    # Undefined symbols for architecture x86_64:
    #   "_func", referenced from:
    export XBB_IGNORE_TEST_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_LTO_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LTO_WEAK_UNDEF_C="y"

    export XBB_IGNORE_TEST_LLD_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LLD_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_LTO_LLD_WEAK_UNDEF_C="y"
    export XBB_IGNORE_TEST_GC_LTO_LLD_WEAK_UNDEF_C="y"

    # hello-exception.
    # on macOS 10.14 and 11.7
    export XBB_IGNORE_TEST_GC_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_LTO_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_GC_LTO_HELLO_EXCEPTION="y"
    # Segmentation fault: 11 on macOS 10.14 and macOS 11.6
    export XBB_IGNORE_TEST_LLD_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_GC_LLD_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_LTO_LLD_HELLO_EXCEPTION="y"
    export XBB_IGNORE_TEST_GC_LTO_LLD_HELLO_EXCEPTION="y"

    # exceptions-reduced.
    # Segmentation fault: 11 on macOS 10.14
    export XBB_IGNORE_TEST_GC_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_LTO_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_GC_LTO_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_LLD_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_GC_LLD_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_LTO_LLD_EXCEPTION_REDUCED="y"
    export XBB_IGNORE_TEST_GC_LTO_LLD_EXCEPTION_REDUCED="y"

    if [ "${XBB_HOST_ARCH}" == "x64" ]
    then
      # throwcatch-main.
      # got exit code: 1 on macOS 10.14 & macOS 14
      export XBB_IGNORE_TEST_LTO_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_THROWCATCH_MAIN="y"

      # got exit code: 1 on macOS 10.14
      export XBB_IGNORE_TEST_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_LTO_LLD_THROWCATCH_MAIN="y"
      export XBB_IGNORE_TEST_GC_LTO_LLD_THROWCATCH_MAIN="y"
    fi
  fi

  # It is mandatory for the compiler to run properly without any
  # explicit libraries or other options, otherwise tools used
  # during configuration (like meson) might fail probing for
  # capabilities.
  # However this is not usable, since it uses the new headers
  # with the system libraries.
  test_compiler_c_cpp

  (
    # The shared libraries are in a custom location and require setting
    # the libraries and rpath explicitly.

    local toolchain_library_path="$(xbb_get_toolchain_library_path "${CXX}")"

    LDFLAGS+=" $(xbb_expand_linker_library_paths "${toolchain_library_path}")"
    LDFLAGS+=" $(xbb_expand_linker_rpaths "${toolchain_library_path}")"

    LDXXFLAGS+=" $(xbb_expand_linker_library_paths "${toolchain_library_path}")"
    LDXXFLAGS+=" $(xbb_expand_linker_rpaths "${toolchain_library_path}")"

    export LDFLAGS
    export LDXXFLAGS

    echo
    echo "LDFLAGS=${LDFLAGS}"

    # Again, with various options.
    test_compiler_c_cpp --gc
    test_compiler_c_cpp --lto
    test_compiler_c_cpp --gc --lto

    # No need for compiler-rt or libc++, they are the defaults.

    # `lld` is not present in macOS SDK.
    if [ ! -z "${LLD}" ]
    then
      # Again with lld.
      test_compiler_c_cpp --lld
      test_compiler_c_cpp --gc --lld
      test_compiler_c_cpp --lto --lld
      test_compiler_c_cpp --gc --lto --lld
    fi
  )

  # ld: library not found for -lcrt0.o
  # test_compiler_c_cpp --static

  # ld64.lld: warning: Option `-static' is not yet implemented. Stay tuned...
  # ld64.lld: error: library not found for -lcrt0.o
  # ld64.lld: error: undefined symbol: printf

  # test_compiler_c_cpp --static --lld
}

# -----------------------------------------------------------------------------

function test_case_clangd_hello()
{
  local test_case_name="$(test_case_get_name)"

  local prefix=${PREFIX:-""}
  local suffix=${SUFFIX:-""}

  (
    trap 'test_case_trap_handler ${test_case_name} $? $LINENO; return 0' ERR

    # Note: __EOF__ is quoted to prevent substitutions here.
    cat <<'__EOF__' > "clangd-hello.cpp"
#include <iostream>

class Hello {
public:
    Hello() {
        printf("Hello ctor\n");
    }
    ~Hello() {
        printf("Hello dtor\n");
    }
};

Hello global_h;

__attribute__((constructor)) static void attr_ctor(void) {
    printf("attr_ctor\n");
}

__attribute__((destructor)) static void attr_dtor(void) {
    printf("attr_dtor\n");
}

int main(int argc, char* argv[]) {
    std::cout<<"Hello world C++"<<std::endl;
    return 0;
}
__EOF__

    # Note: __EOF__ is NOT quoted to allow substitutions here.
    cat <<__EOF__ > "compile_commands.json"
[
  {
    "directory": "$(pwd)",
    "command": "${CXX} -c clangd-hello.cpp",
    "file": "clangd-hello.cpp"
  }
]
__EOF__

    cat "compile_commands.json"

    run_host_app_verbose "${CLANGD}" --check="clangd-hello.cpp"

    test_case_pass "${test_case_name}"
  ) 2>&1 | tee "${XBB_TEST_RESULTS_FOLDER_PATH}/${prefix}${test_case_name}${suffix}.txt"
}


function test_case_clangd_unchecked_exception()
{
  local test_case_name="$(test_case_get_name)"

  local prefix=${PREFIX:-""}
  local suffix=${SUFFIX:-""}

  (
    trap 'test_case_trap_handler ${test_case_name} $? $LINENO; return 0' ERR

    # Note: __EOF__ is quoted to prevent substitutions here.
    cat <<'__EOF__' > "clangd-unchecked-exception.cpp"
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
    "command": "${CXX} -c clangd-unchecked-exception.cpp",
    "file": "clangd-unchecked-exception.cpp"
  }
]
__EOF__

    cat "compile_commands.json"

    run_host_app_verbose "${CLANGD}" --check="clangd-unchecked-exception.cpp"

    test_case_pass "${test_case_name}"
  ) 2>&1 | tee "${XBB_TEST_RESULTS_FOLDER_PATH}/${prefix}${test_case_name}${suffix}.txt"
}

# -----------------------------------------------------------------------------

function strip_libs()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  if with_strip
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
