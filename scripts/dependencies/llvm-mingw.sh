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

function build_mingw_llvm_first()
{
  export ACTUAL_LLVM_VERSION="$1"
  shift

  local llvm_version_major=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')
  local llvm_version_minor=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')

  export llvm_src_folder_name="llvm-project-${ACTUAL_LLVM_VERSION}.src"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${ACTUAL_LLVM_VERSION}/${llvm_archive}"

  local llvm_folder_name="mingw-w64-llvm-${ACTUAL_LLVM_VERSION}-first"

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

      # Use install/libs/lib & include
      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # Non-static will have trouble to find the llvm bootstrap libc++.
      # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      LDFLAGS="${XBB_LDFLAGS_APP}"
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
          echo "Running mingw-64-llvm-first cmake..."

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
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")

          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}")
          config_options+=("-DCMAKE_C_COMPILER=${CC}")

          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")

          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          # Please note the trailing space.
          config_options+=("-DCLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DFLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DLLD_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DPACKAGE_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")

          config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF")
          config_options+=("-DLLDB_INCLUDE_TESTS=OFF")


          # Mind the links in llvm to clang, lld, lldb.
          config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")
          config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
          config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres")


          # https://llvm.org/docs/BuildingADistribution.html#options-for-reducing-size
          # This option is not available on Windows
          # config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
          # config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")

          # compiler-rt, libunwind, libc++ and libc++-abi are built
          # in separate steps intertwined with mingw.


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
        echo "Running mingw-w64-llvm-first build..."

        if [ "${XBB_IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake --build . --verbose
          run_verbose cmake --build .  --verbose  --target install/strip
        else
          run_verbose_timed cmake --build .
          run_verbose cmake --build . --target install/strip
        fi


        show_host_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/clang"
        show_host_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/llvm-nm"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}/build-output-$(ndate).txt"

      copy_license \
        "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm" \
        "${llvm_folder_name}"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_stamp_file_path}"

  else
    echo "Component mingw-w64-llvm-first already installed."
  fi
}

# $1="${XBB_BOOTSTRAP_SUFFIX}"
function build_mingw_llvm_compiler_rt()
{
  local llvm_compiler_rt_folder_name="mingw-w64-llvm-${ACTUAL_LLVM_VERSION}-compiler-rt"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

  local llvm_compiler_rt_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_compiler_rt_folder_name}-installed"
  if [ ! -f "${llvm_compiler_rt_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS}"

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      (
        xbb_show_env_develop

        echo
        echo "Running llvm-compiler-rt cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}")
        else
          # Traditionally the runtime is in a versioned folder.
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        # config_options+=("-DCMAKE_C_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang")
        config_options+=("-DCMAKE_C_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang)")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        # config_options+=("-DCMAKE_CXX_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang++)")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        # config_options+=("-DCMAKE_AR=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_AR=$(which llvm-ar)")
        # config_options+=("-DCMAKE_RANLIB=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")
        config_options+=("-DCMAKE_RANLIB=$(which llvm-ranlib)")

        if [ "${XBB_HOST_MACHINE}" == "x86_64" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=x86_64-windows-gnu")
        elif [ "${XBB_HOST_MACHINE}" == "i686" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=i386-windows-gnu")
        else
          echo "Unsupported XBB_HOST_MACHINE=${XBB_HOST_MACHINE} in ${FUNCNAME[0]}()"
          exit 1
        fi

        config_options+=("-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON")
        config_options+=("-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON")
        config_options+=("-DSANITIZER_CXX_ABI=libc++")

        config_options+=("-DZLIB_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          # Otherwise it'll generate two -mmacosx-version-min
          config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
        fi

        # Do not activate it, it fails. And be sure llvm-config is not in the PATH.
        # config_options+=("-DLLVM_CONFIG_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-config")

        run_verbose cmake \
          "${config_options[@]}" \
          "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/compiler-rt/lib/builtins"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/cmake-output-$(ndate).txt"

      (
        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

        if true # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          mkdir -pv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/windows"
          for i in lib/windows/libclang_rt.*.a
          do
              cp -v $i "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/windows/$(basename $i)"
          done

          mkdir -pv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}/bin"
          for i in lib/windows/libclang_rt.*.dll
          do
              if [ -f $i ]
              then
                  cp -v $i "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}/bin"
              fi
          done
        fi

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/build-output-$(ndate).txt"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_compiler_rt_stamp_file_path}"

  else
    echo "Component mingw-w64-llvm-compiler-rt already installed."
  fi

}

function build_mingw_llvm_libcxx()
{
  local llvm_libunwind_folder_name="mingw-w64-llvm-${ACTUAL_LLVM_VERSION}-libunwind"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}"

  local llvm_libunwind_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_libunwind_folder_name}-installed"
  if [ ! -f "${llvm_libunwind_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libunwind_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_libunwind_folder_name}"

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
        xbb_show_env_develop

        echo
        echo "Running mingw-w64-llvm-libunwind cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}")
        else
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

  if false
  then
        config_options+=("-DCMAKE_C_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")
  else
        config_options+=("-DCMAKE_C_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang)")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang++)")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=$(which llvm-ar)")
        config_options+=("-DCMAKE_RANLIB=$(which llvm-ranlib)")
  fi
        config_options+=("-DLIBUNWIND_ENABLE_THREADS=ON")
        config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")
        config_options+=("-DLIBUNWIND_ENABLE_STATIC=ON")
        config_options+=("-DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF")
        config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON")

        # When compiling the bootstrap, the compiler is not yet fully functional.
        config_options+=("-DLLVM_COMPILER_CHECKED=ON")
        config_options+=("-DLLVM_PATH=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          # Otherwise it'll generate two -mmacosx-version-min
          config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
        fi

        run_verbose cmake \
          "${config_options[@]}" \
          "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libunwind"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}/cmake-output-$(ndate).txt"

      (
        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}/build-output-$(ndate).txt"

    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_libunwind_stamp_file_path}"

  else
    echo "Component mingw-w64-llvm-libunwind already installed."
  fi

  # ---------------------------------------------------------------------------

  # Define & prepare the folder, will be used later.
  local llvm_libcxxabi_folder_name="mingw-w64-llvm-${ACTUAL_LLVM_VERSION}-libcxxabi"
  mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

  local llvm_libcxx_folder_name="mingw-w64-llvm-${ACTUAL_LLVM_VERSION}-libcxx"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}"

  local llvm_libcxx_headers_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-headers-installed"
  if [ ! -f "${llvm_libcxx_headers_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

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
        xbb_show_env_develop

        echo
        echo "Running mingw-w64-llvm-libcxx-headers cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}")
        else
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

  if false
  then
        config_options+=("-DCMAKE_C_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")
  else
        config_options+=("-DCMAKE_C_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang)")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang++)")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=$(which llvm-ar)")
        config_options+=("-DCMAKE_RANLIB=$(which llvm-ranlib)")
  fi

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
        config_options+=("-DLIBCXX_CXX_ABI_INCLUDE_PATHS=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxxabi/include")
        config_options+=("-DLIBCXX_CXX_ABI_LIBRARY_PATH=${XBB_BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/lib")
        config_options+=("-DLIBCXX_LIBDIR_SUFFIX=")
        config_options+=("-DLIBCXX_INCLUDE_TESTS=OFF")
        config_options+=("-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF")
        config_options+=("-DLIBCXX_USE_COMPILER_RT=ON")

        config_options+=("-DLLVM_PATH=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          # Otherwise it'll generate two -mmacosx-version-min
          config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
        fi

        run_verbose cmake \
          "${config_options[@]}" \
          "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxx"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/cmake-output-$(ndate).txt"

      (
        # Configure, but don't build libcxx yet, so that libcxxabi has
        # proper headers to refer to.
        run_verbose cmake --build . --verbose --target generate-cxx-headers

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/generate-cxx-headeres-output-$(ndate).txt"

    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_libcxx_headers_stamp_file_path}"

  else
    echo "Component mingw-w64-llvm-libcxx-headers already installed."
  fi

  local llvm_libcxxabi_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_libcxxabi_folder_name}-installed"
  if [ ! -f "${llvm_libcxxabi_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

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
        xbb_show_env_develop

        echo
        echo "Running mingw-w64-llvm-libcxxabi cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}")
        else
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")
        fi

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

  if false
  then
        config_options+=("-DCMAKE_C_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/${XBB_TARGET_TRIPLET}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ranlib")
  else
        config_options+=("-DCMAKE_C_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang)")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=$(which ${XBB_TARGET_TRIPLET}-clang++)")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=$(which llvm-ar)")
        config_options+=("-DCMAKE_RANLIB=$(which llvm-ranlib)")
  fi

        config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON")
        config_options+=("-DLIBCXXABI_ENABLE_EXCEPTIONS=ON")
        config_options+=("-DLIBCXXABI_ENABLE_THREADS=ON")
        config_options+=("-DLIBCXXABI_TARGET_TRIPLE=${XBB_TARGET_TRIPLET}")
        config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF")
        config_options+=("-DLIBCXXABI_LIBCXX_INCLUDES=${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}/include/c++/v1")
        config_options+=("-DLIBCXXABI_LIBDIR_SUFFIX=")
        config_options+=("-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=ON")

        config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")
        config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON")

        config_options+=("-DLLVM_PATH=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          # Otherwise it'll generate two -mmacosx-version-min
          config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
        fi

        run_verbose cmake \
          "${config_options[@]}" \
          "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxxabi"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/cmake-output-$(ndate).txt"

      (
        # Configure, but don't build libcxxabi yet, so that libcxxabi has
        # proper headers to refer to.
        run_verbose cmake --build . --verbose

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/build-output-$(ndate).txt"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_libcxxabi_stamp_file_path}"

  else
    echo "Component mingw-w64-llvm-libcxxabi already installed."
  fi

  local llvm_libcxx_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-installed"
  if [ ! -f "${llvm_libcxx_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

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
        xbb_show_env_develop

        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

        # Append libunwind to libc++.
        if false # [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        then
          run_verbose "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-ar" qcsL \
                  "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}/lib/libc++.a" \
                  "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}/lib/libunwind.a"
        else
          run_verbose "$(which llvm-ar)" qcsL \
                  "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/libc++.a" \
                  "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/libunwind.a"


        fi

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/build-output-$(ndate).txt"

    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_libcxx_stamp_file_path}"

  else
    echo "Component mingw-w64-llvm-libcxx already installed."
  fi

  tests_add "test_llvm_mingw" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
}

# -----------------------------------------------------------------------------

function test_llvm_mingw()
{
  local test_bin_path="$1"
  shift

  local triplet="x86_64-w64-mingw32"
  local name_prefix=""
  local name_suffix=""
  local is_bootstrap="n"

  while [ $# -gt 0 ]
  do
    case "$1" in
      --triplet=* )
        triplet=$(xbb_parse_option "$1")
        ;;

      --bootstrap )
        is_bootstrap="y"
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
    shift
  done

  name_prefix="${triplet}-"

  echo
  echo "Testing the ${name_prefix}llvm binaries..."

  (
    run_verbose ls -l "${test_bin_path}"

    # Help the loader find the .dll files if the native is not static.
    # export WINEPATH=${test_bin_path}/${triplet}/bin

    CC="${test_bin_path}/${triplet}-clang"
    CXX="${test_bin_path}/${triplet}-clang++"
    DLLTOOL="${test_bin_path}/${triplet}-dlltool"
    WIDL="${test_bin_path}/${triplet}-widl"
    GENDEF="${test_bin_path}/gendef"
    AR="${test_bin_path}/${triplet}-ar"
    RANLIB="${test_bin_path}/${triplet}-ranlib"

    show_host_libs "${test_bin_path}/clang"
    show_host_libs "${test_bin_path}/lld"
    if [ -f "${test_bin_path}/lldb" ]
    then
      # lldb not available on Ubuntu 16 Arm.
      show_host_libs "${test_bin_path}/lldb"
    fi

    echo
    echo "Testing if the ${name_prefix}llvm binaries start properly..."

    run_app "${CC}" --version
    run_app "${CXX}" --version

    if [ -f "${test_bin_path}/clang-format${XBB_HOST_DOT_EXE}" ]
    then
      run_app "${test_bin_path}/clang-format" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    # run_app "${test_bin_path}/lld" --version || true

    run_app "${test_bin_path}/llvm-ar" --version
    run_app "${test_bin_path}/llvm-nm" --version
    run_app "${test_bin_path}/llvm-objcopy" --version
    run_app "${test_bin_path}/llvm-objdump" --version
    run_app "${test_bin_path}/llvm-ranlib" --version
    if [ -f "${test_bin_path}/llvm-readelf" ]
    then
      run_app "${test_bin_path}/llvm-readelf" --version
    fi
    if [ -f "${test_bin_path}/llvm-size" ]
    then
      run_app "${test_bin_path}/llvm-size" --version
    fi
    run_app "${test_bin_path}/llvm-strings" --version
    run_app "${test_bin_path}/llvm-strip" --version

    echo
    echo "Testing ${name_prefix}clang configuration..."

    run_app "${test_bin_path}/clang" -print-target-triple
    run_app "${test_bin_path}/clang" -print-targets
    run_app "${test_bin_path}/clang" -print-supported-cpus
    run_app "${test_bin_path}/clang" -print-search-dirs
    run_app "${test_bin_path}/clang" -print-resource-dir
    run_app "${test_bin_path}/clang" -print-libgcc-file-name

    # run_app "${test_bin_path}/llvm-config" --help

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

    local VERBOSE_FLAG=""
    if [ "${XBB_IS_DEVELOP}" == "y" ]
    then
      VERBOSE_FLAG="-v"
    fi

    LD_GC_SECTIONS=""

    xbb_show_env_develop

    run_verbose uname

    # -------------------------------------------------------------------------

    # `-fuse-ld=lld` fails on macOS:
    # ld64.lld: warning: ignoring unknown argument: -no_deduplicate
    # ld64.lld: warning: -sdk_version is required when emitting min version load command.  Setting sdk version to match provided min version
    # For now use the system linker /usr/bin/ld.

    # -static-libstdc++ not available on macOS:
    # clang-11: warning: argument unused during compilation: '-static-libstdc++'

    # -------------------------------------------------------------------------

if false
then
    test_clang_mingw_one "${test_bin_path}" "${triplet}"
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --gc
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --lto
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --gc --lto

    test_clang_mingw_one "${test_bin_path}" "${triplet}" --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --gc --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --lto --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --gc --lto --crt

    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --gc
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --lto
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --gc --lto

    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --gc --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --lto --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static-lib --gc --lto --crt

    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --gc
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --lto
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --gc --lto
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --gc --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --lto --crt
    test_clang_mingw_one "${test_bin_path}" "${triplet}" --static --gc --lto --crt
fi
    # -------------------------------------------------------------------------

    (
      cd c-cpp

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app "${CC}" -o add.o -c add.c -ffunction-sections -fdata-sections
      else
        run_app "${CC}" -o add.o -fpic -c add.c -ffunction-sections -fdata-sections
      fi

      rm -rf libadd-static.a
      run_app "${AR}" -r ${VERBOSE_FLAG} libadd-static.a add.o
      run_app "${RANLIB}" libadd-static.a

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        # The `--out-implib` creates an import library, which can be
        # directly used with -l.
        run_app "${CC}" ${VERBOSE_FLAG} -shared -o libadd-shared.dll -Wl,--out-implib,libadd-shared.dll.a add.o -Wl,--subsystem,windows
      else
        run_app "${CC}" -o libadd-shared.${XBB_HOST_SHLIB_EXT} -shared add.o
      fi

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app "${CC}" -o rt-add.o -c add.c -ffunction-sections -fdata-sections
      else
        run_app "${CC}" -o rt-add.o -fpic -c add.c -ffunction-sections -fdata-sections
      fi

      rm -rf libadd-add-static.a
      run_app "${AR}" -r ${VERBOSE_FLAG} librt-add-static.a rt-add.o
      run_app "${RANLIB}" librt-add-static.a

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app "${CC}" -shared -o librt-add-shared.dll -Wl,--out-implib,librt-add-shared.dll.a rt-add.o -rtlib=compiler-rt
      else
        run_app "${CC}" -o librt-add-shared.${XBB_HOST_SHLIB_EXT} -shared rt-add.o -rtlib=compiler-rt
      fi

      run_app "${CC}" ${VERBOSE_FLAG} -o static-adder${XBB_TARGET_DOT_EXE} adder.c -ladd-static -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}

      test_mingw_expect "42" "static-adder${XBB_TARGET_DOT_EXE}" 40 2

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        # -ladd-shared is in fact libadd-shared.dll.a
        # The library does not show as DLL, it is loaded dynamically.
        run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder${XBB_TARGET_DOT_EXE} adder.c -ladd-shared -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
      else
        run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder adder.c -ladd-shared -L . -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
      fi

      (
        # LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
        # export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
        test_mingw_expect "42" "shared-adder${XBB_TARGET_DOT_EXE}" 40 2
      )

      run_app "${CC}" ${VERBOSE_FLAG} -o rt-static-adder${XBB_TARGET_DOT_EXE} adder.c -lrt-add-static -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}

      test_mingw_expect "42" "rt-static-adder${XBB_TARGET_DOT_EXE}" 40 2

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        # -lrt-add-shared is in fact librt-add-shared.dll.a
        # The library does not show as DLL, it is loaded dynamically.
        run_app "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder${XBB_TARGET_DOT_EXE} adder.c -lrt-add-shared -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
      else
        run_app "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder adder.c -lrt-add-shared -L . -rtlib=compiler-rt -ffunction-sections -fdata-sections ${LD_GC_SECTIONS}
      fi

      (
        # LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
        # export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
        test_mingw_expect "42" "rt-shared-adder${XBB_TARGET_DOT_EXE}" 40 2
      )

      # -------------------------------------------------------------------------
      # Tests borrowed from the llvm-mingw project.

      # run_app "${CC}" hello.c -o hello${XBB_TARGET_DOT_EXE} ${VERBOSE_FLAG} -lm
      # show_dlls hello
      # run_app ./hello

      # run_app "${CC}" setjmp-patched.c -o setjmp${XBB_TARGET_DOT_EXE} ${VERBOSE_FLAG} -lm
      # show_dlls setjmp
      # run_app ./setjmp

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app "${CC}" "hello-tls.c" -o "hello-tls${XBB_TARGET_DOT_EXE}" ${VERBOSE_FLAG}
        show_dlls "hello-tls${XBB_TARGET_DOT_EXE}"
        run_app "./hello-tls"

        run_app "${CC}" "crt-test.c" -o "crt-test${XBB_TARGET_DOT_EXE}" ${VERBOSE_FLAG}
        show_dlls "crt-test${XBB_TARGET_DOT_EXE}"
        run_app "./crt-test"

        run_app "${CC}" "autoimport-lib.c" -shared -o "autoimport-lib.dll" -Wl,--out-implib,libautoimport-lib.dll.a ${VERBOSE_FLAG}
        show_dlls "autoimport-lib.dll"

        run_app "${CC}" "autoimport-main.c" -o "autoimport-main${XBB_TARGET_DOT_EXE}" -L. -lautoimport-lib ${VERBOSE_FLAG}
        show_dlls "autoimport-main${XBB_TARGET_DOT_EXE}"
        run_app "./autoimport-main"

        # The IDL output isn't arch specific, but test each arch frontend
        run_app "${WIDL}" idltest.idl -h -o idltest.h
        run_app "${CC}" idltest.c -I. -o idltest${XBB_TARGET_DOT_EXE} -lole32 ${VERBOSE_FLAG}
        show_dlls idltest${XBB_TARGET_DOT_EXE}
        run_app ./idltest
      fi

      # for test in hello-cpp hello-exception exception-locale exception-reduced global-terminate longjmp-cleanup
      # do
      #   run_app ${CXX} $test.cpp -o $test${XBB_TARGET_DOT_EXE} ${VERBOSE_FLAG}
      #   show_dlls $test
      #   run_app ./$test
      # done

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app ${CXX} "hello-exception.cpp" -static -o "hello-exception-static${XBB_TARGET_DOT_EXE}" ${VERBOSE_FLAG}

        show_dlls "hello-exception-static${XBB_TARGET_DOT_EXE}"
        run_app "./hello-exception-static"

        run_app ${CXX} "tlstest-lib.cpp" -shared -o "tlstest-lib.dll" -Wl,--out-implib,libtlstest-lib.dll.a ${VERBOSE_FLAG}
        show_dlls "tlstest-lib.dll"

        run_app ${CXX} "tlstest-main.cpp" -o "tlstest-main${XBB_TARGET_DOT_EXE}" ${VERBOSE_FLAG}
        show_dlls "tlstest-main${XBB_TARGET_DOT_EXE}"
        run_app "./tlstest-main"
      fi

      if true # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app ${CXX} "throwcatch-lib.cpp" -shared -o "throwcatch-lib.dll" -Wl,--out-implib,libthrowcatch-lib.dll.a ${VERBOSE_FLAG}
      elif false # [ "$(lsb_release -rs)" == "12.04" -a \( "$(uname -m)" == "x86_64" -o "$(uname -m)" == "i686" \) ]
      then
        run_app ${CXX} "throwcatch-lib.cpp" -shared -fpic -o "libthrowcatch-lib.${XBB_HOST_SHLIB_EXT}" ${VERBOSE_FLAG} -fuse-ld=lld
      else
        run_app ${CXX} "throwcatch-lib.cpp" -shared -fpic -o "libthrowcatch-lib.${XBB_HOST_SHLIB_EXT}" ${VERBOSE_FLAG}
      fi

      run_app ${CXX} "throwcatch-main.cpp" -o "throwcatch-main${XBB_TARGET_DOT_EXE}" -L. -lthrowcatch-lib ${VERBOSE_FLAG}

      (
        # LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
        # export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}

        show_dlls "throwcatch-main${XBB_TARGET_DOT_EXE}"
        run_app "./throwcatch-main"
      )
      # -------------------------------------------------------------------------

      # On Windows there is no clangd.exe. (Why?)
      if false # [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        run_app ${test_bin_path}/clangd --check=hello-cpp.cpp
        cat <<'__EOF__' > ${tmp}/unchecked-exception.cpp
// repro for clangd crash from github.com/clangd/clangd issue #1072
#include <exception>
int main() {
    std::exception_ptr foo;
    try {} catch (...) { }
    return 0;
}
__EOF__
        run_app ${test_bin_path}/clangd --check=${tmp}/unchecked-exception.cpp
      fi
    )
  )

  echo
  echo "Testing the llvm${name_suffix} binaries completed successfuly."
}

# ("" | "-bootstrap") [--lto] [--gc] [--crt] [--static|--static-lib]
function test_clang_mingw_one()
{
  echo_develop
  echo_develop "[test_clang_mingw_one $@]"

  local test_bin_path="$1"
  shift
  local mingw_triplet="$1"
  shift
  local suffix="" # "$1"
  # shift

  (
    unset IFS

    local is_gc=""
    local is_lto=""
    local is_crt=""
    local is_static=""
    local is_static_lib=""

    local prefix=""


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
      run_app "${CC}" "simple-hello.c" -o "${prefix}simple-hello-c-one${suffix}${XBB_TARGET_DOT_EXE}" ${LDFLAGS}
      test_mingw_expect "Hello" "${prefix}simple-hello-c-one${suffix}${XBB_TARGET_DOT_EXE}"

      # Test C compile and link in separate steps.
      run_app "${CC}" -c "simple-hello.c" -o "simple-hello.c.o" ${CFLAGS}
      run_app "${CC}" "simple-hello.c.o" -o "${prefix}simple-hello-c-two${suffix}${XBB_TARGET_DOT_EXE}" ${LDFLAGS}
      test_mingw_expect "Hello" "${prefix}simple-hello-c-two${suffix}${XBB_TARGET_DOT_EXE}"

      # -------------------------------------------------------------------------

      # Test C++ compile and link in a single step.
      run_app "${CXX}" "simple-hello.cpp" -o "${prefix}simple-hello-cpp-one${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
      test_mingw_expect "Hello" "${prefix}simple-hello-cpp-one${suffix}${XBB_TARGET_DOT_EXE}"

      # Test C++ compile and link in separate steps.
      run_app "${CXX}" -c "simple-hello.cpp" -o "${prefix}simple-hello${suffix}.cpp.o" ${CXXFLAGS}
      run_app "${CXX}" "${prefix}simple-hello${suffix}.cpp.o" -o "${prefix}simple-hello-cpp-two${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
      test_mingw_expect "Hello" "${prefix}simple-hello-cpp-two${suffix}${XBB_TARGET_DOT_EXE}"

      # -------------------------------------------------------------------------

      if false # [ \( "${XBB_HOST_PLATFORM}" == "linux"  -a "${is_crt}" == "y" \) ]
      then

        # On Linux it works only with the full LLVM runtime and lld

        run_app "${CXX}" "simple-exception.cpp" -o "${prefix}simple-exception${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld -v
        test_mingw_expect "MyException" "${prefix}simple-exception${suffix}${XBB_TARGET_DOT_EXE}"

        run_app "${CXX}" "simple-str-exception.cpp" -o "${prefix}simple-str-exception${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
        test_mingw_expect "MyStringException" "${prefix}simple-str-exception${suffix}${XBB_TARGET_DOT_EXE}"

        run_app "${CXX}" "simple-int-exception.cpp" -o "${prefix}simple-int-exception${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
        test_mingw_expect "42" "${prefix}simple-int-exception${suffix}${XBB_TARGET_DOT_EXE}"

      else

        run_app "${CXX}" "simple-exception.cpp" -o "${prefix}simple-exception${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
        test_mingw_expect "MyException" "${prefix}simple-exception${suffix}${XBB_TARGET_DOT_EXE}"

        run_app "${CXX}" "simple-str-exception.cpp" -o "${prefix}simple-str-exception${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
        test_mingw_expect "MyStringException" "${prefix}simple-str-exception${suffix}${XBB_TARGET_DOT_EXE}"

        run_app "${CXX}" "simple-int-exception.cpp" -o "${prefix}simple-int-exception${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
        test_mingw_expect "42" "${prefix}simple-int-exception${suffix}${XBB_TARGET_DOT_EXE}"

      fi

      # -------------------------------------------------------------------------
      # Tests borrowed from the llvm-mingw project.

      run_app "${CC}" "hello.c" -o "${prefix}hello${suffix}${XBB_TARGET_DOT_EXE}" ${LDFLAGS} -lm
      show_dlls "${prefix}hello${suffix}${XBB_TARGET_DOT_EXE}"
      run_app "./${prefix}hello${suffix}"

      run_app "${CC}" "setjmp-patched.c" -o "${prefix}setjmp${suffix}${XBB_TARGET_DOT_EXE}" ${LDFLAGS} -lm
      show_dlls "${prefix}setjmp${suffix}${XBB_TARGET_DOT_EXE}"
      run_app "./${prefix}setjmp${suffix}"

      for test in hello-cpp global-terminate
      do
        run_app ${CXX} "${test}.cpp" -o "${prefix}${test}${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
        show_dlls "${prefix}${test}${suffix}${XBB_TARGET_DOT_EXE}"
        run_app "./${prefix}${test}${suffix}"
      done

      if false # [ \( "${XBB_HOST_PLATFORM}" == "linux"  -a "${is_crt}" == "y" \) ]
      then

        # /usr/bin/ld: /tmp/longjmp-cleanup-e3da32.o: undefined reference to symbol '_Unwind_Resume@@GCC_3.0'
        run_app ${CXX} longjmp-cleanup.cpp -o ${prefix}longjmp-cleanup${suffix}${XBB_TARGET_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
        show_dlls ${prefix}longjmp-cleanup${suffix}${XBB_TARGET_DOT_EXE}
        run_app ./${prefix}longjmp-cleanup${suffix}

        for test in hello-exception exception-locale exception-reduced
        do
          run_app ${CXX} ${test}.cpp -o ${prefix}${test}${suffix}${XBB_TARGET_DOT_EXE} ${LDXXFLAGS} -stdlib=libc++ -fuse-ld=lld
          show_dlls ${prefix}${test}${suffix}${XBB_TARGET_DOT_EXE}
          run_app ./${prefix}${test}${suffix}
        done

      else

        run_app ${CXX} "longjmp-cleanup.cpp" -o "${prefix}longjmp-cleanup${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
        show_dlls "${prefix}longjmp-cleanup${suffix}${XBB_TARGET_DOT_EXE}"
        run_app "./${prefix}longjmp-cleanup${suffix}"

        for test in hello-exception exception-locale exception-reduced
        do
          run_app ${CXX} "${test}.cpp" -o "${prefix}${test}${suffix}${XBB_TARGET_DOT_EXE}" ${LDXXFLAGS}
          show_dlls "${prefix}${test}${suffix}${XBB_TARGET_DOT_EXE}"
          run_app "./${prefix}${test}${suffix}"
        done

      fi

      run_app "${CC}" -c -o "${prefix}hello-weak${suffix}.c.o" "hello-weak.c" ${CFLAGS}
      run_app "${CC}" -c -o "${prefix}hello-f-weak${suffix}.c.o" "hello-f-weak.c" ${CFLAGS}
      run_app "${CC}" -o "${prefix}hello-weak${suffix}${XBB_TARGET_DOT_EXE}" "${prefix}hello-weak${suffix}.c.o" "${prefix}hello-f-weak${suffix}.c.o" ${VERBOSE_FLAG} -lm ${LDFLAGS}
      test_mingw_expect "Hello World!" "./${prefix}hello-weak${suffix}${XBB_TARGET_DOT_EXE}"

      if [ "${is_lto}" == "y" ]
      then
        # lld-link: error: duplicate symbol: world()
        # >>> defined at hello-weak-cpp.cpp
        # >>>            lto-hello-weak-cpp.cpp.o
        # >>> defined at hello-f-weak-cpp.cpp
        # >>>            lto-hello-f-weak-cpp.cpp.o
        # clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
        echo "Skip hello-weak-cpp with -flto with Windows binaries"
      else
        run_app "${CXX}" -c -o "${prefix}hello-weak-cpp${suffix}.cpp.o" "hello-weak-cpp.cpp" ${CXXFLAGS}
        run_app "${CXX}" -c -o "${prefix}hello-f-weak-cpp${suffix}.cpp.o" "hello-f-weak-cpp.cpp" ${CXXFLAGS}
        run_app "${CXX}" -o "${prefix}hello-weak-cpp${suffix}${XBB_TARGET_DOT_EXE}" "${prefix}hello-weak-cpp${suffix}.cpp.o" "${prefix}hello-f-weak-cpp${suffix}.cpp.o" ${VERBOSE_FLAG} -lm ${LDXXFLAGS}
        test_mingw_expect "Hello World!" "./${prefix}hello-weak-cpp${suffix}${XBB_TARGET_DOT_EXE}"
      fi

      if false
      then
        # Test weak override.
        (
          cd weak-override

          run_app "${CC}" -c "main-weak.c" -o "${prefix}main-weak${suffix}.c.o" ${CFLAGS}
          run_app "${CC}" -c "add2.c" -o "${prefix}add2${suffix}.c.o" ${CFLAGS}
          run_app "${CC}" -c "dummy.c" -o "${prefix}dummy${suffix}.c.o" ${CFLAGS}
          run_app "${CC}" -c "expected3.c" -o "${prefix}expected3${suffix}.c.o" ${CFLAGS}

          run_app "${CC}" "${prefix}main-weak${suffix}.c.o" "${prefix}add2${suffix}.c.o" "${prefix}dummy${suffix}.c.o" "${prefix}expected3${suffix}.c.o" -o "${prefix}weak-override${suffix}${XBB_TARGET_DOT_EXE}" ${LDFLAGS}

          run_app "./${prefix}weak-override${suffix}"
        )
      fi
    )

    # -------------------------------------------------------------------------
  )
}

# -----------------------------------------------------------------------------
