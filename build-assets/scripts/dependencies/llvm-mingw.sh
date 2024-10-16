# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

# The configuration is based on:
# https://github.com/mstorsjo/llvm-mingw

# 17.0.6 - https://github.com/mstorsjo/llvm-mingw/releases/tag/20231128
# 16.0.6 - https://github.com/mstorsjo/llvm-mingw/releases/tag/20230614
# 15.0.0 - https://github.com/mstorsjo/llvm-mingw/releases/tag/20220906

# -----------------------------------------------------------------------------

# XBB_LLVM_PATCH_FILE_NAME

function llvm_mingw_build_first()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  export XBB_ACTUAL_LLVM_VERSION="$1"
  shift

  local is_bootstrap=""
  local bootstrap_option=""

  while [ $# -gt 0 ]
  do
    case "$1" in
      --bootstrap )
        is_bootstrap="y"
        bootstrap_option="$1"
        shift
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
  done

  local name_prefix="mingw-w64-"

  local llvm_version_major=$(xbb_get_version_major "${XBB_ACTUAL_LLVM_VERSION}")
  local llvm_version_minor=$(xbb_get_version_minor "${XBB_ACTUAL_LLVM_VERSION}")

  local llvm_folder_name="${name_prefix}llvm-${XBB_ACTUAL_LLVM_VERSION}-first"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_folder_name}"

  llvm_download "${XBB_ACTUAL_LLVM_VERSION}"

  local llvm_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_folder_name}-installed"
  if [ ! -f "${llvm_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"
      run_verbose_develop cd "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"

      # Use install/libs/lib & include
      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      LDFLAGS="${XBB_LDFLAGS_APP}"

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
          echo "Running ${name_prefix}llvm-first cmake..."

          config_options=()

          if is_development
          then
            config_options+=("-LAH") # display help for each variable
          fi
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
          config_options+=("-DCMAKE_SHARED_LINKER_FLAGS=${LDFLAGS}")

          # To avoid running out of memory.
          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          # Please note the trailing space.
          config_options+=("-DCLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          # config_options+=("-DFLANG_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DLLD_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")
          config_options+=("-DPACKAGE_VENDOR=${XBB_LLVM_BOOTSTRAP_BRANDING} ")

          config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF") # MS
          # Keep tests, to be sure all dependencies are built.
          # config_options+=("-DLLDB_INCLUDE_TESTS=OFF")

          config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")

          config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON") # MS

          # Mind the links in llvm to clang, lld, lldb.
          config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON") # MS

          # config_options+=("-DLLVM_TARGETS_TO_BUILD=ARM;AArch64;X86")  # MS
          config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")

          config_options+=("-DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra")  # MS
          # config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf")  # MS
          # "llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size;llvm-cxxfilt" # MS 20231128
          config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size;llvm-cxxfilt")  # MS

          # compiler-rt, libunwind, libc++ and libc++-abi are built
          # in separate steps intertwined with mingw.

          config_options+=("-DZLIB_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include")

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

        if is_development
        then
          run_verbose_timed cmake \
            --build . \
            --verbose \
            --parallel ${XBB_JOBS}

          if with_strip
          then
            run_verbose "${CMAKE}" \
              --build . \
              --verbose  \
              --target install/strip
          else
            run_verbose "${CMAKE}" \
              --build . \
              --verbose  \
              --target install
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

        # Copy these tools to the install folder, to simplify access
        # to them from the cross build.
        run_verbose cp -v \
          "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"/bin/*-tblgen* \
          "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}"/bin/*-config* \
          "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"

        if [ -f "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/bin/clang-pseudo-gen" ]
        then
          run_verbose cp -v \
            "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/bin/clang-pseudo-gen" \
            "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
        fi

        if [ -f "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/bin/clang-tidy-confusable-chars-gen" ]
        then
          run_verbose cp -v \
            "${XBB_BUILD_FOLDER_PATH}/${llvm_folder_name}/bin/clang-tidy-confusable-chars-gen" \
            "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
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
    echo "Component ${name_prefix}llvm-first already installed"
  fi

  for triplet in "${XBB_MINGW_TRIPLETS[@]}"
  do
    tests_add "test_mingw_llvm" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin" --triplet="${triplet}" "${bootstrap_option}"
  done
}

# $1="${XBB_BOOTSTRAP_SUFFIX}"
function llvm_mingw_build_compiler_rt()
{
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  local triplet="${XBB_TARGET_TRIPLET}" # "x86_64-w64-mingw32"
  local name_prefix="mingw-w64-"
  local is_bootstrap=""

  while [ $# -gt 0 ]
  do
    case "$1" in
      --triplet=* )
        triplet=$(xbb_parse_option "$1")
        name_prefix="${triplet}-"
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

  local llvm_compiler_rt_folder_name="${name_prefix}llvm-${XBB_ACTUAL_LLVM_VERSION}-compiler-rt"

  local llvm_version_major=$(xbb_get_version_major "${XBB_ACTUAL_LLVM_VERSION}")

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

  local llvm_compiler_rt_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_compiler_rt_folder_name}-installed"
  if [ ! -f "${llvm_compiler_rt_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"
      run_verbose_develop cd "${XBB_BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

      # Actually not used.
      # CPPFLAGS="${XBB_CPPFLAGS}"
      # CFLAGS="${XBB_CFLAGS_NO_W}"
      # CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # LDFLAGS="${XBB_LDFLAGS}"

      # export CPPFLAGS
      # export CFLAGS
      # export CXXFLAGS
      # export LDFLAGS

      CMAKE=$(which cmake)

      if [ ! -f "cmake.done" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${name_prefix}llvm-compiler-rt cmake..."

          config_options=()

          if is_development
          then
            config_options+=("-LAH") # display help for each variable
          fi
          config_options+=("-G" "Ninja")

          # Traditionally the runtime is in a versioned folder.
          if [ ${llvm_version_major} -ge 16 ]
          then
            # Starting with clang 16, only the major is used.
            config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${llvm_version_major}") # MS
          else
            # Up to clang 15, the full version number was used.
            config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${XBB_ACTUAL_LLVM_VERSION}") # MS
          fi

          config_options+=("-DCMAKE_BUILD_TYPE=Release") # MS
          config_options+=("-DCMAKE_CROSSCOMPILING=ON")
          config_options+=("-DCMAKE_SYSTEM_NAME=Windows") # MS

          config_options+=("-DCMAKE_C_COMPILER=${CC}") # MS
          config_options+=("-DCMAKE_C_COMPILER_WORKS=ON") # MS
          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}") # MS
          config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON") # MS

          config_options+=("-DCMAKE_ADDR2LINE=${ADDR2LINE}")
          config_options+=("-DCMAKE_AR=${AR}") # MS
          config_options+=("-DCMAKE_DLLTOOL=${DLLTOOL}")
          config_options+=("-DCMAKE_LINKER=${LD}")
          config_options+=("-DCMAKE_NM=${NM}")
          config_options+=("-DCMAKE_OBJCOPY=${OBJCOPY}")
          config_options+=("-DCMAKE_OBJDUMP=${OBJDUMP}")
          config_options+=("-DCMAKE_RANLIB=${RANLIB}") # MS
          config_options+=("-DCMAKE_READELF=${READELF}")
          config_options+=("-DCMAKE_STRIP=${STRIP}")

          if [ "${triplet}" == "x86_64-w64-mingw32" ]
          then
            config_options+=("-DCMAKE_C_COMPILER_TARGET=x86_64-w64-windows-gnu") # MS
          elif [ "${triplet}" == "i686-w64-mingw32" ]
          then
            config_options+=("-DCMAKE_C_COMPILER_TARGET=i686-w64-windows-gnu") # MS
          else
            echo "Unsupported triplet=${triplet} in ${FUNCNAME[0]}()"
            exit 1
          fi

          # No C/C++ options.
          config_options+=("-DCMAKE_C_FLAGS_INIT=") # MS
          config_options+=("-DCMAKE_CXX_FLAGS_INIT=") # MS
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=-v")
          config_options+=("-DCMAKE_SHARED_LINKER_FLAGS=-v")

          config_options+=("-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON") # MS
          config_options+=("-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON") # MS
          config_options+=("-DCOMPILER_RT_BUILD_BUILTINS=ON") # MS

          if [ "${is_bootstrap}" != "y" ]
          then
            config_options+=("-DCOMPILER_RT_BUILD_PROFILE=ON")
            config_options+=("-DCOMPILER_RT_BUILD_SANITIZERS=ON")
            config_options+=("-DCOMPILER_RT_BUILD_XRAY=ON")
            config_options+=("-DCOMPILER_RT_BUILD_XRAY_NO_PREINIT=OFF")

            config_options+=("-DSANITIZER_USE_STATIC_CXX_ABI=ON")
            config_options+=("-DSANITIZER_USE_STATIC_LLVM_UNWINDER=ON")
            config_options+=("-DSANITIZER_USE_STATIC_TEST_CXX=ON")
          fi

          config_options+=("-DCMAKE_FIND_ROOT_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}") # MS
          config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY") # MS
          config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY") # MS

          # Do not activate it, it fails. And be sure llvm-config is not in the PATH.
          # config_options+=("-DLLVM_CONFIG_PATH=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}${XBB_BOOTSTRAP_SUFFIX}/bin/llvm-config")
          config_options+=("-DLLVM_CONFIG_PATH=") # MS

          config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")

          config_options+=("-DSANITIZER_CXX_ABI=libc++") # MS

          config_options+=("-DZLIB_INCLUDE_DIR=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/include") # Extra

          # -DCMAKE_C_FLAGS_INIT=-mguard=cf MS
          # -DCMAKE_CXX_FLAGS_INIT=-mguard=cf

          if [ "${is_bootstrap}" == "y" ]
          then
            # Only the builtins are built for the bootstrap.
            run_verbose "${CMAKE}" \
              "${config_options[@]}" \
              "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/compiler-rt/lib/builtins"
          else
            # The entire compiler-rt is built.
            run_verbose "${CMAKE}" \
              "${config_options[@]}" \
              "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/compiler-rt"
          fi

          touch "cmake.done"

        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/cmake-output-$(ndate).txt"
      fi

      (
        if is_development
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

        if [ "${is_bootstrap}" != "y" ]
        then
          # The dynamic sanitizers require architecture specific
          # libc++.dll and libunwind.dll, currently not supported by
          # the post-processing step.
          if [ "${triplet}" == "x86_64-w64-mingw32" ]
          then
            run_verbose rm "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${llvm_version_major}/lib/windows"/libclang_rt.asan_dynamic-x86_64.dll*
          elif [ "${triplet}" == "i686-w64-mingw32" ]
          then
            run_verbose rm "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/lib/clang/${llvm_version_major}/lib/windows"/libclang_rt.asan_dynamic-i386.dll*
          else
            echo "Unsupported triplet=${triplet} in ${FUNCNAME[0]}()"
            exit 1
          fi
        fi

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

  local llvm_libcxx_folder_name="${name_prefix}llvm-${XBB_ACTUAL_LLVM_VERSION}-libcxx"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}"

  local llvm_libcxx_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-installed"
  if [ ! -f "${llvm_libcxx_stamp_file_path}" ]
  then
    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      run_verbose_develop cd "${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

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

      CMAKE=$(which cmake)

      if [ ! -f "cmake.done" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running ${name_prefix}llvm-libcxx cmake..."

          config_options=()

          if is_development
          then
            config_options+=("-LAH") # display help for each variable
          fi
          config_options+=("-G" "Ninja")

          config_options+=("-DCMAKE_INSTALL_PREFIX=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}") # MS

          config_options+=("-DCMAKE_BUILD_TYPE=Release") # MS
          config_options+=("-DCMAKE_CROSSCOMPILING=ON") # MS

          config_options+=("-DCMAKE_C_COMPILER=${CC}") # MS
          config_options+=("-DCMAKE_C_COMPILER_WORKS=ON") # MS
          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}") # MS
          config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON") # MS

          config_options+=("-DCMAKE_ADDR2LINE=${ADDR2LINE}")
          config_options+=("-DCMAKE_AR=${AR}") # MS
          config_options+=("-DCMAKE_DLLTOOL=${DLLTOOL}")
          config_options+=("-DCMAKE_LINKER=${LD}")
          config_options+=("-DCMAKE_NM=${NM}")
          config_options+=("-DCMAKE_OBJCOPY=${OBJCOPY}")
          config_options+=("-DCMAKE_OBJDUMP=${OBJDUMP}")
          config_options+=("-DCMAKE_RANLIB=${RANLIB}") # MS
          config_options+=("-DCMAKE_READELF=${READELF}")
          config_options+=("-DCMAKE_STRIP=${STRIP}")

          # Warning: the result is not the mingw triplet, it is the Linux triplet.
          if [ "${triplet}" == "x86_64-w64-mingw32" ]
          then
            config_options+=("-DCMAKE_CXX_COMPILER_TARGET=x86_64-w64-windows-gnu") # MS
          elif [ "${triplet}" == "i686-w64-mingw32" ]
          then
            config_options+=("-DCMAKE_CXX_COMPILER_TARGET=i686-w64-windows-gnu") # MS
          else
            echo "Unsupported triplet=${triplet} in ${FUNCNAME[0]}()"
            exit 1
          fi

          config_options+=("-DCMAKE_C_FLAGS_INIT=") # MS
          config_options+=("-DCMAKE_CXX_FLAGS_INIT=") # MS
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=-v")
          config_options+=("-DCMAKE_SHARED_LINKER_FLAGS=-v")

          config_options+=("-DCMAKE_SYSTEM_NAME=Windows") # MS

          # config_options+=("-DLIBCXX_INSTALL_HEADERS=ON")
          # config_options+=("-DLIBCXX_ENABLE_EXCEPTIONS=ON")
          config_options+=("-DLIBCXX_ENABLE_THREADS=ON")
          config_options+=("-DLIBCXX_HAS_WIN32_THREAD_API=ON")

          config_options+=("-DLIBCXX_ENABLE_SHARED=ON") # MS
          # config_options+=("-DLIBCXX_ENABLE_SHARED=OFF")

          config_options+=("-DLIBCXX_CXX_ABI=libcxxabi") # MS

          # config_options+=("-DLIBCXX_CXX_ABI_INCLUDE_PATHS=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libcxxabi/include")
          # config_options+=("-DLIBCXX_CXX_ABI_LIBRARY_PATH=${XBB_BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/lib")

          config_options+=("-DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=OFF") # MS

          config_options+=("-DLIBCXX_ENABLE_STATIC=ON") # MS
          # config_options+=("-DLIBCXX_ENABLE_EXPERIMENTAL_LIBRARY=OFF")
          config_options+=("-DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=ON") # MS
          # config_options+=("-DLIBCXX_ENABLE_NEW_DELETE_DEFINITIONS=OFF")

          config_options+=("-DLIBCXX_LIBDIR_SUFFIX=") # MS
          config_options+=("-DLIBCXX_INCLUDE_TESTS=OFF") # MS
          config_options+=("-DLIBCXX_USE_COMPILER_RT=ON") # MS

          config_options+=("-DLIBCXXABI_USE_COMPILER_RT=ON") # MS
          config_options+=("-DLIBCXXABI_USE_LLVM_UNWINDER=ON") # MS
          # config_options+=("-DLIBCXXABI_ENABLE_EXCEPTIONS=ON")
          config_options+=("-DLIBCXXABI_ENABLE_THREADS=ON")
          config_options+=("-DLIBCXXABI_HAS_WIN32_THREAD_API=ON")
          # config_options+=("-DLIBCXXABI_TARGET_TRIPLE=${XBB_TARGET_TRIPLET}")
          config_options+=("-DLIBCXXABI_ENABLE_SHARED=OFF") # MS
          # config_options+=("-DLIBCXXABI_LIBCXX_INCLUDES=${XBB_BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}/include/c++/v1")
          config_options+=("-DLIBCXXABI_LIBDIR_SUFFIX=") # MS
          # config_options+=("-DLIBCXXABI_ENABLE_NEW_DELETE_DEFINITIONS=ON")

          # config_options+=("-DLIBUNWIND_ENABLE_THREADS=ON")

          # For now disable shared libc++ and libunwind, it requires an
          # explicit -lunwind in the link.
          config_options+=("-DLIBUNWIND_ENABLE_SHARED=ON") # MS
          # config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF") # Different

          config_options+=("-DLIBUNWIND_ENABLE_STATIC=ON") # MS
          # config_options+=("-DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF")
          config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON") # MS

          config_options+=("-DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx") # Extra

          config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")

          config_options+=("-DLLVM_PATH=${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm") # MS

          # -DCMAKE_C_FLAGS_INIT=-mguard=cf MS
          # -DCMAKE_CXX_FLAGS_INIT=-mguard=cf MS

          run_verbose "${CMAKE}" \
            "${config_options[@]}" \
            "${XBB_SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/runtimes"

          touch "cmake.done"

        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/cmake-output-$(ndate).txt"
      fi

      (
        run_verbose "${CMAKE}" \
          --build . \
          --verbose \
          --target install

        run_verbose cp -v \
          "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/bin"/*.dll \
          "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/lib"

        # Append libunwind to libc++, to simplify things.
        # It helps when there are no shared libc++ and linunwind.
        # run_verbose "${AR}" qcsL \
        #         "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/lib/libc++.a" \
        #         "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${triplet}/lib/libunwind.a"

        if is_development
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
  echo_develop
  echo_develop "[${FUNCNAME[0]} $@]"

  local test_bin_path="$1"
  shift

  local triplet="x86_64-w64-mingw32"
  local name_prefix=""
  local name_suffix=""

  local is_bootstrap=""
  local bootstrap_option=""

  while [ $# -gt 0 ]
  do
    case "$1" in
      --triplet=* )
        triplet=$(xbb_parse_option "$1")
        shift
        ;;

      --bootstrap )
        is_bootstrap="y"
        bootstrap_option="$1"
        shift
        ;;

      * )
        echo "Unsupported argument $1 in ${FUNCNAME[0]}()"
        exit 1
        ;;
    esac
  done

  name_prefix="${triplet}-"

  local bits
  local bits_option=""
  if [ "${triplet}" == "x86_64-w64-mingw32" ]
  then
    bits="64"
    bits_option="--64"
  elif [ "${triplet}" == "i686-w64-mingw32" ]
  then
    bits="32"
    bits_option="--32"
  else
    echo "Unsupported triplet ${triplet}"
    exit 1
  fi

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

    CLANGD="${test_bin_path}/clangd"

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
    run_verbose_develop cd "${XBB_TESTS_FOLDER_PATH}/${name_prefix}clang${name_suffix}"

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

    # `-fuse-ld=lld` fails on macOS:
    # ld64.lld: warning: ignoring unknown argument: -no_deduplicate
    # ld64.lld: warning: -sdk_version is required when emitting min version load command.  Setting sdk version to match provided min version
    # For now use the system linker /usr/bin/ld.

    # -static-libstdc++ not available on macOS:
    # clang-11: warning: argument unused during compilation: '-static-libstdc++'

    # -------------------------------------------------------------------------

    ls -l ${test_bin_path}/../${triplet}/bin

    local llvm_version=$(run_host_app "${CC}" -dumpversion)
    echo "clang: ${llvm_version}"

    local llvm_version_major=$(xbb_get_version_major "${llvm_version}")

    if [ ${llvm_version_major} -eq 14 ] || \
       [ ${llvm_version_major} -eq 15 ]
    then
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

      export XBB_IGNORE_TEST_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_HELLO_WEAK2_CPP="y"

      export XBB_IGNORE_TEST_STATIC_LIB_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_CRT_HELLO_WEAK2_CPP="y"

      export XBB_IGNORE_TEST_STATIC_LTO_CRT_HELLO_WEAK2_CPP="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_CRT_HELLO_WEAK2_CPP="y"
    elif [ ${llvm_version_major} -eq 17 ]
    then

      # bufferoverflow.
      # error: unable to find library -lssp
      export XBB_IGNORE_TEST_ALL_BUFFEROVERFLOW="y"

      # weak-undef.
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

      export XBB_IGNORE_TEST_LTO_CRT_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_GC_LTO_CRT_WEAK_UNDEF_C="y"

      export XBB_IGNORE_TEST_STATIC_LIB_LTO_CRT_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_LIB_GC_LTO_CRT_WEAK_UNDEF_C="y"

      export XBB_IGNORE_TEST_STATIC_LTO_CRT_WEAK_UNDEF_C="y"
      export XBB_IGNORE_TEST_STATIC_GC_LTO_CRT_WEAK_UNDEF_C="y"
    elif [ ${llvm_version_major} -eq 18 ]
    then
      # bufferoverflow.
      # error: unable to find library -lssp
      export XBB_IGNORE_TEST_ALL_BUFFEROVERFLOW="y"
    fi

    (
      # The DLLs are usually in bin, but for consistency within GCC, they are
      # also copied to lib; it is recommended to ask the compiler for the
      # actual path.
      # export WINEPATH="${test_bin_path}/../${triplet}/bin;${WINEPATH:-}"
      libcxx_file_path="$(${CXX} -print-file-name=libc++.dll)"
      if [ "${libcxx_file_path}" == "libc++.dll" ]
      then
        echo "Cannot get libc++.dll path"
        exit 1
      fi
      export WINEPATH="$(dirname $(echo "${libcxx_file_path}"))"
      echo "WINEPATH=${WINEPATH}"

      test_compiler_c_cpp ${bits_option} "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --gc "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --lto "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --gc --lto "${bootstrap_option}"

      if [ "${XBB_HOST_ARCH}" == "x64" ] && [ "${is_bootstrap}" != "y" ]
      then
        test_compiler_c_cpp ${bits} ${bits_option} --clang-coverage
      fi
    )
    if [ "${XBB_APPLICATION_BOOTSTRAP_ONLY:-"n"}" == "y" ]
    then
      test_compiler_c_cpp ${bits_option} --static-lib "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static-lib --gc "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static-lib --lto "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static-lib --gc --lto "${bootstrap_option}"

      test_compiler_c_cpp ${bits_option} --static "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static --gc "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static --lto "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static --gc --lto "${bootstrap_option}"
    fi

    (
      libcxx_file_path="$(${CXX} -print-file-name=libc++.dll)"
      if [ "${libcxx_file_path}" == "libc++.dll" ]
      then
        echo "Cannot get libc++.dll path"
        exit 1
      fi
      export WINEPATH="$(dirname $(echo "${libcxx_file_path}"))"
      echo "WINEPATH=${WINEPATH}"

      # Once again with --crt
      test_compiler_c_cpp ${bits_option} --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --gc --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --lto --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --gc --lto --crt "${bootstrap_option}"
    )

    if [ "${XBB_APPLICATION_BOOTSTRAP_ONLY:-"n"}" == "y" ]
    then
      test_compiler_c_cpp ${bits_option} --static-lib --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static-lib --gc --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static-lib --lto --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static-lib --gc --lto --crt "${bootstrap_option}"

      test_compiler_c_cpp ${bits_option} --static --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static --gc --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static --lto --crt "${bootstrap_option}"
      test_compiler_c_cpp ${bits_option} --static --gc --lto --crt "${bootstrap_option}"
    fi

    # -------------------------------------------------------------------------

    (
      cd c-cpp

      # On Windows things are a bit more complicated
      if is_native
      then
        if [ -f "${CLANGD}${XBB_HOST_DOT_EXE}" ]
        then

          test_case_clangd_hello

          # Segmentation fault (core dumped) on 13 & 14
          test_case_clangd_unchecked_exception

        fi

      fi
    )

  )
}

# -----------------------------------------------------------------------------
