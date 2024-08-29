# Developer info for mstorsjo/llvm-mingw

The build scripts producing Windows binaries are inspired by the project
[llvm-mingw](https://github.com/mstorsjo/llvm-mingw),
maintained by Martin Storsjö.

To get the actual configurations, the easiest way is to run the builds with
the shell debug option enabled, and capture the console output.

The direct invocation of the build script on an Ubuntu 18 fails,
since cmake is too old, thus it is preferred to use the Docker builds.

For this, on `xbbli`:

```sh
rm -rf ~/Work/mstorsjo/llvm-mingw.git
mkdir -pv ~/Work/mstorsjo
git clone https://github.com/mstorsjo/llvm-mingw ~/Work/mstorsjo/llvm-mingw.git

# or, if already cloned:
# git -C ~/Work/mstorsjo/llvm-mingw.git pull
```

Here include version specific patch, see below.

```sh
sed -i.bak2 \
-e 's|TOOLCHAIN_ARCHS="i686 x86_64 armv7 aarch64"|TOOLCHAIN_ARCHS="i686 x86_64"|' \
-e 's|TOOLCHAIN_ARCHS-i686 x86_64 armv7 aarch64|TOOLCHAIN_ARCHS-i686 x86_64|' \
-e 's|arch in i686 x86_64 armv7 aarch64|arch in i686 x86_64|' \
-e 's|-DLLVM_TARGETS_TO_BUILD="ARM;AArch64;X86"|-DLLVM_TARGETS_TO_BUILD="X86"|' \
~/Work/mstorsjo/llvm-mingw.git/Dockerfile* ~/Work/mstorsjo/llvm-mingw.git/*.sh

# Patch the shell scripts to add -x.
find ~/Work/mstorsjo/llvm-mingw.git -name '*.sh' ! -iname '*-wrapper.sh' \
  -exec sed -i.bak3 -e 's|^#!/bin/sh$|#!/bin/sh -x|' -e 's|cmake [\]|cmake -LAH \\|' '{}' ';'

docker system prune --force

cd ~/Work/mstorsjo/llvm-mingw.git

LLVM_VERSION="$(grep "LLVM_VERSION:=" build-llvm.sh | sed -e "s|^.*llvmorg-||" | sed -e s"|}||")"
echo "LLVM_VERSION=${LLVM_VERSION}"

# Build the development docker image.
docker build --no-cache --progress plain -f Dockerfile.dev -t mstorsjo/llvm-mingw:dev . 2>&1 | tee "../build-output-x-dev-$(date -u +%Y%m%d-%H%M%S)-${LLVM_VERSION}.txt"

# Build the cross binaries.
docker build --no-cache --progress plain -f Dockerfile.cross -t mstorsjo/llvm-mingw:cross . 2>&1 | tee "../build-output-x-cross-$(date -u +%Y%m%d-%H%M%S)-${LLVM_VERSION}.txt"

# Build the regular binaries. (?)
docker build --progress plain -t mstorsjo/llvm-mingw . 2>&1 | tee "../build-output-x-$(date -u +%Y%m%d-%H%M%S)-${LLVM_VERSION}.txt"
```

<https://github.com/mstorsjo/llvm-mingw/releases/>

## v17.0.2 - 2023-10

<https://github.com/mstorsjo/llvm-mingw/releases/20231003>

## v16.0.6 - 2023-07-31

<https://github.com/mstorsjo/llvm-mingw/releases/tag/20230614>

```sh
git -C ~/Work/mstorsjo/llvm-mingw.git checkout 20230614

LLVM_VERSION="16.0.6"

# sed -i.bak2 -e 's|{LLVM_VERSION:=llvmorg-.*}|{LLVM_VERSION:=llvmorg-16.0.6}|' ~/Work/mstorsjo/llvm-mingw.git/build-llvm.sh

# https://github.com/mirror/mingw-w64/tags
sed -i.bak -e 's|{MINGW_W64_VERSION:=.*}|{MINGW_W64_VERSION:=v11.0.0}|' ~/Work/mstorsjo/llvm-mingw.git/build-mingw-w64.sh
```

For `mstorsjo/llvm-mingw:dev` (actualy build-output-x-dev-*.txt):

```console
#11 [ 6/33] RUN ./build-llvm.sh /opt/llvm-mingw

#11 82.91 + cd llvm-project/llvm

#11 82.91 + cmake -LAH -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size ..

#11 94.59 + ninja install/strip

#13 [ 8/33] RUN ./build-lldb-mi.sh /opt/llvm-mingw
#13 2.117 + cmake -LAH -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw -DCMAKE_BUILD_TYPE=Release ..
#13 3.284 + ninja install/strip

#15 [10/33] RUN ./strip-llvm.sh /opt/llvm-mingw

#16 [11/33] COPY wrappers/*.sh wrappers/*.c wrappers/*.h ./wrappers/
#17 [12/33] COPY install-wrappers.sh ./
#18 [13/33] RUN ./install-wrappers.sh /opt/llvm-mingw

#20 18.46 + cd mingw-w64-headers
#20 18.46 + cd build
#20 18.46 + ../configure --prefix=/opt/llvm-mingw/generic-w64-mingw32 --enable-idl --with-default-win32-winnt=0x601 --with-default-msvcrt=ucrt INSTALL=install -C

#20 19.86 + cd mingw-w64-crt
#20 19.86 + FLAGS=--enable-lib32 --disable-lib64 --with-default-msvcrt=ucrt
#20 19.86 + ../configure --host=i686-w64-mingw32 --prefix=/opt/llvm-mingw/i686-w64-mingw32 --enable-lib32 --disable-lib64 --with-default-msvcrt=ucrt --enable-cfguard

#20 41.66 + cd ..
#20 41.66 + cd build-x86_64
#20 41.66 + FLAGS=--disable-lib32 --enable-lib64 --with-default-msvcrt=ucrt
#20 41.66 + ../configure --host=x86_64-w64-mingw32 --prefix=/opt/llvm-mingw/x86_64-w64-mingw32 --disable-lib32 --enable-lib64 --with-default-msvcrt=ucrt --enable-cfguard

#22 [17/33] RUN ./build-mingw-w64-tools.sh /opt/llvm-mingw
#22 0.403 + cd mingw-w64-tools/gendef
#22 0.404 + cd build
#22 0.404 + ../configure --prefix=/opt/llvm-mingw

#24 [19/33] RUN ./build-compiler-rt.sh /opt/llvm-mingw --enable-cfguard
#24 0.369 + cd llvm-project/compiler-rt
#24 0.370 + cd build-i686
#24 0.371 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/16 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_WORKS=1 -DCMAKE_CXX_COMPILER_WORKS=1 -DCMAKE_C_COMPILER_TARGET=i686-w64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT=-mguard=cf -DCMAKE_CXX_FLAGS_INIT=-mguard=cf ../lib/builtins
#24 0.938 + ninja
#24 1.557 + ninja install
#24 1.568 -- Installing: /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.builtins-i386.a

#24 1.569 + cd ..
#24 1.570 + cd build-x86_64
#24 1.570 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/16 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_WORKS=1 -DCMAKE_CXX_COMPILER_WORKS=1 -DCMAKE_C_COMPILER_TARGET=x86_64-w64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT=-mguard=cf -DCMAKE_CXX_FLAGS_INIT=-mguard=cf ../lib/builtins
#24 2.129 + ninja
#24 3.040 + ninja install
#24 3.050 -- Installing: /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.builtins-x86_64.a

#25 [20/33] COPY build-libcxx.sh ./

#26 [21/33] RUN ./build-libcxx.sh /opt/llvm-mingw --enable-cfguard
#26 0.372 + cd llvm-project
#26 0.372 + cd runtimes
#26 0.373 + cd build-i686
#26 0.374 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_CXX_COMPILER_TARGET=i686-w64-windows-gnu -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DLLVM_PATH=/build/llvm-project/llvm -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBDIR_SUFFIX= -DLIBCXX_INCLUDE_TESTS=FALSE -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_LIBDIR_SUFFIX= -DCMAKE_C_FLAGS_INIT=-mguard=cf -DCMAKE_CXX_FLAGS_INIT=-mguard=cf ..
#26 6.209 -- Build files have been written to: /build/llvm-project/runtimes/build-i686
#26 6.217 + ninja

#26 7.399 [896/1024] Linking C static library lib/libunwind.a
#26 7.429 [897/1024] Linking C shared library lib/libunwind.dll
#26 13.08 [960/1024] Linking CXX static library lib/libc++abi.a
#26 20.94 [1019/1024] Linking CXX static library lib/libc++.a
#26 23.60 [1023/1024] Linking CXX shared library lib/libc++.dll
#26 23.62 [1024/1024] Linking CXX static library lib/libc++experimental.a

#26 23.62 + ninja install
#26 23.65 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/lib/libunwind.dll.a
#26 23.65 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/bin/libunwind.dll
#26 23.65 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/lib/libunwind.a
#26 23.78 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/lib/libc++.dll.a
#26 23.79 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/bin/libc++.dll
#26 23.79 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/lib/libc++.a

#26 23.79 + cd ..
#26 23.79 + cd build-x86_64
#26 23.79 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_CXX_COMPILER_TARGET=x86_64-w64-windows-gnu -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DLLVM_PATH=/build/llvm-project/llvm -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBDIR_SUFFIX= -DLIBCXX_INCLUDE_TESTS=FALSE -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_LIBDIR_SUFFIX= -DCMAKE_C_FLAGS_INIT=-mguard=cf -DCMAKE_CXX_FLAGS_INIT=-mguard=cf ..

#26 29.65 + ninja

#26 49.00 + ninja install
#26 49.02 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/lib/libunwind.dll.a
#26 49.02 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/bin/libunwind.dll
#26 49.02 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/lib/libunwind.a
#26 49.07 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/lib/libc++.dll.a
#26 49.07 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/bin/libc++.dll
#26 49.08 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/lib/libc++.a

#27 [22/33] COPY build-mingw-w64-libraries.sh ./

#28 [23/33] RUN ./build-mingw-w64-libraries.sh /opt/llvm-mingw --enable-cfguard

#28 0.381 + cd mingw-w64/mingw-w64-libraries
#28 0.381 + cd winpthreads
#28 0.381 + cd build-i686
#28 0.381 + arch_prefix=/opt/llvm-mingw/i686-w64-mingw32
#28 0.381 + ../configure --host=i686-w64-mingw32 --prefix=/opt/llvm-mingw/i686-w64-mingw32 --libdir=/opt/llvm-mingw/i686-w64-mingw32/lib CFLAGS=-g -O2 -mguard=cf CXXFLAGS=-g -O2 -mguard=cf

#28 2.547 + make -j12

#28 3.695 + make install
#28 3.752 libtool: install:  /usr/bin/install -c .libs/libwinpthread-1.dll /opt/llvm-mingw/i686-w64-mingw32/lib/../bin/libwinpthread-1.dll
#28 3.753 libtool: install:  chmod a+x /opt/llvm-mingw/i686-w64-mingw32/lib/../bin/libwinpthread-1.dll
#28 3.754 libtool: install:  if test -n '' && test -n 'i686-w64-mingw32-strip --strip-unneeded'; then eval 'i686-w64-mingw32-strip --strip-unneeded /opt/llvm-mingw/i686-w64-mingw32/lib/../bin/libwinpthread-1.dll' || exit 0; fi
#28 3.754 libtool: install: /usr/bin/install -c .libs/libwinpthread.lai /opt/llvm-mingw/i686-w64-mingw32/lib/libwinpthread.la
#28 3.755 libtool: install: /usr/bin/install -c .libs/libwinpthread.a /opt/llvm-mingw/i686-w64-mingw32/lib/libwinpthread.a

#28 3.789 + cd ..
#28 3.791 + cd build-x86_64
#28 3.791 + arch_prefix=/opt/llvm-mingw/x86_64-w64-mingw32
#28 3.791 + ../configure --host=x86_64-w64-mingw32 --prefix=/opt/llvm-mingw/x86_64-w64-mingw32 --libdir=/opt/llvm-mingw/x86_64-w64-mingw32/lib CFLAGS=-g -O2 -mguard=cf CXXFLAGS=-g -O2 -mguard=cf

#28 5.925 + make -j12
#28 7.786 + make install

#28 7.893 + cd ..
#28 7.893 + cd winstorecompat
#28 7.893 + cd build-i686
#28 7.893 + arch_prefix=/opt/llvm-mingw/i686-w64-mingw32
#28 7.893 + ../configure --host=i686-w64-mingw32 --prefix=/opt/llvm-mingw/i686-w64-mingw32 --libdir=/opt/llvm-mingw/i686-w64-mingw32/lib CFLAGS=-g -O2 -mguard=cf CXXFLAGS=-g -O2 -mguard=cf

#28 9.144 + make -j12
#28 10.66 + make install
#28 10.70  /usr/bin/install -c -m 644  libwinstorecompat.a libwindowsappcompat.a '/opt/llvm-mingw/i686-w64-mingw32/lib'

#28 10.71 + cd ..
#28 10.71 + cd build-x86_64
#28 10.71 + arch_prefix=/opt/llvm-mingw/x86_64-w64-mingw32
#28 10.71 + ../configure --host=x86_64-w64-mingw32 --prefix=/opt/llvm-mingw/x86_64-w64-mingw32 --libdir=/opt/llvm-mingw/x86_64-w64-mingw32/lib CFLAGS=-g -O2 -mguard=cf CXXFLAGS=-g -O2 -mguard=cf

#28 11.97 + make -j12
#28 15.53 + make install
#28 15.58  /usr/bin/install -c -m 644  libwinstorecompat.a libwindowsappcompat.a '/opt/llvm-mingw/x86_64-w64-mingw32/lib'

#29 [24/33] COPY test/*.c test/*.h test/*.idl ./test/

#33 [28/33] RUN ./build-compiler-rt.sh /opt/llvm-mingw --build-sanitizers

#33 0.410 + cd llvm-project/compiler-rt
#33 0.411 + cd build-i686-sanitizers
#33 0.411 + [ -n  ]
#33 0.411 + rm -rf CMake*
#33 0.412 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/16 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_WORKS=1 -DCMAKE_CXX_COMPILER_WORKS=1 -DCMAKE_C_COMPILER_TARGET=i686-w64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=FALSE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..

#33 6.527 + ninja

#33 15.34 + ninja install

#33 15.36 -- Installing: /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.stats-i386.a
#33 15.36 -- Installing: /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.stats_client-i386.a

#33 15.37 -- Installing: /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.profile-i386.a
#33 15.38 + mv /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.asan_dynamic-i386.dll /opt/llvm-mingw/i686-w64-mingw32/bin

#33 15.38 + cd ..
#33 15.38 + cd build-x86_64-sanitizers
#33 15.38 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/16 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_WORKS=1 -DCMAKE_CXX_COMPILER_WORKS=1 -DCMAKE_C_COMPILER_TARGET=x86_64-w64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=FALSE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..

#33 21.52 + ninja

#33 33.08 + ninja install

#33 33.11 + mv /opt/llvm-mingw/lib/clang/16/lib/windows/libclang_rt.asan_dynamic-x86_64.dll /opt/llvm-mingw/x86_64-w64-mingw32/bin

#35 [30/33] COPY build-openmp.sh ./

#36 [31/33] RUN ./build-openmp.sh /opt/llvm-mingw --enable-cfguard

#36 0.388 + cd llvm-project/openmp
#36 0.389 + cd build-i686
#36 0.389 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DCMAKE_ASM_MASM_COMPILER=llvm-ml -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLIBOMP_ENABLE_SHARED=TRUE -DCMAKE_C_FLAGS_INIT=-mguard=cf -DCMAKE_CXX_FLAGS_INIT=-mguard=cf ..

#36 5.796 + ninja
#36 11.18 + ninja install
#36 11.19 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/bin/libomp.dll
#36 11.19 -- Installing: /opt/llvm-mingw/i686-w64-mingw32/lib/libomp.dll.a

#36 11.21 + cd ..
#36 11.21 + cd build-x86_64
#36 11.21 + cmake -LAH -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_ASM_MASM_COMPILER=llvm-ml -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLIBOMP_ENABLE_SHARED=TRUE -DCMAKE_C_FLAGS_INIT=-mguard=cf -DCMAKE_CXX_FLAGS_INIT=-mguard=cf -DLIBOMP_ASMFLAGS=-m64 ..

#36 17.01 + ninja
#36 22.50 + ninja install
#36 22.51 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/bin/libomp.dll
#36 22.51 -- Installing: /opt/llvm-mingw/x86_64-w64-mingw32/lib/libomp.dll.a

#38 [33/33] RUN cd test &&     for arch in i686 x86_64; do         cp /opt/llvm-mingw/$arch-w64-mingw32/bin/*.dll $arch || exit 1;     done
```

From `mstorsjo/llvm-mingw:cross` (actually build-output-x-cross-*.txt):

```console
#11 1.046 + cd llvm-project/llvm
#11 1.048 + cd build-x86_64-w64-mingw32

#11 1.048 + cmake -LAH -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw-x86_64 -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra -DLLVM_TARGETS_TO_BUILD=X86 -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf;llvm-size -DLLVM_HOST_TRIPLE=x86_64-w64-mingw32 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DLLVM_NATIVE_TOOL_DIR=/build/llvm-project/llvm/build/bin -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DCLANG_DEFAULT_RTLIB=compiler-rt -DCLANG_DEFAULT_UNWINDLIB=libunwind -DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld -DLLD_DEFAULT_LD_LLD_IS_MINGW=ON ..
#11 69.00 -- Build files have been written to: /build/llvm-project/llvm/build-x86_64-w64-mingw32
#11 69.61 + ninja install/strip
#11 5109.1 [5263/5264] Installing the project stripped...
#11 5109.2 -- Installing: /opt/llvm-mingw-x86_64/bin/clang.exe

#13 [ 9/21] RUN ./build-lldb-mi.sh /opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32
#13 0.314 + cd lldb-mi
#13 0.315 + cd build-x86_64-w64-mingw32
#13 0.316 + cmake -LAH -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw-x86_64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_FIND_ROOT_PATH=/build/llvm-project/llvm/build-x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY ..

#13 2.695 + ninja install/strip
#13 17.56 -- Installing: /opt/llvm-mingw-x86_64/bin/lldb-mi.exe

#15 [11/21] RUN ./strip-llvm.sh /opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32

#17 [13/21] RUN ./build-mingw-w64-tools.sh /opt/llvm-mingw-x86_64 --skip-include-triplet-prefix --host=x86_64-w64-mingw32

#17 0.497 + cd mingw-w64-tools/gendef
#17 0.499 + cd build-x86_64-w64-mingw32
#17 0.499 + ../configure --prefix=/opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32
#17 2.077 + make -j12

#17 2.499 + install -m644 ../COPYING /opt/llvm-mingw-x86_64/share/gendef
#17 2.500 + cd ../../widl

#17 2.501 + cd build-x86_64-w64-mingw32
#17 2.501 + ../configure --prefix=/opt/llvm-mingw-x86_64 --target=i686-w64-mingw32 --with-widl-includedir=/opt/llvm-mingw-x86_64/include --host=x86_64-w64-mingw32
#17 5.289 + make -j12
#17 7.129 + make install-strip
#17 7.161 + cd /opt/llvm-mingw-x86_64/bin
#17 7.161 + ln -sf i686-w64-mingw32-widl.exe i686-w64-mingw32uwp-widl.exe

#20 [16/21] RUN ./install-wrappers.sh /opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32

#22 [18/21] RUN ./prepare-cross-toolchain.sh /opt/llvm-mingw /opt/llvm-mingw-x86_64 x86_64

#24 [20/21] RUN ./build-make.sh /opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32

#25 [21/21] RUN ln -s /opt/llvm-mingw-x86_64 llvm-mingw-$TAGx86_64 &&     zip -9r /llvm-mingw-$TAGx86_64.zip llvm-mingw-$TAGx86_64 &&     ls -lh /llvm-mingw-$TAGx86_64.zip
#25 0.440   adding: llvm-mingw-x86_64/ (stored 0%)

```

## v15.0.7 - 2023-01-02

```sh
sed -i.bak2 -e 's|{LLVM_VERSION:=llvmorg-.*}|{LLVM_VERSION:=llvmorg-15.0.7}|' ~/Work/mstorsjo/llvm-mingw.git/build-llvm.sh

# https://github.com/mirror/mingw-w64/tags
sed -i.bak2 -e 's|{MINGW_W64_VERSION:=.*}|{MINGW_W64_VERSION:=v10.0.0}|' ~/Work/mstorsjo/llvm-mingw.git/build-mingw-w64.sh
```

Same configuration, but with LLVM 15.0.7.

## v15.0.6 - 2023-01-06

With 04c623fe8b50d0c0d78e810ef1cefe10fc418a50 from 01 Dec 2022, which
builds LLVM 15.0.6, the configurations used for the docker images are as below.

For `mstorsjo/llvm-mingw:dev` (actualy build-output-x-dev-*.txt):

```console
ENV TOOLCHAIN_PREFIX=/opt/llvm-mingw
ARG FULL_LLVM
RUN ./build-llvm.sh $TOOLCHAIN_PREFIX

# Build the mingw bootstrap toolchain.
cd llvm-project/llvm/build
# 126
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra -DLLVM_TARGETS_TO_BUILD=ARM;AArch64;X86 -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf ..
ninja
ninja install

RUN ./build-lldb-mi.sh $TOOLCHAIN_PREFIX
cd lldb-mi/build
# L6651
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw -DCMAKE_BUILD_TYPE=Release ..
ninja
ninja install

# L6839
RUN ./strip-llvm.sh $TOOLCHAIN_PREFIX
...

ARG TOOLCHAIN_ARCHS="i686 x86_64 armv7 aarch64"

RUN ./install-wrappers.sh $TOOLCHAIN_PREFIX
...

ARG DEFAULT_CRT=ucrt
ARG CFGUARD_ARGS=--disable-cfguard
# L7555
RUN ./build-mingw-w64.sh $TOOLCHAIN_PREFIX --with-default-msvcrt=$DEFAULT_CRT $CFGUARD_ARGS
export PATH=/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Note: to save some space, install it once and make links.
cd mingw-w64-headers/build
# L7621
../configure --prefix=/opt/llvm-mingw/generic-w64-mingw32 --enable-idl --with-default-win32-winnt=0x601 --with-default-msvcrt=ucrt INSTALL=install -C
make install

ln -sfn ../generic-w64-mingw32/include /opt/llvm-mingw/i686-w64-mingw32/include
ln -sfn ../generic-w64-mingw32/include /opt/llvm-mingw/x86_64-w64-mingw32/include
ln -sfn ../generic-w64-mingw32/include /opt/llvm-mingw/armv7-w64-mingw32/include
ln -sfn ../generic-w64-mingw32/include /opt/llvm-mingw/aarch64-w64-mingw32/include

# Also in cross .../prepare-cross-toolchain.sh
# cp -a /opt/llvm-mingw/generic-w64-mingw32/include /opt/llvm-mingw-x86_64/include

cd mingw-w64-crt/build-i686
# L7741
../configure --host=i686-w64-mingw32 --prefix=/opt/llvm-mingw/i686-w64-mingw32 --enable-lib32 --disable-lib64 --with-default-msvcrt=ucrt
make
make install

cd mingw-w64-crt/build-x86_64
# L10317
../configure --host=x86_64-w64-mingw32 --prefix=/opt/llvm-mingw/x86_64-w64-mingw32 --disable-lib32 --enable-lib64 --with-default-msvcrt=ucrt
make
make install

cd mingw-w64-crt/build-armv7
../configure --host=armv7-w64-mingw32 --prefix=/opt/llvm-mingw/armv7-w64-mingw32 --disable-lib32 --disable-lib64 --enable-libarm32 --with-default-msvcrt=ucrt
make
make install

cd mingw-w64-crt/build-aarch64
./configure --host=aarch64-w64-mingw32 --prefix=/opt/llvm-mingw/aarch64-w64-mingw32 --disable-lib32 --disable-lib64 --enable-libarm64 --with-default-msvcrt=ucrt
make
make install

RUN ./build-mingw-w64-tools.sh $TOOLCHAIN_PREFIX
cd mingw-w64-tools/gendef/build
# L18589
../configure --prefix=/opt/llvm-mingw
make
make install-strip

cd mingw-w64-tools/widl/build
# L18682
../configure --prefix=/opt/llvm-mingw --target=i686-w64-mingw32 --with-widl-includedir=/opt/llvm-mingw/generic-w64-mingw32/include
make
make install-strip

RUN ./build-compiler-rt.sh $TOOLCHAIN_PREFIX $CFGUARD_ARGS
export PATH=/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd llvm-project/compiler-rt/build-i686
# L18897
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/15.0.7 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_TARGET=i686-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ../lib/builtins
ninja
ninja install

cd llvm-project/compiler-rt/build-x86_64
# L19131
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/15.0.7 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_TARGET=x86_64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ../lib/builtins
ninja
ninja install

cd llvm-project/compiler-rt/build-armv7
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/15.0.0 -DCMAKE_C_COMPILER=armv7-w64-mingw32-clang -DCMAKE_CXX_COMPILER=armv7-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_TARGET=armv7-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/armv7-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ../lib/builtins
ninja
ninja install

cd llvm-project/compiler-rt/build-aarch64
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/15.0.0 -DCMAKE_C_COMPILER=aarch64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=aarch64-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_TARGET=aarch64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=TRUE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/aarch64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ../lib/builtins
ninja
ninja install

# 19952
RUN ./build-libcxx.sh $TOOLCHAIN_PREFIX $CFGUARD_ARGS
export PATH=/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd llvm-project/build-i686
# L20002
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_CXX_COMPILER_TARGET=i686-w64-windows-gnu -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DLLVM_PATH=/build/llvm-project/llvm -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBDIR_SUFFIX= -DLIBCXX_INCLUDE_TESTS=FALSE -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_LIBDIR_SUFFIX= -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

cd llvm-project/build-x86_64
# L22007
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_CXX_COMPILER_TARGET=x86_64-w64-windows-gnu -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DLLVM_PATH=/build/llvm-project/llvm -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBDIR_SUFFIX= -DLIBCXX_INCLUDE_TESTS=FALSE -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_LIBDIR_SUFFIX= -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

cd llvm-project/build-armv7
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/armv7-w64-mingw32 -DCMAKE_C_COMPILER=armv7-w64-mingw32-clang -DCMAKE_CXX_COMPILER=armv7-w64-mingw32-clang++ -DCMAKE_CXX_COMPILER_TARGET=armv7-w64-windows-gnu -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DLLVM_PATH=/build/llvm-project/llvm -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBDIR_SUFFIX= -DLIBCXX_INCLUDE_TESTS=FALSE -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_LIBDIR_SUFFIX= -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

cd llvm-project/build-aarch64
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/aarch64-w64-mingw32 -DCMAKE_C_COMPILER=aarch64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=aarch64-w64-mingw32-clang++ -DCMAKE_CXX_COMPILER_TARGET=aarch64-w64-windows-gnu -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER_WORKS=TRUE -DCMAKE_CXX_COMPILER_WORKS=TRUE -DLLVM_PATH=/build/llvm-project/llvm -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLLVM_ENABLE_RUNTIMES=libunwind;libcxxabi;libcxx -DLIBUNWIND_USE_COMPILER_RT=TRUE -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON -DLIBCXX_USE_COMPILER_RT=ON -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON -DLIBCXX_ENABLE_STATIC_ABI_LIBRARY=TRUE -DLIBCXX_CXX_ABI=libcxxabi -DLIBCXX_LIBDIR_SUFFIX= -DLIBCXX_INCLUDE_TESTS=FALSE -DLIBCXX_ENABLE_ABI_LINKER_SCRIPT=FALSE -DLIBCXXABI_USE_COMPILER_RT=ON -DLIBCXXABI_USE_LLVM_UNWINDER=ON -DLIBCXXABI_ENABLE_SHARED=OFF -DLIBCXXABI_LIBDIR_SUFFIX= -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

RUN ./build-mingw-w64-libraries.sh $TOOLCHAIN_PREFIX $CFGUARD_ARGS
export PATH=/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd mingw-w64/mingw-w64-libraries/winpthreads/build-i686
# L28052
../configure --host=i686-w64-mingw32 --prefix=/opt/llvm-mingw/i686-w64-mingw32 --libdir=/opt/llvm-mingw/i686-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winpthreads/build-x86_64
# L28341
../configure --host=x86_64-w64-mingw32 --prefix=/opt/llvm-mingw/x86_64-w64-mingw32 --libdir=/opt/llvm-mingw/x86_64-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winpthreads/build-armv7
../configure --host=armv7-w64-mingw32 --prefix=/opt/llvm-mingw/armv7-w64-mingw32 --libdir=/opt/llvm-mingw/armv7-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winpthreads/build-aarch64
../configure --host=aarch64-w64-mingw32 --prefix=/opt/llvm-mingw/aarch64-w64-mingw32 --libdir=/opt/llvm-mingw/aarch64-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winstorecompat/build-i686
# L29087
../configure --host=i686-w64-mingw32 --prefix=/opt/llvm-mingw/i686-w64-mingw32 --libdir=/opt/llvm-mingw/i686-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winstorecompat/build-x86_64
# L29294
../configure --host=x86_64-w64-mingw32 --prefix=/opt/llvm-mingw/x86_64-w64-mingw32 --libdir=/opt/llvm-mingw/x86_64-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winstorecompat/build-armv7
../configure --host=armv7-w64-mingw32 --prefix=/opt/llvm-mingw/armv7-w64-mingw32 --libdir=/opt/llvm-mingw/armv7-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

cd mingw-w64/mingw-w64-libraries/winstorecompat/build-aarch64
../configure --host=aarch64-w64-mingw32 --prefix=/opt/llvm-mingw/aarch64-w64-mingw32 --libdir=/opt/llvm-mingw/aarch64-w64-mingw32/lib CFLAGS=-g -O2 CXXFLAGS=-g -O2
make
make install

ENV PATH=$TOOLCHAIN_PREFIX/bin:$PATH
RUN cd test && ...

RUN ./build-compiler-rt.sh $TOOLCHAIN_PREFIX --build-sanitizers
export PATH=/opt/llvm-mingw/bin:/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd llvm-project/compiler-rt/build-i686-sanitizers
# L29979
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/15.0.7 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_TARGET=i686-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=FALSE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

cd llvm-project/compiler-rt/build-x86_64-sanitizers
# L30591
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/lib/clang/15.0.7 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DCMAKE_C_COMPILER_TARGET=x86_64-windows-gnu -DCOMPILER_RT_DEFAULT_TARGET_ONLY=TRUE -DCOMPILER_RT_USE_BUILTINS_LIBRARY=TRUE -DCOMPILER_RT_BUILD_BUILTINS=FALSE -DLLVM_CONFIG_PATH= -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DSANITIZER_CXX_ABI=libc++ -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

RUN ./build-libssp.sh $TOOLCHAIN_PREFIX $CFGUARD_ARGS
export PATH=/opt/llvm-mingw/bin:/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd libssp/build-i686
make -f ../Makefile -j12 CROSS=i686-w64-mingw32- CFGUARD_CFLAGS=

cd libssp/build-x86_64
make -f ../Makefile -j12 CROSS=x86_64-w64-mingw32- CFGUARD_CFLAGS=

cd libssp/build-armv7
make -f ../Makefile -j12 CROSS=armv7-w64-mingw32- CFGUARD_CFLAGS=

cd libssp/build-aarch64
make -f ../Makefile -j12 CROSS=aarch64-w64-mingw32- CFGUARD_CFLAGS=

RUN ./build-openmp.sh $TOOLCHAIN_PREFIX $CFGUARD_ARGS
export PATH=/opt/llvm-mingw/bin:/opt/llvm-mingw/bin:/opt/cmake/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

cd llvm-project/openmp/build-i686
# L31469
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/i686-w64-mingw32 -DCMAKE_C_COMPILER=i686-w64-mingw32-clang -DCMAKE_CXX_COMPILER=i686-w64-mingw32-clang++ -DCMAKE_RC_COMPILER=i686-w64-mingw32-windres -DCMAKE_ASM_MASM_COMPILER=llvm-ml -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLIBOMP_ENABLE_SHARED=TRUE -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= ..
ninja
ninja install

cd llvm-project/openmp/build-x86_64
# L31679
cmake -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_C_COMPILER=x86_64-w64-mingw32-clang -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-clang++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_ASM_MASM_COMPILER=llvm-ml -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_AR=/opt/llvm-mingw/bin/llvm-ar -DCMAKE_RANLIB=/opt/llvm-mingw/bin/llvm-ranlib -DLIBOMP_ENABLE_SHARED=TRUE -DCMAKE_C_FLAGS_INIT= -DCMAKE_CXX_FLAGS_INIT= -DLIBOMP_ASMFLAGS=-m64 ..
ninja
ninja install
```

From `mstorsjo/llvm-mingw:cross` (actually build-output-x-cross-*.txt):

```console
RUN if [ -n "$WITH_PYTHON" ]; then         ./build-python.sh /opt/python;     fi
ENV PATH=/opt/python/bin:$PATH
ARG CROSS_ARCH=x86_64
ENV CROSS_TOOLCHAIN_PREFIX=/opt/llvm-mingw-$CROSS_ARCH
ENV HOST=$CROSS_ARCH-w64-mingw32
RUN if [ -n "$WITH_PYTHON" ]; then         ./build-python.sh $CROSS_TOOLCHAIN_PREFIX/python --host=$HOST &&         mkdir -p $CROSS_TOOLCHAIN_PREFIX/bin &&         cp $CROSS_TOOLCHAIN_PREFIX/python/bin/*.dll $CROSS_TOOLCHAIN_PREFIX/bin;     fi

ARG FULL_LLVM
RUN if [ -n "$WITH_PYTHON" ]; then ARG="--with-python"; fi &&     ./build-llvm.sh $CROSS_TOOLCHAIN_PREFIX --host=$HOST $ARG

cd llvm-project/llvm/build-x86_64-w64-mingw32
# L184
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw-x86_64 -DCMAKE_BUILD_TYPE=Release -DLLVM_ENABLE_ASSERTIONS=OFF -DLLVM_ENABLE_PROJECTS=clang;lld;lldb;clang-tools-extra -DLLVM_TARGETS_TO_BUILD=ARM;AArch64;X86 -DLLVM_INSTALL_TOOLCHAIN_ONLY=ON -DLLVM_LINK_LLVM_DYLIB=ON -DLLVM_TOOLCHAIN_TOOLS=llvm-ar;llvm-ranlib;llvm-objdump;llvm-rc;llvm-cvtres;llvm-nm;llvm-strings;llvm-readobj;llvm-dlltool;llvm-pdbutil;llvm-objcopy;llvm-strip;llvm-cov;llvm-profdata;llvm-addr2line;llvm-symbolizer;llvm-windres;llvm-ml;llvm-readelf -DLLVM_HOST_TRIPLE=x86_64-w64-mingw32 -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DLLVM_TABLEGEN=/build/llvm-project/llvm/build/bin/llvm-tblgen -DCLANG_TABLEGEN=/build/llvm-project/llvm/build/bin/clang-tblgen -DLLDB_TABLEGEN=/build/llvm-project/llvm/build/bin/lldb-tblgen -DLLVM_CONFIG_PATH=/build/llvm-project/llvm/build/bin/llvm-config -DCLANG_PSEUDO_GEN=/build/llvm-project/llvm/build/bin/clang-pseudo-gen -DCLANG_TIDY_CONFUSABLE_CHARS_GEN=/build/llvm-project/llvm/build/bin/clang-tidy-confusable-chars-gen -DCMAKE_FIND_ROOT_PATH=/opt/llvm-mingw/x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY -DCLANG_DEFAULT_RTLIB=compiler-rt -DCLANG_DEFAULT_UNWINDLIB=libunwind -DCLANG_DEFAULT_CXX_STDLIB=libc++ -DCLANG_DEFAULT_LINKER=lld ..
ninja install/strip

RUN ./build-lldb-mi.sh $CROSS_TOOLCHAIN_PREFIX --host=$HOST
cd lldb-mi/build-x86_64-w64-mingw32
# L6318
cmake -G Ninja -DCMAKE_INSTALL_PREFIX=/opt/llvm-mingw-x86_64 -DCMAKE_BUILD_TYPE=Release -DCMAKE_SYSTEM_NAME=Windows -DCMAKE_C_COMPILER=x86_64-w64-mingw32-gcc -DCMAKE_CXX_COMPILER=x86_64-w64-mingw32-g++ -DCMAKE_RC_COMPILER=x86_64-w64-mingw32-windres -DCMAKE_FIND_ROOT_PATH=/build/llvm-project/llvm/build-x86_64-w64-mingw32 -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY ..
ninja install/strip

RUN ./strip-llvm.sh $CROSS_TOOLCHAIN_PREFIX --host=$HOST

RUN ./build-mingw-w64-tools.sh $CROSS_TOOLCHAIN_PREFIX --skip-include-triplet-prefix --host=$HOST

cd mingw-w64-tools/gendef/build-x86_64-w64-mingw32
# L7149
../configure --prefix=/opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32
make
make install-strip

cd mingw-w64-tools/widl/build-x86_64-w64-mingw32
# L7243
../configure --prefix=/opt/llvm-mingw-x86_64 --target=i686-w64-mingw32 --with-widl-includedir=/opt/llvm-mingw-x86_64/include --host=x86_64-w64-mingw32
make
make install-strip

RUN ./install-wrappers.sh $CROSS_TOOLCHAIN_PREFIX --host=$HOST
...

RUN ./prepare-cross-toolchain.sh $TOOLCHAIN_PREFIX $CROSS_TOOLCHAIN_PREFIX $CROSS_ARCH

RUN ./build-make.sh $CROSS_TOOLCHAIN_PREFIX --host=$HOST

cd make-4.2.1/build-x86_64-w64-mingw32
../configure --prefix=/opt/llvm-mingw-x86_64 --host=x86_64-w64-mingw32 --program-prefix=mingw32- --enable-job-server LDFLAGS=-Wl,-s
make

ARG TAG
RUN ln -s $CROSS_TOOLCHAIN_PREFIX llvm-mingw-$TAG$CROSS_ARCH &&     zip -9r /llvm-mingw-$TAG$CROSS_ARCH.zip llvm-mingw-$TAG$CROSS_ARCH &&     ls -lh /llvm-mingw-$TAG$CROSS_ARCH.zip
```

## v15.0.0 - 2022-11-27

With 01597c1d723ed08981d64e224f8860c3ce4a7596 from 22 Aug 2022, which
builds LLVM 15.0.0, the configurations used for the docker images are the same
as before.
