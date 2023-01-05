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

function llvm_mingw_build_first()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  export ACTUAL_LLVM_VERSION="$1"
  shift

  local name_prefix="mingw-w64-"

  local llvm_version_major=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)[.]\([0-9][0-9]*\)[.].*|\1|')
  local llvm_version_minor=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)[.]\([0-9][0-9]*\)[.].*|\2|')

  export llvm_src_folder_name="llvm-project-${ACTUAL_LLVM_VERSION}.src"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${ACTUAL_LLVM_VERSION}/${llvm_archive}"

  local llvm_folder_name="${name_prefix}llvm-${ACTUAL_LLVM_VERSION}-first"

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
      xbb_adjust_ldflags_rpath

      if [ "${XBB_HOST_PLATFORM}" == "linux" ]
      then
        # MemoryMapper.cpp:(.text._ZZN4llvm3orc18SharedMemoryMapper7reserveEmNS_15unique_functionIFvNS_8ExpectedINS0_17ExecutorAddrRangeEEEEEEENUlNS_5ErrorENS3_ISt4pairINS0_12ExecutorAddrENSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEEEEEEE_clES8_SI_+0x110): undefined reference to `shm_open'
        LDFLAGS+=" -ldl -lrt -lpthread -lm"
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
          echo "Running ${name_prefix}llvm-first cmake..."

          config_options=()

          config_options+=("-LH") # display help for each variable
          config_options+=("-G" "Ninja")

          # https://llvm.org/docs/GettingStarted.html
          # https://llvm.org/docs/CMake.html

          config_options+=("-DCMAKE_BUILD_TYPE=Release") # MS
          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}") # MS

          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}") # MS
          config_options+=("-DCMAKE_C_COMPILER=${CC}") # MS

          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}") # MS
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}") # MS
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}") # MS

          # To avoid running out of memory.
          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          # Please note the trailing space.
          config_options+=("-DCLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DFLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DLLD_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DPACKAGE_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")

          config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF") # MS
          # Keep tests, to be sure all dependencies are built.
          # config_options+=("-DLLDB_INCLUDE_TESTS=OFF")

          config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON") # MS

          # Mind the links in llvm to clang, lld, lldb.
          config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON") # MS

          # config_options+=("-DLLVM_TARGETS_TO_BUILD=ARM;AArch64;X86")  # MS
          config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")

          config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra")  # MS
          config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf")  # MS

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
        echo "Running ${name_prefix}llvm-first build..."

        if [ "${XBB_IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake \
            --build . \
            --verbose \
            --parallel ${XBB_JOBS}

          run_verbose cmake \
            --build . \
            --verbose  \
            --target install/strip
        else
          run_verbose cmake \
            --build .

          run_verbose cmake \
            --build . \
            --target install/strip
        fi

        # Copy these tools to the install folder, to simplify access
        # to them from the cross build.
        run_verbose cp -v \
          "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"/bin/*-tblgen* \
          "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"/bin/*-config* \
          "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

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
    echo "Component ${name_prefix}llvm-first already installed"
  fi

  tests_add "test_mingw_llvm" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
}

# $1="${XBB_BOOTSTRAP_SUFFIX}"
function llvm_mingw_build_compiler_rt()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  local triplet="${XBB_TARGET_TRIPLET}" # "x86_64-w64-mingw32"
  local name_prefix="mingw-w64-"

  while [ $# -gt 0 ]
  do
    case "$1" in
      --triplet=* )
        triplet=$(xbb_parse_option "$1")
        name_prefix="${triplet}-"
        shift
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
  done

  local llvm_compiler_rt_folder_name="${name_prefix}llvm-${ACTUAL_LLVM_VERSION}-compiler-rt"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

  local llvm_compiler_rt_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_compiler_rt_folder_name}-installed"
  if [ ! -f "${llvm_compiler_rt_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

      # Actually not used.
      # CPPFLAGS="${XBB_CPPFLAGS}"
      # CFLAGS="${XBB_CFLAGS_NO_W}"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # LDFLAGS="${XBB_LDFLAGS}"

      # export CPPFLAGS
      # export CFLAGS
      # export CXXFLAGS
      # export LDFLAGS

      (
        xbb_show_env_develop

        echo
        echo "Running ${name_prefix}llvm-compiler-rt cmake..."

        config_options=()

        config_options+=("-LH") # display help for each variable
        config_options+=("-G" "Ninja")

        # Traditionally the runtime is in a versioned folder.
        config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}") # MS

        config_options+=("-DCMAKE_BUILD_TYPE=Release") # MS
        # config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows") # MS

        config_options+=("-DCMAKE_C_COMPILER=${CC}") # MS
        # config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${CXX}") # MS
        # config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${AR}") # MS
        config_options+=("-DCMAKE_RANLIB=${RANLIB}") # MS

        if [ "${XBB_TARGET_MACHINE}" == "x86_64" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=x86_64-windows-gnu") # MS
        elif [ "${XBB_TARGET_MACHINE}" == "i686" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=i386-windows-gnu")
        else
          echo "Unsupported XBB_TARGET_MACHINE=${XBB_TARGET_MACHINE} in ${FUNCNAME[0]}()"
          exit 1
        fi

        config_options+=("-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON") # MS
        config_options+=("-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON") # MS
        config_options+=("-DCOMPILER_RT_BUILD_BUILTINS=ON") # MS

        config_options+=("-DSANITIZER_CXX_ABI=libc++") # MS

        config_options+=("-DZLIB_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")

        # if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        # then
        #   # Otherwise it'll generate two -mmacosx-version-min
        #   config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
        # fi

        config_options+=("-DCMAKE_FIND_ROOT_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}") # MS
        config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY") # MS
        config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY") # MS

        # Do not activate it, it fails. And be sure llvm-config is not in the PATH.
        # config_options+=("-DLLVM_CONFIG_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-config")
        config_options+=("-DLLVM_CONFIG_PATH=") # MS

        # No C/C++ options.
        config_options+=("-DCMAKE_C_FLAGS_INIT=") # MS
        config_options+=("-DCMAKE_CXX_FLAGS_INIT=") # MS

        run_verbose cmake \
          "${config_options[@]}" \
          "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/compiler-rt/lib/builtins"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/cmake-output-$(ndate).txt"

      (
        if [ "${XBB_IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake \
            --build . \
            --verbose \
            --parallel ${XBB_JOBS}

          run_verbose cmake \
            --build . \
            --verbose \
            --target install/strip
        else
          run_verbose cmake \
            --build .

          run_verbose cmake \
            --build . \
            --target install/strip
        fi

        # if [ "" == "${XBB_BOOTSTRAP_SUFFIX}" ]
        # then
        #   mkdir -pv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/windows"
        #   for i in lib/windows/libclang_rt.*.a
        #   do
        #       run_verbose cp -v $i "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${ACTUAL_LLVM_VERSION}/lib/windows/$(basename $i)"
        #   done

        #   mkdir -pv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}/bin"
        #   for i in lib/windows/libclang_rt.*.dll
        #   do
        #       if [ -f $i ]
        #       then
        #           run_verbose cp -v $i "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_TARGET_TRIPLET}/bin"
        #       fi
        #   done
        # fi

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/build-output-$(ndate).txt"
    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_compiler_rt_stamp_file_path}"

  else
    echo "Component ${name_prefix}llvm-compiler-rt already installed"
  fi
}

function llvm_mingw_build_libcxx()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  local triplet="${XBB_TARGET_TRIPLET}" # "x86_64-w64-mingw32"
  local name_prefix="mingw-w64-"

  while [ $# -gt 0 ]
  do
    case "$1" in
      --triplet=* )
        triplet=$(xbb_parse_option "$1")
        name_prefix="${triplet}-"
        shift
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
  done

  local llvm_libcxx_folder_name="${name_prefix}llvm-${ACTUAL_LLVM_VERSION}-libcxx"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}"

  local llvm_libcxx_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-installed"
  if [ ! -f "${llvm_libcxx_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      # Actually not used
      # CPPFLAGS="${XBB_CPPFLAGS}"
      # CFLAGS="${XBB_CFLAGS_NO_W}"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      # # CFLAGS="${XBB_CFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"
      # # CXXFLAGS="${XBB_CXXFLAGS_NO_W} -Wno-dll-attribute-on-redeclaration"

      # LDFLAGS="${XBB_LDFLAGS}"

      # export CPPFLAGS
      # export CFLAGS
      # export CXXFLAGS
      # export LDFLAGS

      (
        xbb_show_env_develop

        echo
        echo "Running ${name_prefix}llvm-libcxx cmake..."

        config_options=()

        config_options+=("-LH") # display help for each variable
        config_options+=("-G" "Ninja")

        config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}") # MS

        config_options+=("-DCMAKE_BUILD_TYPE=Release") # MS
        # config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows") # MS

        config_options+=("-DCMAKE_C_COMPILER=${CC}") # MS
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON") # MS
        config_options+=("-DCMAKE_CXX_COMPILER=${CXX}") # MS
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON") # MS

        config_options+=("-DCMAKE_AR=${AR}") # MS
        config_options+=("-DCMAKE_RANLIB=${RANLIB}") # MS

        if [ "${XBB_TARGET_MACHINE}" == "x86_64" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=x86_64-windows-gnu") # MS
        elif [ "${XBB_TARGET_MACHINE}" == "i686" ]
        then
          config_options+=("-DCMAKE_C_COMPILER_TARGET=i386-windows-gnu")
        else
          echo "Unsupported XBB_TARGET_MACHINE=${XBB_TARGET_MACHINE} in ${FUNCNAME[0]}()"
          exit 1
        fi

        config_options+=("-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx")

        # config_options+=("-DLIBUNWIND_ENABLE_THREADS=ON")

        # For now disable shared libc++ and libunwind, it requires an
        # explicit -lunwind in the link.
        # config_options+=("-DLIBUNWIND_ENABLE_SHARED=ON") # MS
        config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")

        config_options+=("-DLIBUNWIND_ENABLE_STATIC=ON") # MS
        # config_options+=("-DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF")
        config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON") # MS

        # config_options+=("-DCMAKE_SHARED_LINKER_FLAGS=-lunwind")

        # config_options+=("-DLIBCXX_INSTALL_HEADERS=ON")
        # config_options+=("-DLIBCXX_ENABLE_EXCEPTIONS=ON")
        # config_options+=("-DLIBCXX_ENABLE_THREADS=ON")
        # config_options+=("-DLIBCXX_HAS_WIN32_THREAD_API=ON")

        # config_options+=("-DLIBCXX_ENABLE_SHARED=ON") # MS
        config_options+=("-DLIBCXX_ENABLE_SHARED=OFF") # MS

        config_options+=("-DLIBCXX_ENABLE_STATIC=ON") # MS
        # config_options+=("-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF")
        config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON") # MS
        # config_options+=("-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=OFF")
        config_options+=("-DLIBCXX_CXX_ABI=libcxxabi") # MS
        # config_options+=("-DLIBCXX_CXX_ABI_INCLUDE_PATHS=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxxabi/include")
        # config_options+=("-DLIBCXX_CXX_ABI_LIBRARY_PATH=${XBB_BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/lib")
        config_options+=("-DLIBCXX_LIBDIR_SUFFIX=") # MS
        config_options+=("-DLIBCXX_INCLUDE_TESTS=OFF") # MS
        config_options+=("-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF") # MS
        config_options+=("-DLIBCXX_USE_COMPILER_RT=ON") # MS

        config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON") # MS
        config_options+=("-DLIBCXXABI_USE_LLVM_UNWINDER=ON") # MS
        # config_options+=("-DLIBCXXABI_ENABLE_EXCEPTIONS=ON")
        # config_options+=("-DLIBCXXABI_ENABLE_THREADS=ON")
        # config_options+=("-DLIBCXXABI_TARGET_TRIPLE=${XBB_TARGET_TRIPLET}")
        config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF") # MS
        # config_options+=("-DLIBCXXABI_LIBCXX_INCLUDES=${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}/include/c++/v1")
        config_options+=("-DLIBCXXABI_LIBDIR_SUFFIX=") # MS
        # config_options+=("-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=ON")

       config_options+=("-DCMAKE_C_FLAGS_INIT=") # MS
       config_options+=("-DCMAKE_CXX_FLAGS_INIT=") # MS

        config_options+=("-DLLVM_PATH=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm") # MS

        # if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        # then
        #   # Otherwise it'll generate two -mmacosx-version-min
        #   config_options+=("-DCMAKE_OSX_DEPLOYMENT_TARGET=${XBB_MACOSX_DEPLOYMENT_TARGET}")
        # fi

        run_verbose cmake \
          "${config_options[@]}" \
          "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/runtimes"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/cmake-output-$(ndate).txt"

      (
        run_verbose cmake \
          --build . \
          --verbose \
          --target install

        # Append libunwind to libc++, to simplify things.
        # It hels when there are no shared libc++ and linunwind.
        run_verbose "${AR}" qcsL \
                "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/lib/libc++.a" \
                "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/lib/libunwind.a"

        if [ "${XBB_IS_DEVELOP}" == "y" ]
        then
          run_verbose "${NM}" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/lib/libc++.a"
        fi

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/build-output-$(ndate).txt"

    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${llvm_libcxx_stamp_file_path}"

  else
    echo "Component ${name_prefix}llvm-libcxx already installed"
  fi
}

# -----------------------------------------------------------------------------

function test_mingw_llvm()
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
        shift
        ;;

      --bootstrap )
        is_bootstrap="y"
        shift
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
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

    # For consistency, on Linux it is available in the system.
    local realpath=$(which grealpath || which realpath || echo realpath)

    if [ "${XBB_BUILD_PLATFORM}" != "win32" ]
    then
      show_host_libs "${test_bin_path}/clang"
      show_host_libs "${test_bin_path}/lld"
      if [ -f "${test_bin_path}/lldb" -o -f "${test_bin_path}/lldb${XBB_HOST_DOT_EXE}" ]
      then
        # lldb not available on Ubuntu 16 Arm.
        show_host_libs "${test_bin_path}/lldb"
      fi
    fi

    echo
    echo "Testing if the ${name_prefix}llvm binaries start properly..."

    run_host_app_verbose "${CC}" --version
    run_host_app_verbose "${CXX}" --version

    if [ -f "${test_bin_path}/clang-format" -o \
         -f "${test_bin_path}/clang-format${XBB_HOST_DOT_EXE}" ]
    then
      run_host_app_verbose "${test_bin_path}/clang-format" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    # run_host_app_verbose "${test_bin_path}/lld" --version || true

    run_host_app_verbose "${test_bin_path}/llvm-ar" --version
    run_host_app_verbose "${test_bin_path}/llvm-nm" --version
    run_host_app_verbose "${test_bin_path}/llvm-objcopy" --version
    run_host_app_verbose "${test_bin_path}/llvm-objdump" --version
    run_host_app_verbose "${test_bin_path}/llvm-ranlib" --version
    if [ -f "${test_bin_path}/llvm-readelf" ]
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
    echo "Testing ${name_prefix}clang configuration..."

    run_host_app_verbose "${test_bin_path}/clang" -print-target-triple
    run_host_app_verbose "${test_bin_path}/clang" -print-targets
    run_host_app_verbose "${test_bin_path}/clang" -print-supported-cpus
    run_host_app_verbose "${test_bin_path}/clang" -print-search-dirs
    run_host_app_verbose "${test_bin_path}/clang" -print-resource-dir
    run_host_app_verbose "${test_bin_path}/clang" -print-libgcc-file-name

    # run_host_app_verbose "${test_bin_path}/llvm-config" --help

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

    run_verbose cp -rv "${helper_folder_path}/tests/fortran" .
    chmod -R a+w fortran

    # -------------------------------------------------------------------------

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

    compiler-tests-single "${test_bin_path}"
    compiler-tests-single "${test_bin_path}" --gc
    compiler-tests-single "${test_bin_path}" --lto
    compiler-tests-single "${test_bin_path}" --gc --lto

    compiler-tests-single "${test_bin_path}" --static-lib
    compiler-tests-single "${test_bin_path}" --static-lib --gc
    compiler-tests-single "${test_bin_path}" --static-lib --lto
    compiler-tests-single "${test_bin_path}" --static-lib --gc --lto

    compiler-tests-single "${test_bin_path}" --static
    compiler-tests-single "${test_bin_path}" --static --gc
    compiler-tests-single "${test_bin_path}" --static --lto
    compiler-tests-single "${test_bin_path}" --static --gc --lto

    # Once again with --crt
    compiler-tests-single "${test_bin_path}" --crt
    compiler-tests-single "${test_bin_path}" --gc --crt
    compiler-tests-single "${test_bin_path}" --lto --crt
    compiler-tests-single "${test_bin_path}" --gc --lto --crt

    compiler-tests-single "${test_bin_path}" --static-lib --crt
    compiler-tests-single "${test_bin_path}" --static-lib --gc --crt
    compiler-tests-single "${test_bin_path}" --static-lib --lto --crt
    compiler-tests-single "${test_bin_path}" --static-lib --gc --lto --crt

    compiler-tests-single "${test_bin_path}" --static --crt
    compiler-tests-single "${test_bin_path}" --static --gc --crt
    compiler-tests-single "${test_bin_path}" --static --lto --crt
    compiler-tests-single "${test_bin_path}" --static --gc --lto --crt

    # -------------------------------------------------------------------------

    (
      cd c-cpp

      # -------------------------------------------------------------------------

      # On Windows there is no clangd.exe. (Why?)
      if is_native
      then
        run_host_app_verbose "${test_bin_path}/clangd" --check="hello-cpp.cpp"

        cat <<'__EOF__' > "unchecked-exception.cpp"
// repro for clangd crash from github.com/clangd/clangd issue #1072
#include <exception>
int main() {
    std::exception_ptr foo;
    try {} catch (...) { }
    return 0;
}
__EOF__
        run_host_app_verbose "${test_bin_path}/clangd" --check="unchecked-exception.cpp"
      fi
    )
  )
}

# -----------------------------------------------------------------------------
