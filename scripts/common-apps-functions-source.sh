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
            
          cp "config.log" "${LOGS_FOLDER_PATH}/${binutils_folder_name}/config-log.txt"
        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${binutils_folder_name}/configure-output.txt"
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

function download_llvm()
{
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
  elif [ "${TARGET_PLATFORM}" == "win32" ]
  then
    (
      cd "${llvm_src_folder_name}/llvm/tools"

      # This trick will allow to build the toolchain only and still get clang
      for p in clang lld lldb; do
          if [ ! -e $p ]
          then
              ln -s ../../$p .
          fi
      done
    )
  fi
}

function build_native_llvm_mingw()
{
  # https://github.com/mstorsjo/llvm-mingw

  local native_llvm_mingw_version="$1"

  local native_llvm_mingw_folder_name="native-llvm-mingw-${native_llvm_mingw_version}"
  local native_llvm_mingw_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${native_llvm_mingw_folder_name}-installed"

  export BUILD_LLVM_MINGW_PATH="${BUILD_FOLDER_PATH}/${native_llvm_mingw_folder_name}"
  export NATIVE_LLVM_MINGW_FOLDER_NAME="native-llvm-mingw"
  export NATIVE_LLVM_MINGW_FOLDER_PATH="${INSTALL_FOLDER_PATH}/${NATIVE_LLVM_MINGW_FOLDER_NAME}"

  # Redundant, but may be use in submodule scripts.
  export TOOLCHAIN_PREFIX="${NATIVE_LLVM_MINGW_FOLDER_PATH}"
  export TOOLCHAIN_ARCHS="${HOST_MACHINE}"

  if [ ! -f "${native_llvm_mingw_stamp_file_path}" ]
  then

    mkdir -pv "${LOGS_FOLDER_PATH}/${native_llvm_mingw_folder_name}"

    mkdir -p "${BUILD_FOLDER_PATH}/${native_llvm_mingw_folder_name}"
    cd "${BUILD_FOLDER_PATH}/${native_llvm_mingw_folder_name}"


    git config --global user.name "LLVM MinGW"
    git config --global user.email root@localhost

    (
      xbb_activate

      # Use the XBB libraries.
      xbb_activate_dev
      xbb_activate_libs

      unset_gcc_env

      CC=${NATIVE_CC}
      CXX=${NATIVE_CXX}

      CPPFLAGS="${XBB_CPPFLAGS} -I${XBB_FOLDER_PATH}/include/ncurses"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      export CC
      export CXX
      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort

      # -----------------------------------------------------------------------

      # Note: __EOF__ is NOT quoted to allow substitutions here.
      cat <<__EOF__ > build-native-llvm.sh
#!/bin/bash

config_options=()
config_options+=("-DCMAKE_C_COMPILER=${CC}")
config_options+=("-DCMAKE_CXX_COMPILER=${CXX}")

config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")

config_options+=("-DCMAKE_VERBOSE_MAKEFILE=ON")

__EOF__

      cat "${BUILD_GIT_PATH}/scripts/llvm-mingw/build-llvm.sh" >> build-native-llvm.sh
      sed -i.bak \
        -e 's|^    \$CMAKEFLAGS \\$|    \$CMAKEFLAGS "\${config_options[@]}" --verbose \\|' \
        -e 's|^    -DLLVM_TARGETS_TO_BUILD="ARM;AArch64;X86" \\$|    -DLLVM_TARGETS_TO_BUILD="X86" \\|' \
        -e 's|^\$BUILDCMD |\$BUILDCMD -v |' \
        build-native-llvm.sh

      mkdir -pv patches/llvm-project
      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/patches/llvm-project"/*.patch patches/llvm-project

      # Build LLVM
      run_verbose bash -x build-native-llvm.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

      # -------------------------------------------------------------------

      # Strip the LLVM install output immediately.
      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/strip-llvm.sh" .
      run_verbose bash strip-llvm.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

      # Install the usual $TUPLE-clang binaries
      mkdir -p wrappers
      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/wrappers/"*.sh wrappers
      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/wrappers/"*.c wrappers
      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/wrappers/"*.h wrappers

      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/install-wrappers.sh" .

      run_verbose bash install-wrappers.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${native_llvm_mingw_folder_name}/build-llvm.txt"

    (
      xbb_activate
      # For the new binaries to find the XBB libraries.
      xbb_activate_libs

      unset_gcc_env

      CFLAGS="-O2 -pipe -w"
      CXXFLAGS="-O2 -pipe -w"
      LDFLAGS=""

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      # unset CC
      # unset CXX

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      export PATH=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin:$PATH

      env | sort

      # -------------------------------------------------------------------
      # Inspired from Dockerfile.dev, by Martin Storsjo.
      # https://github.com/mstorsjo/llvm-mingw

      LLVM_MINGW_PATH="${BUILD_GIT_PATH}/scripts/llvm-mingw"

      DEFAULT_CRT=ucrt
      # DEFAULT_CRT=msvcrt

      # Build MinGW-w64
      cp -v "${LLVM_MINGW_PATH}/build-mingw-w64.sh" .
      run_verbose bash -x build-mingw-w64.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH} --with-default-msvcrt=$DEFAULT_CRT

      cp -v "${LLVM_MINGW_PATH}/build-mingw-w64-tools.sh" .
      run_verbose bash -x build-mingw-w64-tools.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

      # Build compiler-rt
      cp -v "${LLVM_MINGW_PATH}/build-compiler-rt.sh" .
      run_verbose bash -x build-compiler-rt.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

      # Build mingw-w64's extra libraries
      cp -v "${LLVM_MINGW_PATH}/build-mingw-w64-libraries.sh" .
      run_verbose bash -x build-mingw-w64-libraries.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

      VERBOSE_FLAG=""
      if [ "${IS_DEVELOP}" == "y" ]
      then
        VERBOSE_FLAG="-v"
      fi
      export VERBOSE_FLAG

      # Build C test applications
      (
        mkdir -p test
        cp -v "${LLVM_MINGW_PATH}/test"/*.c test
        cp -v "${LLVM_MINGW_PATH}/test"/*.h test
        cp -v "${LLVM_MINGW_PATH}/test"/*.idl test

        cd test 
        for arch in ${TOOLCHAIN_ARCHS}
        do 
          mkdir -p $arch 
          for test in hello hello-tls crt-test setjmp
          do 
              run_verbose $arch-w64-mingw32-clang $test.c -o $arch/$test.exe ${VERBOSE_FLAG} || exit 1
              run_app $arch/$test || exit 1
          done
          for test in autoimport-lib
          do 
              run_verbose $arch-w64-mingw32-clang $test.c -shared -o $arch/$test.dll -Wl,--out-implib,$arch/lib$test.dll.a ${VERBOSE_FLAG} || exit 1
          done
          for test in autoimport-main
          do 
              run_verbose $arch-w64-mingw32-clang $test.c -o $arch/$test.exe -L$arch -l${test%-main}-lib ${VERBOSE_FLAG} || exit 1
              run_app $arch/$test || exit 1
          done
          for test in idltest
          do
              # The IDL output isn't arch specific, but test each arch frontend 
              run_verbose $arch-w64-mingw32-widl $test.idl -h -o $arch/$test.h || exit 1
              run_verbose $arch-w64-mingw32-clang $test.c -I$arch -o $arch/$test.exe -lole32 ${VERBOSE_FLAG} || exit 1
              run_app $arch/$test || exit 1
          done
        done
      )

      # Build libunwind/libcxxabi/libcxx
      cp -v "${BUILD_GIT_PATH}/scripts/llvm-mingw/build-libcxx.sh" .
      run_verbose bash -x build-libcxx.sh ${NATIVE_LLVM_MINGW_FOLDER_PATH}

      # Build C++ test applications
      (
        cp -v "${LLVM_MINGW_PATH}/test"/*.cpp test 

        # Non-static EXE refer the libc++.dll, libunwind.dll, etc, thus
        # the temporary WINEPATH extension.
        cd test
        for arch in $TOOLCHAIN_ARCHS
        do
          mkdir -p $arch
          for test in hello-cpp hello-exception exception-locale exception-reduced global-terminate longjmp-cleanup; do
              run_verbose $arch-w64-mingw32-clang++ $test.cpp -o $arch/$test.exe ${VERBOSE_FLAG} || exit 1
              (
                export WINEPATH=${NATIVE_LLVM_MINGW_FOLDER_PATH}/$arch-w64-mingw32/bin 
                run_app $arch/$test || exit 1
              )
          done
          for test in hello-exception
          do
              run_verbose $arch-w64-mingw32-clang++ $test.cpp -static -o $arch/$test-static.exe ${VERBOSE_FLAG} || exit 1
              run_app $arch/$test-static || exit 1
          done
          for test in tlstest-lib throwcatch-lib
          do
              run_verbose $arch-w64-mingw32-clang++ $test.cpp -shared -o $arch/$test.dll -Wl,--out-implib,$arch/lib$test.dll.a ${VERBOSE_FLAG} || exit 1
          done
          for test in tlstest-main
          do
              run_verbose $arch-w64-mingw32-clang++ $test.cpp -o $arch/$test.exe ${VERBOSE_FLAG} || exit 1
              (
                export WINEPATH=${NATIVE_LLVM_MINGW_FOLDER_PATH}/$arch-w64-mingw32/bin 
                run_app $arch/$test || exit 1
              )
          done
          for test in throwcatch-main
          do
              run_verbose $arch-w64-mingw32-clang++ $test.cpp -o $arch/$test.exe -L$arch -l${test%-main}-lib ${VERBOSE_FLAG} || exit 1
              (
                export WINEPATH=${NATIVE_LLVM_MINGW_FOLDER_PATH}/$arch-w64-mingw32/bin 
                run_app $arch/$test || exit 1
              )
          done
        done
      )

      # Sanitizers?

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${native_llvm_mingw_folder_name}/build-libs.txt"

    touch "${native_llvm_mingw_stamp_file_path}"

  else
    echo "Component native-llvm-mingw already installed."
  fi

  tests_add "test_llvm_bootstrap"
}

# Not functional.
function _build_native_llvm() 
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
  # For GCC 11 it requires a patch to add <limits> to `benchmark_register.h`.
  # Fixed in 12.x.

  if [ "${TARGET_PLATFORM}" != "win32" ]
  then
    return
  fi

  local llvm_version="$1"

  local llvm_version_major=$(echo ${llvm_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')
  local llvm_version_minor=$(echo ${llvm_version} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')

  local llvm_src_folder_name="llvm-project-${llvm_version}.src"
  local llvm_folder_name="native-llvm-${llvm_version}"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${llvm_version}/${llvm_archive}"

  local llvm_patch_file_name="llvm-${llvm_version}.patch"

  local llvm_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_folder_name}-installed"
  if [ ! -f "${llvm_stamp_file_path}" ]
  then

    download_llvm

    mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_folder_name}"

    (
      xbb_activate

      # Use the XBB libraries.
      xbb_activate_dev
      xbb_activate_libs

      unset_gcc_env

      CC=${NATIVE_CC}
      CXX=${NATIVE_CXX}

      CPPFLAGS="${XBB_CPPFLAGS} -I${XBB_FOLDER_PATH}/include/ncurses"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      export CC
      export CXX
      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort

      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_folder_name}"

      if [ ! -f "config.status" ]
      then

        echo
        echo "Running native-llvm cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        config_options+=("-DCMAKE_C_COMPILER=${CC}")
        config_options+=("-DCMAKE_CXX_COMPILER=${CXX}")

        config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
        config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
        config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")

        # config_options+=("CURSES_INCLUDE_PATH=${XBB_FOLDER_PATH}/include/ncurses")

        config_options+=("-DCMAKE_INSTALL_PREFIX=${INSTALL_FOLDER_PATH}/native-${APP_LC_NAME}")
        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DLLVM_ENABLE_ASSERTIONS=OFF")
        config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
        config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")
        config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres")
        config_options+=("-DLLDB_INCLUDE_TESTS=OFF")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm"

        touch "config.status"
      fi

      run_verbose_timed cmake --build . --verbose
      run_verbose cmake --build . --verbose --target install/strip

      (
        cd "${BUILD_GIT_PATH}/scripts/llvm-mingw"

        export ARCHS=x86_64
        export TARGET_OSES=mingw32

        run_verbose ${DEBUG} "${BUILD_GIT_PATH}/scripts/llvm-mingw/install-wrappers.sh" \
          --host "${HOST}" \
          "${INSTALL_FOLDER_PATH}/native-${APP_LC_NAME}"

      )

    ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/cmake-output.txt"

    touch "${llvm_stamp_file_path}"

  else
    echo "Component native-llvm already installed."
  fi
}


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

  export ACTUAL_LLVM_VERSION="$1"

  local llvm_version_major=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\1|')
  local llvm_version_minor=$(echo ${ACTUAL_LLVM_VERSION} | sed -e 's|\([0-9][0-9]*\)\.\([0-9][0-9]*\)\..*|\2|')

  export llvm_src_folder_name="llvm-project-${ACTUAL_LLVM_VERSION}.src"
  local llvm_folder_name="llvm-${ACTUAL_LLVM_VERSION}"

  local llvm_archive="${llvm_src_folder_name}.tar.xz"
  local llvm_url="https://github.com/llvm/llvm-project/releases/download/llvmorg-${ACTUAL_LLVM_VERSION}/${llvm_archive}"

  local llvm_patch_file_name="llvm-${ACTUAL_LLVM_VERSION}.patch"

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
      for p in clang lld lldb; do
          if [ ! -e $p ]
          then
              ln -s ../../$p .
          fi
      done
    )

    mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_folder_name}"

      xbb_activate
      # Use install/libs/lib & include
      xbb_activate_installed_dev

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        # Use XBB libs in native-llvm
        xbb_activate_libs
      fi

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

        # The macOS variant needs to compile lots of .mm files
        # (in lldb, for example HostThreadMacOSX.mm), and
        # GCC chokes at them, making clang mandatory.

        export CC=clang
        export CXX=clang++
      elif [ "${TARGET_PLATFORM}" == "win32" ]
      then
        :
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

          # Please note the trailing space.
          config_options+=("-DCLANG_VENDOR=${LLVM_BRANDING} ")
          config_options+=("-DFLANG_VENDOR=${LLVM_BRANDING} ")
          config_options+=("-DLLD_VENDOR=${LLVM_BRANDING} ")
          config_options+=("-DPACKAGE_VENDOR=${LLVM_BRANDING} ")

          config_options+=("-DCLANG_EXECUTABLE_VERSION=${llvm_version_major}")
          config_options+=("-DCLANG_INCLUDE_TESTS=OFF")

          config_options+=("-DCMAKE_BUILD_TYPE=Release")
          config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")
          config_options+=("-DCMAKE_C_COMPILER=${CC}")
          config_options+=("-DCMAKE_CXX_COMPILER=${CXX}")
          config_options+=("-DCMAKE_C_FLAGS=${CPPFLAGS} ${CFLAGS}")
          config_options+=("-DCMAKE_CXX_FLAGS=${CPPFLAGS} ${CXXFLAGS}")
          config_options+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS}")
          # Prefer the locally compiled libraries.
          config_options+=("-DCMAKE_INCLUDE_PATH=${LIBS_INSTALL_FOLDER_PATH}/include")
          if [ -d "${LIBS_INSTALL_FOLDER_PATH}/lib64" ]
          then
            config_options+=("-DCMAKE_LIBRARY_PATH=${LIBS_INSTALL_FOLDER_PATH}/lib64;${LIBS_INSTALL_FOLDER_PATH}/lib")
          else
            config_options+=("-DCMAKE_LIBRARY_PATH=${LIBS_INSTALL_FOLDER_PATH}/lib")
          fi

          config_options+=("-DCOMPILER_RT_INCLUDE_TESTS=OFF")

          config_options+=("-DCUDA_64_BIT_DEVICE_CODE=OFF")

          config_options+=("-DCURSES_INCLUDE_PATH=${LIBS_INSTALL_FOLDER_PATH}/include/ncurses")

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
          # Better not, and use the explicit `llvm-*` names.
          # config_options+=("-DLLVM_INSTALL_BINUTILS_SYMLINKS=ON")
          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")

          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then

            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
            # config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")

            # To help find the just locally compiled `ld.gold`.
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
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")
            config_options+=("-DLLVM_ENABLE_FFI=ON")
            config_options+=("-DLLVM_HOST_TRIPLE=${TARGET}")
            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")
            # Fails with: Please use architecture with 4 or 8 byte pointers.
            # config_options+=("-DLLVM_RUNTIME_TARGETS=${TARGET}")

            # TODO
            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            # config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")

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

            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")

            # Set the default linker to gold, otherwise `-flto`
            # requires an expicit `-fuse-ld=gold`.
            config_options+=("-DCLANG_DEFAULT_LINKER=gold")

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
            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly;compiler-rt;libcxx;libcxxabi;libunwind")
            config_options+=("-DLLVM_ENABLE_FFI=ON")
            config_options+=("-DLLVM_HOST_TRIPLE=${TARGET}")
            # Unfortunately the LTO test fails with missing LLVMgold.so.
            # config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")
            config_options+=("-DLLVM_INSTALL_UTILS=ON")
            config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
            config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
            config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")
            config_options+=("-DLLVM_RUNTIME_TARGETS=${TARGET}")
            # config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-config;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres")
            config_options+=("-DLLVM_TOOL_GOLD_BUILD=ON")

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

          elif [ "${TARGET_PLATFORM}" == "win32" ]
          then

            config_options+=("-DCLANG_DEFAULT_CXX_STDLIB=libc++")
            config_options+=("-DCLANG_DEFAULT_LINKER=lld")
            config_options+=("-DCLANG_DEFAULT_RTLIB=compiler-rt")
            config_options+=("-DCLANG_TABLEGEN=${BUILD_LLVM_MINGW_PATH}/llvm-project/llvm/build/bin/clang-tblgen")
            
            config_options+=("-DCMAKE_CROSSCOMPILING=ON")
            config_options+=("-DCMAKE_CXX_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-g++")
            config_options+=("-DCMAKE_C_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-gcc")
            config_options+=("-DCMAKE_FIND_ROOT_PATH=${NATIVE_LLVM_MINGW_FOLDER_PATH}/${TARGET}")
            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY")
            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY")
            config_options+=("-DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER")
            config_options+=("-DCMAKE_RC_COMPILER=${CROSS_COMPILE_PREFIX}-windres")
            config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

            config_options+=("-DCROSS_TOOLCHAIN_FLAGS_NATIVE=")

            config_options+=("-DLLDB_TABLEGEN=${BUILD_LLVM_MINGW_PATH}/llvm-project/llvm/build/bin/lldb-tblgen")
            
            config_options+=("-DLLVM_CONFIG_PATH=${BUILD_LLVM_MINGW_PATH}/llvm-project/llvm/build/bin/llvm-config")
            config_options+=("-DLLVM_HOST_TRIPLE=${TARGET}")
            # Mind the links in llvm to clang, lld, lldb.
            config_options+=("-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON")
            config_options+=("-DLLVM_TABLEGEN=${BUILD_LLVM_MINGW_PATH}/llvm-project/llvm/build/bin/llvm-tblgen")
            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            config_options+=("-DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-config;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres")

            # https://llvm.org/docs/BuildingADistribution.html#options-for-reducing-size
            # This option is not available on Windows
            # config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")
            # config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")

            # compiler-rt, libunwind, libc++ and libc++-abi are built
            # in separate steps.

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

          touch "config.status"

        ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/cmake-output.txt"
      fi

      (
        echo
        echo "Running llvm build..."

        if [ "${IS_DEVELOP}" == "y" ]
        then
          run_verbose_timed cmake --build . --verbose
          run_verbose cmake --build .  --verbose  --target install/strip
        else
          run_verbose_timed cmake --build . 
          run_verbose cmake --build . --target install/strip
        fi

if true
then
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
            verify-uselistorder yaml-bench yaml2obj
          do
            rm -rfv $f $f${DOTEXE}
          done

          # So far not used.
          rm -rfv libclang.dll

          cd "${APP_PREFIX}/include"
          run_verbose rm -rf clang clang-c clang-tidy lld lldb llvm llvm-c polly

          cd "${APP_PREFIX}/lib"
          run_verbose rm -rfv libclang*.a libClangdXPCLib* libf*.a liblld*.a libLLVM*.a libPolly*.a
          # rm -rf cmake/lld cmake/llvm cmake/polly

          cd "${APP_PREFIX}/share"
          run_verbose rm -rf man
        )
fi

        show_libs "${APP_PREFIX}/bin/clang"
        show_libs "${APP_PREFIX}/bin/llvm-nm"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_folder_name}/build-output.txt"

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

function test_llvm_bootstrap()
{
  (
    # Use XBB libs in native-llvm
    xbb_activate_libs

    test_llvm "-native"
  )
}

function test_llvm()
{
  local native_suffix=${1-''}

  echo
  echo "Testing the llvm${native_suffix} binaries..."

  (
    if [ -n "${native_suffix}" ]
    then
      TEST_PREFIX="${INSTALL_FOLDER_PATH}/native-llvm-mingw"
      # Help the loader find the .dll files.
      export WINEPATH=${TEST_PREFIX}/${CROSS_COMPILE_PREFIX}/bin 

      CC="${TEST_PREFIX}/bin/${CROSS_COMPILE_PREFIX}-clang"
      CXX="${TEST_PREFIX}/bin/${CROSS_COMPILE_PREFIX}-clang++"
      DLLTOOL="${TEST_PREFIX}/bin/${CROSS_COMPILE_PREFIX}-dlltool"
      WIDL="${TEST_PREFIX}/bin/${CROSS_COMPILE_PREFIX}-widl"
      GENDEF="${TEST_PREFIX}/bin/gendef"
      AR="${TEST_PREFIX}/bin/${CROSS_COMPILE_PREFIX}-ar"
      RANLIB="${TEST_PREFIX}/bin/${CROSS_COMPILE_PREFIX}-ranlib"
    else
      TEST_PREFIX="${APP_PREFIX}"

      CC="${TEST_PREFIX}/bin/clang"
      CXX="${TEST_PREFIX}/bin/clang++"
      AR="${TEST_PREFIX}/bin/llvm-ar"
      RANLIB="${TEST_PREFIX}/bin/llvm-ranlib"
    fi

    show_libs "${TEST_PREFIX}/bin/clang"
    show_libs "${TEST_PREFIX}/bin/lld"
    show_libs "${TEST_PREFIX}/bin/lldb"

    echo
    echo "Testing if llvm binaries start properly..."

    run_app "${TEST_PREFIX}/bin/clang" --version
    run_app "${TEST_PREFIX}/bin/clang++" --version

    if [ -f "${TEST_PREFIX}/bin/clang-format${DOTEXE}" ]
    then
      run_app "${TEST_PREFIX}/bin/clang-format" --version
    fi

    # lld is a generic driver.
    # Invoke ld.lld (Unix), ld64.lld (macOS), lld-link (Windows), wasm-ld (WebAssembly) instead
    run_app "${TEST_PREFIX}/bin/lld" --version || true
    if [ "${TARGET_PLATFORM}" == "linux" ]
    then
      run_app "${TEST_PREFIX}/bin/ld.lld" --version || true
    elif [ "${TARGET_PLATFORM}" == "darwin" ]
    then
      run_app "${TEST_PREFIX}/bin/ld64.lld" --version || true
    elif [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${TEST_PREFIX}/bin/ld-link" --version || true
    fi

    run_app "${TEST_PREFIX}/bin/llvm-ar" --version
    run_app "${TEST_PREFIX}/bin/llvm-nm" --version
    run_app "${TEST_PREFIX}/bin/llvm-objcopy" --version
    run_app "${TEST_PREFIX}/bin/llvm-objdump" --version
    run_app "${TEST_PREFIX}/bin/llvm-ranlib" --version
    if [ -f "${TEST_PREFIX}/bin/llvm-readelf" ]
    then
      run_app "${TEST_PREFIX}/bin/llvm-readelf" --version
    fi
    if [ -f "${TEST_PREFIX}/bin/llvm-size" ]
    then
      run_app "${TEST_PREFIX}/bin/llvm-size" --version
    fi
    run_app "${TEST_PREFIX}/bin/llvm-strings" --version
    run_app "${TEST_PREFIX}/bin/llvm-strip" --version

    echo
    echo "Testing clang configuration..."

    run_app "${TEST_PREFIX}/bin/clang" -print-target-triple
    run_app "${TEST_PREFIX}/bin/clang" -print-targets
    run_app "${TEST_PREFIX}/bin/clang" -print-supported-cpus
    run_app "${TEST_PREFIX}/bin/clang" -print-search-dirs
    run_app "${TEST_PREFIX}/bin/clang" -print-resource-dir
    run_app "${TEST_PREFIX}/bin/clang" -print-libgcc-file-name

    # run_app "${TEST_PREFIX}/bin/llvm-config" --help

    echo
    echo "Testing if clang compiles simple Hello programs..."

    local tests_folder_path="${WORK_FOLDER_PATH}/${TARGET_FOLDER_NAME}"
    mkdir -pv "${tests_folder_path}/tests"
    local tmp="$(mktemp "${tests_folder_path}/tests/test-clang${native_suffix}-XXXXXXXXXX")"
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

    # -----------------------------------------------------------------------

    cp -v "${BUILD_GIT_PATH}/scripts/helper/tests/c-cpp"/* .

    # Test C compile and link in a single step.
    run_app "${CC}" ${VERBOSE_FLAG} -o hello-simple-c1${DOTEXE} hello-simple.c ${GC_SECTION}

    test_expect "hello-simple-c1" "Hello"

    # Static links are not supported, at least not with the Apple linker:
    # "/usr/bin/ld" -demangle -lto_library /Users/ilg/Work/clang-11.1.0-1/darwin-x64/install/clang/lib/libLTO.dylib -no_deduplicate -static -arch x86_64 -platform_version macos 10.10.0 0.0.0 -syslibroot /Library/Developer/CommandLineTools/SDKs/MacOSX.sdk -o static-hello-simple-c1 -lcrt0.o /var/folders/3h/98gc9hrn3qnfm40q7_0rxczw0000gn/T/hello-4bed56.o
    # ld: library not found for -lcrt0.o
    # run_app "${TEST_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o static-hello-simple-c1 hello-simple.c -static
    # test_expect "static-hello-simple-c1" "Hello"

    # Test C compile and link in separate steps.
    run_app "${CC}" -o hello-simple-c.o -c hello-simple.c
    run_app "${CC}" ${VERBOSE_FLAG} -o hello-simple-c2${DOTEXE} hello-simple-c.o ${GC_SECTION}

    test_expect "hello-simple-c2" "Hello"

    # Test LTO C compile and link in a single step.
    run_app "${CC}" ${VERBOSE_FLAG} -flto -o lto-hello-simple-c1${DOTEXE} hello-simple.c ${GC_SECTION}

    test_expect "lto-hello-simple-c1" "Hello"

    # Test LTO C compile and link in separate steps.
    run_app "${CC}" -flto -o lto-hello-simple-c.o -c hello-simple.c
    run_app "${CC}" ${VERBOSE_FLAG} -flto -o lto-hello-simple-c2${DOTEXE} lto-hello-simple-c.o ${GC_SECTION}

    test_expect "lto-hello-simple-c2" "Hello"

    # Test C compile and link in a single step.
    run_app "${CC}" ${VERBOSE_FLAG} -o rt-hello-simple-c1${DOTEXE} hello-simple.c -rtlib=compiler-rt ${GC_SECTION}

    test_expect "rt-hello-simple-c1" "Hello"

    # Test C compile and link in separate steps.
    run_app "${CC}" -o hello-simple-c.o -c hello-simple.c
    run_app "${CC}" ${VERBOSE_FLAG} -o rt-hello-simple-c2${DOTEXE} hello-simple-c.o -rtlib=compiler-rt ${GC_SECTION}

    test_expect "rt-hello-simple-c2" "Hello"

    # Test LTO C compile and link in a single step.
    run_app "${CC}" ${VERBOSE_FLAG} -flto -o rt-lto-hello-simple-c1${DOTEXE} hello-simple.c -rtlib=compiler-rt ${GC_SECTION}

    test_expect "rt-lto-hello-simple-c1" "Hello"

    # Test LTO C compile and link in separate steps.
    run_app "${CC}" -flto -o lto-hello-simple-c.o -c hello-simple.c
    run_app "${CC}" ${VERBOSE_FLAG} -flto -o rt-lto-hello-simple-c2${DOTEXE} lto-hello-simple-c.o -rtlib=compiler-rt ${GC_SECTION}

    test_expect "rt-lto-hello-simple-c2" "Hello"

    # -----------------------------------------------------------------------

    # Test C++ compile and link in a single step.
    run_app "${CXX}" ${VERBOSE_FLAG} -o hello-simple-cpp1${DOTEXE} hello-simple.cpp ${GC_SECTION}

    test_expect "hello-simple-cpp1" "Hello"

    # Test C++ compile and link in separate steps.
    run_app "${CXX}" -o hello-simple-cpp.o -c hello-simple.cpp
    run_app "${CXX}" ${VERBOSE_FLAG} -o hello-simple-cpp2${DOTEXE} hello-simple-cpp.o ${GC_SECTION}

    test_expect "hello-simple-cpp2" "Hello"

    # Test LTO C++ compile and link in a single step.
    run_app "${CXX}" ${VERBOSE_FLAG} -flto -o lto-hello-simple-cpp1${DOTEXE} hello-simple.cpp ${GC_SECTION}

    test_expect "lto-hello-simple-cpp1" "Hello"

    # Test LTO C++ compile and link in separate steps.
    run_app "${CXX}" -flto -o lto-hello-simple-cpp.o -c hello-simple.cpp
    run_app "${CXX}" ${VERBOSE_FLAG} -flto -o lto-hello-simple-cpp2${DOTEXE} lto-hello-simple-cpp.o ${GC_SECTION}

    test_expect "lto-hello-simple-cpp2" "Hello"

    # Test C++ compile and link in a single step.
    run_app "${CXX}" ${VERBOSE_FLAG} -o rt-hello-simple-cpp1${DOTEXE} hello-simple.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

    test_expect "rt-hello-simple-cpp1" "Hello"

    # Test C++ compile and link in separate steps.
    run_app "${CXX}" -o hello-simple-cpp.o -c hello-simple.cpp -stdlib=libc++
    run_app "${CXX}" ${VERBOSE_FLAG} -o rt-hello-simple-cpp2${DOTEXE} hello-simple-cpp.o -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

    test_expect "rt-hello-simple-cpp2" "Hello"

    # Test LTO C++ compile and link in a single step.
    run_app "${CXX}" ${VERBOSE_FLAG} -flto -o rt-lto-hello-simple-cpp1${DOTEXE} hello-simple.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

    test_expect "rt-lto-hello-simple-cpp1" "Hello"

    # Test LTO C++ compile and link in separate steps.
    run_app "${CXX}" -flto -o lto-hello-simple-cpp.o -c hello-simple.cpp -stdlib=libc++
    run_app "${CXX}" ${VERBOSE_FLAG} -flto -o rt-lto-hello-simple-cpp2${DOTEXE} lto-hello-simple-cpp.o -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

    test_expect "rt-lto-hello-simple-cpp2" "Hello"

    # -----------------------------------------------------------------------

    # -O0 is an attempt to prevent any interferences with the optimiser.
    run_app "${CXX}" ${VERBOSE_FLAG} -o except${DOTEXE} -O0 except.cpp ${GC_SECTION}

    if [ "${TARGET_PLATFORM}" != "darwin" ]
    then
      # on Darwin: 'Symbol not found: __ZdlPvm'
      test_expect "except" "MyException"
    fi

    run_app "${CXX}" ${VERBOSE_FLAG} -o rt-except${DOTEXE} -O0 except.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}

    if [ "${TARGET_PLATFORM}" != "darwin" ]
    then
      # on Darwin: 'Symbol not found: __ZdlPvm'
      test_expect "rt-except" "MyException"
    fi

    # -O0 is an attempt to prevent any interferences with the optimiser.
    run_app "${CXX}" ${VERBOSE_FLAG} -o str-except${DOTEXE} -O0 str-except.cpp ${GC_SECTION}
    
    test_expect "str-except" "MyStringException"

    # -O0 is an attempt to prevent any interferences with the optimiser.
    run_app "${CXX}" ${VERBOSE_FLAG} -o rt-str-except${DOTEXE} -O0 str-except.cpp -rtlib=compiler-rt -stdlib=libc++ ${GC_SECTION}
    
    test_expect "rt-str-except" "MyStringException"

    # -----------------------------------------------------------------------

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" -o add.o -c add.c
    else
      run_app "${CC}" -o add.o -fpic -c add.c
    fi

    rm -rf libadd.a
    run_app "${AR}" -r ${VERBOSE_FLAG} libadd-static.a add.o
    run_app "${RANLIB}" libadd-static.a

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # The `--out-implib` crreates an import library, which can be
      # directly used with -l.
      run_app "${CC}" ${VERBOSE_FLAG} -shared -o libadd-shared.dll -Wl,--out-implib,libadd-shared.dll.a add.o -Wl,--subsystem,windows 

      # Alternately it is possible to create the similar .lib with dlltool.
      run_app "${GENDEF}" libadd-shared.dll
      run_app "${DLLTOOL}" -m i386:x86-64 -d libadd-shared.def -l libadd-shared.lib
    else
      run_app "${CC}" -o libadd-shared.so -shared add.o
    fi

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" -o rt-add.o -c add.c
    else
      run_app "${CC}" -o rt-add.o -fpic -c add.c
    fi

    rm -rf libadd.a
    run_app "${AR}" -r ${VERBOSE_FLAG} librt-add-static.a rt-add.o 
    run_app "${RANLIB}" librt-add-static.a

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      run_app "${CC}" -shared -o librt-add-shared.dll -Wl,--out-implib,librt-add-shared.dll.a rt-add.o -rtlib=compiler-rt
    else
      run_app "${CC}" -o librt-add-shared.so -shared rt-add.o -rtlib=compiler-rt
    fi

    run_app "${CC}" ${VERBOSE_FLAG} -o static-adder${DOTEXE} adder.c -ladd-static -L . ${GC_SECTION}

    test_expect "static-adder" "42" 40 2

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # -ladd-shared is in fact libadd-shared.dll.a
      # The library does not show as DLL, it is loaded dynamically.
      run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder${DOTEXE} adder.c -ladd-shared -L . ${GC_SECTION}

      # Example with .lib, which must be passed with full name.
      run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder-lib${DOTEXE} adder.c libadd-shared.lib -L . ${GC_SECTION}
    else
      run_app "${CC}" ${VERBOSE_FLAG} -o shared-adder adder.c -ladd-shared -L . ${GC_SECTION}
    fi

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
      test_expect "shared-adder" "42" 40 2
    )

    run_app "${CC}" ${VERBOSE_FLAG} -o rt-static-adder${DOTEXE} adder.c -lrt-add-static -L . -rtlib=compiler-rt ${GC_SECTION}

    test_expect "rt-static-adder" "42" 40 2

    if [ "${TARGET_PLATFORM}" == "win32" ]
    then
      # -lrt-add-shared is in fact librt-add-shared.dll.a
      # The library does not show as DLL, it is loaded dynamically.
      run_app "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder${DOTEXE} adder.c -lrt-add-shared -L . -rtlib=compiler-rt ${GC_SECTION}
    else
      run_app "${CC}" ${VERBOSE_FLAG} -o rt-shared-adder adder.c -lrt-add-shared -L . -rtlib=compiler-rt ${GC_SECTION}
    fi

    (
      LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
      export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
      test_expect "rt-shared-adder" "42" 40 2
    )

    # -----------------------------------------------------------------------
    # Tests from the llvm-mingw project.

    for test in hello hello-tls crt-test setjmp
    do 
        run_verbose "${CC}" $test.c -o $test.exe ${VERBOSE_FLAG} 
        run_app $test
    done
    for test in autoimport-lib
    do 
        run_verbose "${CC}" $test.c -shared -o $test.dll -Wl,--out-implib,lib$test.dll.a ${VERBOSE_FLAG} 
    done
    for test in autoimport-main
    do 
        run_verbose "${CC}" $test.c -o $test.exe -L. -l${test%-main}-lib ${VERBOSE_FLAG}
        run_app $test
    done
    for test in idltest
    do
        # The IDL output isn't arch specific, but test each arch frontend 
        run_verbose "${WIDL}" $test.idl -h -o $test.h 
        run_verbose "${CC}" $test.c -I. -o $test.exe -lole32 ${VERBOSE_FLAG} 
        run_app $test 
    done

    for test in hello-cpp hello-exception exception-locale exception-reduced global-terminate longjmp-cleanup
    do
        run_verbose ${CXX} $test.cpp -o $test.exe ${VERBOSE_FLAG}
        run_app $test
    done
    for test in hello-exception
    do
        run_verbose ${CXX} $test.cpp -static -o $test-static.exe ${VERBOSE_FLAG}
        run_app $test-static
    done
    for test in tlstest-lib throwcatch-lib
    do
        run_verbose ${CXX} $test.cpp -shared -o $test.dll -Wl,--out-implib,lib$test.dll.a ${VERBOSE_FLAG}
    done
    for test in tlstest-main
    do
        run_verbose ${CXX} $test.cpp -o $test.exe ${VERBOSE_FLAG}
        run_app $test 
    done
    for test in throwcatch-main
    do
        run_verbose ${CXX} $test.cpp -o $test.exe -L. -l${test%-main}-lib ${VERBOSE_FLAG}
        run_app $test
    done

  )

  echo
  echo "Testing the llvm${native_suffix} binaries completed successfuly."
}


function build_llvm_compiler_rt()
{
  local llvm_compiler_rt_folder_name="llvm-${ACTUAL_LLVM_VERSION}-compiler-rt"

  local llvm_compiler_rt_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_compiler_rt_folder_name}-installed"
  if [ ! -f "${llvm_compiler_rt_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}"

      xbb_activate
      # Use install/libs/lib & include
      xbb_activate_installed_dev

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        # Use XBB libs in native-llvm
        xbb_activate_libs
      fi

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort
     
      (
        echo
        echo "Running llvm-compiler-rt cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        # Traditionally the runtime is in a versioned folder.
        config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}/lib/clang/${ACTUAL_LLVM_VERSION}")

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

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

        config_options+=("-DCMAKE_AR=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ranlib")

        config_options+=("-DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON")
        config_options+=("-DCOMPILER_RT_USE_BUILTINS_LIBRARY=ON")
        config_options+=("-DSANITIZER_CXX_ABI=libc++")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/compiler-rt/lib/builtins"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/cmake-output.txt"

      (
        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_compiler_rt_folder_name}/build-output.txt"

    )

    touch "${llvm_compiler_rt_stamp_file_path}"

  else
    echo "Component llvm-compiler-rt already installed."
  fi

}

function build_llvm_libcxx()
{
  local llvm_libunwind_folder_name="llvm-${ACTUAL_LLVM_VERSION}-libunwind"

  local llvm_libunwind_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libunwind_folder_name}-installed"
  if [ ! -f "${llvm_libunwind_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libunwind_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libunwind_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}"

      xbb_activate
      # Use install/libs/lib & include
      xbb_activate_installed_dev

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        # Use XBB libs in native-llvm
        xbb_activate_libs
      fi

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort
     
      (
        echo
        echo "Running llvm-libunwind cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ranlib")

        config_options+=("-DLIBUNWIND_ENABLE_THREADS=ON")
        config_options+=("-DLIBUNWIND_ENABLE_SHARED=OFF")
        config_options+=("-DLIBUNWIND_ENABLE_STATIC=ON")
        config_options+=("-DLIBUNWIND_ENABLE_CROSS_UNWINDING=OFF")
        config_options+=("-DLIBUNWIND_USE_COMPILER_RT=ON")

        config_options+=("-DLLVM_PATH=${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/llvm")

        run_verbose cmake \
          "${config_options[@]}" \
          "${SOURCES_FOLDER_PATH}/${llvm_src_folder_name}/libunwind"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}/cmake-output.txt"

      (
        run_verbose cmake --build . --verbose
        run_verbose cmake --build . --verbose --target install/strip

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libunwind_folder_name}/build-output.txt"

    )

    touch "${llvm_libunwind_stamp_file_path}"

  else
    echo "Component llvm-libunwind already installed."
  fi

  # ---------------------------------------------------------------------------

  # Define & prepare the folder, will be used later.
  local llvm_libcxxabi_folder_name="llvm-${ACTUAL_LLVM_VERSION}-libcxxabi"
  mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

  local llvm_libcxx_folder_name="llvm-${ACTUAL_LLVM_VERSION}-libcxx"

  local llvm_libcxx_headers_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-headers-installed"
  if [ ! -f "${llvm_libcxx_headers_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      xbb_activate
      # Use install/libs/lib & include
      xbb_activate_installed_dev

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        # Use XBB libs in native-llvm
        xbb_activate_libs
      fi

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      env | sort
     
      (
        echo
        echo "Running llvm-libcxx-headers cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ranlib")

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

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/cmake-output.txt"

      (
        # Configure, but don't build libcxx yet, so that libcxxabi has
        # proper headers to refer to.
        run_verbose cmake --build . --verbose --target generate-cxx-headers

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/generate-cxx-headeres-output.txt"

    )

    touch "${llvm_libcxx_headers_stamp_file_path}"

  else
    echo "Component llvm-libcxx-headers already installed."
  fi

  local llvm_libcxxabi_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libcxxabi_folder_name}-installed"
  if [ ! -f "${llvm_libcxxabi_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}"

      xbb_activate
      # Use install/libs/lib & include
      xbb_activate_installed_dev

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        # Use XBB libs in native-llvm
        xbb_activate_libs
      fi

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS
      # Most probably not used

      env | sort
     
      (
        echo
        echo "Running llvm-libcxxabi cmake..."

        config_options=()
        config_options+=("-G" "Ninja")

        config_options+=("-DCMAKE_INSTALL_PREFIX=${APP_PREFIX}")

        config_options+=("-DCMAKE_BUILD_TYPE=Release")
        config_options+=("-DCMAKE_CROSSCOMPILING=ON")
        config_options+=("-DCMAKE_SYSTEM_NAME=Windows")

        config_options+=("-DCMAKE_C_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang")
        config_options+=("-DCMAKE_C_COMPILER_WORKS=ON")
        config_options+=("-DCMAKE_CXX_COMPILER=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/${CROSS_COMPILE_PREFIX}-clang++")
        config_options+=("-DCMAKE_CXX_COMPILER_WORKS=ON")

        config_options+=("-DCMAKE_AR=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ar")
        config_options+=("-DCMAKE_RANLIB=${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ranlib")

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

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/cmake-output.txt"

      (
        # Configure, but don't build libcxxabi yet, so that libcxxabi has
        # proper headers to refer to.
        run_verbose cmake --build . --verbose

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxxabi_folder_name}/build-output.txt"

    )

    touch "${llvm_libcxxabi_stamp_file_path}"

  else
    echo "Component llvm-libcxxabi already installed."
  fi

  local llvm_libcxx_stamp_file_path="${STAMPS_FOLDER_PATH}/stamp-${llvm_libcxx_folder_name}-installed"
  if [ ! -f "${llvm_libcxx_stamp_file_path}" ]
  then
    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}"

      xbb_activate
      # Use install/libs/lib & include
      xbb_activate_installed_dev

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        # Use XBB libs in native-llvm
        xbb_activate_libs
      fi

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"

      if [ "${IS_DEVELOP}" == "y" ]
      then
        LDFLAGS+=" -v"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS
      # Most probably not used

      env | sort

      (
        run_verbose cmake --build . --verbose 
        run_verbose cmake --build . --verbose --target install/strip

        # Append libunwind
        run_verbose ${NATIVE_LLVM_MINGW_FOLDER_PATH}/bin/llvm-ar qcsL \
                "${APP_PREFIX}/lib/libc++.a" \
                "${APP_PREFIX}/lib/libunwind.a"

      ) 2>&1 | tee "${LOGS_FOLDER_PATH}/${llvm_libcxx_folder_name}/build-output.txt"

    )

    touch "${llvm_libcxx_stamp_file_path}"

  else
    echo "Component llvm-libcxx already installed."
  fi

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
