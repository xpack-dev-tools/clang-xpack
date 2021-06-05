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

function build_llvm() 
{
  # https://llvm.org
  # https://llvm.org/docs/GettingStarted.html
  # https://github.com/llvm/llvm-project/
  # https://github.com/llvm/llvm-project/releases/
  # https://github.com/llvm/llvm-project/releases/tag/llvmorg-11.1.0/
  # https://github.com/llvm/llvm-project/releases/download/llvmorg-11.1.0/llvm-project-11.1.0.src.tar.xz

  # https://archlinuxarm.org/packages/aarch64/llvm/files/PKGBUILD

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

    mkdir -pv "${LOGS_FOLDER_PATH}/${llvm_folder_name}"

    (
      mkdir -p "${BUILD_FOLDER_PATH}/${llvm_folder_name}"
      cd "${BUILD_FOLDER_PATH}/${llvm_folder_name}"

      xbb_activate
      xbb_activate_installed_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"
      LDFLAGS="${XBB_LDFLAGS_APP}"
      
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

          config_options+=("-DLLVM_ENABLE_DOXYGEN=OFF")
          config_options+=("-DLLVM_ENABLE_EH=ON")
          config_options+=("-DLLVM_ENABLE_FFI=ON")
          config_options+=("-DLLVM_ENABLE_LIBCXX=ON")

          if [ "${IS_DEVELOP}" == "y" ]
          then
            config_options+=("-DLLVM_ENABLE_LTO=OFF")
          else
            # Build LLVM with -flto.
            config_options+=("-DLLVM_ENABLE_LTO=ON")
          fi

          if true
          then
            # No openmp,mlir
            # flang fails:
            # .../flang/runtime/io-stmt.h:65:17: error: 'visit<(lambda at /Users/ilg/Work/clang-11.1.0-1/darwin-x64/sources/llvm-project-11.1.0.src/flang/runtime/io-stmt.h:66:9), const std::__1::variant<std::__1::reference_wrapper<Fortran::runtime::io::OpenStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::CloseStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::NoopCloseStatementState>, std::__1::reference_wrapper<Fortran::runtime::io::InternalFormattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalFormattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalListIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::InternalListIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalFormattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalFormattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalListIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalListIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::UnformattedIoStatementState<Direction::Output>>, std::__1::reference_wrapper<Fortran::runtime::io::UnformattedIoStatementState<Direction::Input>>, std::__1::reference_wrapper<Fortran::runtime::io::ExternalMiscIoStatementState>> &>' is unavailable: introduced in macOS 10.13

            config_options+=("-DLLVM_ENABLE_PROJECTS=clang;clang-tools-extra;lld;lldb;polly")
            config_options+=("-DLLVM_ENABLE_RUNTIMES=compiler-rt;libcxx;libcxxabi;libunwind")
          else
            # Development options, to reduce build time.
            config_options+=("-DLLVM_ENABLE_PROJECTS=")
            config_options+=("-DLLVM_ENABLE_RUNTIMES=")
          fi

          config_options+=("-DLLVM_ENABLE_RTTI=ON")
          config_options+=("-DLLVM_ENABLE_SPHINX=OFF")
          config_options+=("-DLLVM_ENABLE_WARNINGS=OFF")
          config_options+=("-DLLVM_ENABLE_Z3_SOLVER=OFF")

          config_options+=("-DLLVM_INCLUDE_DOCS=OFF") # No docs
          config_options+=("-DLLVM_INCLUDE_TESTS=OFF") # No tests

          config_options+=("-DLLVM_INSTALL_UTILS=ON")
          config_options+=("-DLLVM_LINK_LLVM_DYLIB=ON")
          config_options+=("-DLLVM_OPTIMIZED_TABLEGEN=ON")
          config_options+=("-DLLVM_POLLY_LINK_INTO_TOOLS=ON")

          # config_options+=("-DPYTHON_EXECUTABLE=${INSTALL_FOLDER_PATH}/bin/python3")
          # config_options+=("-DPython3_EXECUTABLE=python3")

          config_options+=("-DLLVM_PARALLEL_LINK_JOBS=1")
          config_options+=("-DLLVM_INSTALL_BINUTILS_SYMLINKS=ON")

          # Cannot enable BUILD_SHARED_LIBS with LLVM_LINK_LLVM_DYLIB.  We recommend
          # disabling BUILD_SHARED_LIBS.
          # config_options+=("-DBUILD_SHARED_LIBS=ON")

          if [ "${TARGET_PLATFORM}" == "darwin" ]
          then

            set_macos_sdk_path

            # Copy the SDK in the distribution, to have a standalone package.
            copy_macos_sdk "${MACOS_SDK_PATH}"

            config_options+=("-DDEFAULT_SYSROOT=${MACOS_SDK_PATH}")

            # TODO
            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            # config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")

            # Prefer the locally compiled libraries.
            config_options+=("-DCMAKE_LIBRARY_PATH=${LIBS_INSTALL_FOLDER_PATH}/lib")

            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

          elif [ "${TARGET_PLATFORM}" == "linux" ]
          then

            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")
            # config_options+=("-DLLVM_TARGETS_TO_BUILD=AArch64")
            # config_options+=("-DLLVM_TARGETS_TO_BUILD=ARM")

            config_options+=("-DLLVM_USE_LINKER=gold")

            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

          elif [ "${TARGET_PLATFORM}" == "win32" ]
          then

            config_options+=("-DLLVM_TARGETS_TO_BUILD=X86")

            config_options+=("-DLLVM_USE_LINKER=gold")

            config_options+=("-DLLVM_BUILD_LLVM_C_DYLIB=ON")
            config_options+=("-DLLVM_BUILD_LLVM_DYLIB=ON")

          else
            echo "Oops! Unsupported ${TARGET_PLATFORM}."
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

       run_verbose_timed cmake --build . \
          --verbose \

        run_verbose cmake --build . \
          --verbose \
          --target install \

        # show_libs "${APP_PREFIX}/bin/clang"
        # show_libs "${APP_PREFIX}/bin/clang++"


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


    # Cannot run the the compiler without a loader.
    if [ "${TARGET_PLATFORM}" != "win32" ]
    then

      echo
      echo "Testing if gcc compiles simple Hello programs..."

      local tmp="$(mktemp ~/tmp/test-gcc-XXXXXXXXXX)"
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
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o hello-c1 hello.c

      test_expect "hello-c1" "Hello"

      # Test C compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang" -o hello-c.o -c hello.c
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o hello-c2 hello-c.o

      test_expect "hello-c2" "Hello"

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o static-hello-c2 hello-c.o

      test_expect "static-hello-c2" "Hello"

      # Test LTO C compile and link in a single step.
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o lto-hello-c1 hello.c

      test_expect "lto-hello-c1" "Hello"

      # Test LTO C compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang" -flto -o lto-hello-c.o -c hello.c
      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o lto-hello-c2 lto-hello-c.o

      test_expect "lto-hello-c2" "Hello"

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -flto -o static-lto-hello-c2 lto-hello-c.o

      test_expect "static-lto-hello-c2" "Hello"

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
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o hello-cpp1 hello.cpp

      test_expect "hello-cpp1" "Hello"

      # Test C++ compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang++" -o hello-cpp.o -c hello.cpp
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o hello-cpp2 hello-cpp.o

      test_expect "hello-cpp2" "Hello"

      # Note: macOS linker ignores -static-libstdc++
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -static-libstdc++ -o static-hello-cpp2 hello-cpp.o

      test_expect "static-hello-cpp2" "Hello"

      # Test LTO C++ compile and link in a single step.
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -flto -o lto-hello-cpp1 hello.cpp

      test_expect "lto-hello-cpp1" "Hello"

      # Test LTO C++ compile and link in separate steps.
      run_app "${APP_PREFIX}/bin/clang++" -flto -o lto-hello-cpp.o -c hello.cpp
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -flto -o lto-hello-cpp2 lto-hello-cpp.o

      test_expect "lto-hello-cpp2" "Hello"

      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -static-libstdc++ -flto -o static-lto-hello-cpp2 lto-hello-cpp.o

      test_expect "static-lto-hello-cpp2" "Hello"

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
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o except -O0 except.cpp

      if [ "${TARGET_PLATFORM}" != "darwin" ]
      then
        # on Darwin: 'Symbol not found: __ZdlPvm'
        test_expect "except" "MyException"
      fi

      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -static-libstdc++ -o static-except -O0 except.cpp

      test_expect "static-except" "MyException"

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
      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -o str-except -O0 str-except.cpp
      
      test_expect "str-except" "MyStringException"

      run_app "${APP_PREFIX}/bin/clang++" ${VERBOSE_FLAG} -static-libstdc++ -o static-str-except -O0 str-except.cpp

      test_expect "static-str-except" "MyStringException"

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
      if false # [ "${TARGET_PLATFORM}" == "darwin" ]
      then
        run_app "ar" -r ${VERBOSE_FLAG} libadd-static.a add.o
        run_app "ranlib" libadd-static.a
      else
        run_app "${APP_PREFIX}/bin/ar" -r ${VERBOSE_FLAG} libadd-static.a add.o
        run_app "${APP_PREFIX}/bin/ranlib" libadd-static.a
      fi

      # No gcc-ar/gcc-ranlib on Darwin/mingw; problematic with clang.

      if [ "${TARGET_PLATFORM}" == "win32" ]
      then
        run_app "${APP_PREFIX}/bin/clang" -o libadd-shared.dll -shared add.o -Wl,--subsystem,windows
      else
        run_app "${APP_PREFIX}/bin/clang" -o libadd-shared.so -shared add.o
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

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o static-adder adder.c -ladd-static -L .

      test_expect "static-adder" "42" 40 2

      run_app "${APP_PREFIX}/bin/clang" ${VERBOSE_FLAG} -o shared-adder adder.c -ladd-shared -L .

      (
        LD_LIBRARY_PATH=${LD_LIBRARY_PATH:-""}
        export LD_LIBRARY_PATH=$(pwd):${LD_LIBRARY_PATH}
        test_expect "shared-adder" "42" 40 2
      )

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
            echo "Oops! Unsupported ${TARGET_ARCH}."
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
