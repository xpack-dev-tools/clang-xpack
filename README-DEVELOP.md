# Developer info

## Notes

- no Lua support in lldb
- no python support in lldb
- no sanitizers in compiler_rt
- Linux default linker is GNU ld.gold, to allow LTO
- Windows default linker is lld
- macOS default linker is the system ld
- on macOS, because the system linker prefers the system libc++.dylib,
there are no C++ headers and libraries)
- no rpc/xdr.h in compiler_rt
- on Linux the default is with libstdc++ and the GNU libraries
- on Linux, the clang libc++ fails to link with -static is exceptions are used
- on Arm64, lldb failed with missing SVE_PT_FPSIMD_OFFSET; lldb disabled on Arm,
to be re-enabled with Ubuntu 18.

### macOS 10.10

The compiler on macOS 10.10 seems a bit too old (LLVM 3.6.0)
and the build fails with:

```console
/Users/ilg/Work/clang-14.0.6-2/darwin-x64/sources/llvm-project-14.0.6.src/llvm/utils/TableGen/GlobalISelEmitter.cpp:4298:7: error: no matching function for call to 'makeArrayRef'
      makeArrayRef({&BuildVector, &BuildVectorTrunc}));
      ^~~~~~~~~~~~
/Users/ilg/Work/clang-14.0.6-2/darwin-x64/sources/llvm-project-14.0.6.src/llvm/include/llvm/ADT/ArrayRef.h:458:15: note: candidate template ignored: couldn't infer template argument 'T'
  ArrayRef<T> makeArrayRef(const T &OneElt) {
              ^
```

It is not clear if the issue is related to the compiler or rather the
C++ standard library.

On macOS 10.13 the compiler is relatively recent (Apple LLVM version 10.0.0)
and is able to build the project without problems.

Thus, for the xPack LLVM/clang, the minimum supported system will
be macOS 10.13.

## ubuntu-latest

Tests fail on ubuntu-latest, in crt-simple-exception, with:

```console
[/home/runner/Work/linux-x64/tests/xpack-clang-14.0.6-2/bin/clang++ simple-exception.cpp -o crt-simple-exception -rtlib=compiler-rt -stdlib=libc++ -fuse-ld=lld]
ld.lld: error: undefined symbol: _Unwind_Resume
>>> referenced by simple-exception.cpp
>>>               /tmp/simple-exception-16524d.o:(main)
>>> referenced by simple-exception.cpp
>>>               /tmp/simple-exception-16524d.o:(std::__1::basic_ostream<char, std::__1::char_traits<char> >& std::__1::__put_character_sequence<char, std::__1::char_traits<char> >(std::__1::basic_ostream<char, std::__1::char_traits<char> >&, char const*, unsigned long))
>>> referenced by simple-exception.cpp
>>>               /tmp/simple-exception-16524d.o:(std::__1::ostreambuf_iterator<char, std::__1::char_traits<char> > std::__1::__pad_and_output<char, std::__1::char_traits<char> >(std::__1::ostreambuf_iterator<char, std::__1::char_traits<char> >, char const*, char const*, char const*, std::__1::ios_base&, char))
>>> referenced 1 more times
clang-12: error: linker command failed with exit code 1 (use -v to see invocation)
Error: Process completed with exit code 1.
```

The same test on a plain Ubuntu 20 passes.

## -static-libstdc++

On RedHat systems, the tests that expected a `libstdc++.a` fail.

## mstorsjo/llvm-mingw

The build scripts producing Windows binaries are inspired by the project
[llvm-mingw](https://github.com/mstorsjo/llvm-mingw),
maintained by Martin Storsjö.

To get the actual configurations, the easiest way is to run the builds with
the shell debug option enabled, and capture the console output.

The direct invocation of the build script on an Ubuntu 18 fails,
since cmake is too old, thus it is preferred to use the Docker builds.

For this, on `xbbli`:

```sh
mkdir -pv ~/Work/mstorsjo
git clone https://github.com/mstorsjo/llvm-mingw ~/Work/mstorsjo/llvm-mingw.git

# or, if already cloned:
git -C ~/Work/mstorsjo/llvm-mingw.git pull

# Patch the shell scripts to add -x.
find ~/Work/mstorsjo/llvm-mingw.git -name '*.sh' ! -iname '*-wrapper.sh' \
  -exec sed -i.bak -e 's|^#!/bin/sh$|#!/bin/sh -x|' '{}' ';'

sed -i.bak2 -e 's|-15.0.0}|-15.0.7}|' ~/Work/mstorsjo/llvm-mingw.git/build-llvm.sh

# Build the development docker image.
cd ~/Work/mstorsjo/llvm-mingw.git
time docker build -f Dockerfile.dev -t mstorsjo/llvm-mingw:dev . | tee ../build-output-x-dev-$(date -u +%Y%m%d-%H%M%S).txt

# Build the cross binaries.
cd ~/Work/mstorsjo/llvm-mingw.git
time docker build -f Dockerfile.cross -t mstorsjo/llvm-mingw:cross . | tee ../build-output-x-cross-$(date -u +%Y%m%d-%H%M%S).txt

# For completeness, build the regular binaries.
cd ~/Work/mstorsjo/llvm-mingw.git
docker build  -t mstorsjo/llvm-mingw . | tee ../build-output-x-$(date -u +%Y%m%d-%H%M%S).txt
```

## 2023-01-06

With 04c623fe8b50d0c0d78e810ef1cefe10fc418a50 from 01 Dec 2022, which
builds LLVM 15.0.7, the configurations used for the docker images are as below.

For `mstorsjo/llvm-mingw:dev` (actualy build-output-x-dev-*.txt):

```sh
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

```sh
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

## 2022-11-27

With 01597c1d723ed08981d64e224f8860c3ce4a7596 from 22 Aug 2022, which
builds LLVM 15.0.0, the configurations used for the docker images are the same
as before.
