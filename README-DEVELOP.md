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
/Users/ilg/Work/clang-16.0.6-1/darwin-x64/sources/llvm-project-16.0.6.src/llvm/utils/TableGen/GlobalISelEmitter.cpp:4298:7: error: no matching function for call to 'makeArrayRef'
      makeArrayRef({&BuildVector, &BuildVectorTrunc}));
      ^~~~~~~~~~~~
/Users/ilg/Work/clang-16.0.6-1/darwin-x64/sources/llvm-project-16.0.6.src/llvm/include/llvm/ADT/ArrayRef.h:458:15: note: candidate template ignored: couldn't infer template argument 'T'
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
[/home/runner/Work/linux-x64/tests/xpack-clang-16.0.6-1/bin/clang++ simple-exception.cpp -o crt-simple-exception -rtlib=compiler-rt -stdlib=libc++ -fuse-ld=lld]
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

The solution is to install the static libraries.

## 13.0.1-2

Fails the build for Windows and for macOS Sonoma.

## 14.0.6-3

Fails on macOS Sonoma with errors while building the sanitizer.

Fails on Windows to compile static

```
[wine64 /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/win32-x64/application/bin/clang++.exe simple-hello.cpp -o static-lib-simple-hello1-cpp-one-32.exe -static-libgcc -static-libstdc++ -m32 -v -v]
ld.lld: error: undefined symbol: __declspec(dllimport) std::__1::cout
>>> referenced by C:/users/ilg/Temp/simple-hello1-cfc904.o:(_main)
```

## 18.1.7-1

On Ubuntu 18, x64, 32-bit static lld tests fail, most probably due to an
issue with the old 32-bit libraries:


```
  ld.lld: error: duplicate symbol: __x86.get_pc_thunk.cx
  >>> defined at locale.o:(.text.__x86.get_pc_thunk.cx+0x0) in archive /usr/lib/gcc/x86_64-linux-gnu/7/32/libstdc++.a
  >>> defined at stpncpy-sse2.o:(.gnu.linkonce.t.__x86.get_pc_thunk.cx+0x0) in archive /usr/lib/gcc/x86_64-linux-gnu/7/../../../../lib32/libc.a
  clang++: error: linker command failed with exit code 1 (use -v to see invocation)

  xfail: static-lld-simple-hello-cout-one-32
```

## Run tests on docker images

For prerequisites, see [xbb-helper-xpack.git/README-DEVELOPER.md](https://github.com/xpack-dev-tools/xbb-helper-xpack/blob/xpack-develop/README-DEVELOPER.md#prerequisites-to-run-tests-on-docker-images).

Common to all distributions:

```sh
rm -rf ~/Work/xpack-dev-tools/clang-xpack.git && \
mkdir -p ~/Work/xpack-dev-tools && \
git clone \
--branch xpack-develop \
https://github.com/xpack-dev-tools/clang-xpack.git \
~/Work/xpack-dev-tools/clang-xpack.git

rm -rf ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
mkdir -p ~/Work/xpack-dev-tools && \
git clone \
--branch xpack-develop \
https://github.com/xpack-dev-tools/xbb-helper-xpack.git \
~/Work/xpack-dev-tools/xbb-helper-xpack.git

rm -rf ~/Work/xpack-dev-tools/clang-xpack.git/xpacks
mkdir -pv ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools
ln -sv ~/Work/xpack-dev-tools/xbb-helper-xpack.git ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper
```

Pass the distribution name, since at this point the docker image cannot identify itself,
`lsb_release` is not yet available.

```sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/scripts/test.sh --image redhat --base-url pre-release --version 18.1.8-1
bash ~/Work/xpack-dev-tools/clang-xpack.git/scripts/test.sh --image debian --base-url pre-release --version 18.1.8-1
bash ~/Work/xpack-dev-tools/clang-xpack.git/scripts/test.sh --image ubuntu --base-url pre-release --version 18.1.8-1
```

Other commands:

```sh
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull

git -C ~/Work/xpack-dev-tools/clang-xpack.git status
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git status

vi ~/Work/xpack-dev-tools/xbb-helper-xpack.git/scripts/build-tests.sh
vi /root/Work/xpack-dev-tools/clang-xpack.git/build/linux-x64/tests/results/summary
vi ~/Work/xpack-dev-tools/clang-xpack.git/scripts/tests/run.sh
```

## Oracle ampere tests

17.0.5-1, ampere 4 core, 24 GB RAM, 200 GB disk

- 64-bit: 2h14, 2h17, 2h18 (average 2h16, 136min, 1.1147)
- 32-bit: 2h02, 2h02, 2h02 (average 2h02, 122min)
- in parallel 64-bit: 4h21, 32-bit: 4h06

Berry 32

- 32-bit: 9h36 (576min), 9h29 (569min), 9h29 (569min)

Berry 64

- 64-bit: 11h47 (707min) 1.3092;
- 32-bit: 9h00 (540min); 9h16

- <https://forums.raspberrypi.com/viewtopic.php?p=2158073#p2158073>

## Bug reports

### Bug in getInstalledDir() prevents picking up the correct headers when clang is started via a link

- <https://github.com/llvm/llvm-project/issues/66704>

### Catching custom exceptions thrown from shared libraries fail when using -flto

- <https://github.com/llvm/llvm-project/issues/64471>

### Building 16|17 fails on macOS 10.13 due to incompatible 'optional' header

- <https://github.com/llvm/llvm-project/issues/64472>
