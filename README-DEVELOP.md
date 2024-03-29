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

## 13.0.1-2

Fails the build for Windows and for macOS Sonoma.

## 14.0.6-3

Fails on macOS Sonoma with errors while building the sanitizer.

Fails on Windows to compile static

```
[wine64 /home/ilg/Work/xpack-dev-tools/clang-xpack.git/build/win32-x64/application/bin/clang++.exe simple-hello.cpp -o static-lib-simple-hello-cpp-one-32.exe -static-libgcc -static-libstdc++ -m32 -v -v]
ld.lld: error: undefined symbol: __declspec(dllimport) std::__1::cout
>>> referenced by C:/users/ilg/Temp/simple-hello-cfc904.o:(_main)
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
