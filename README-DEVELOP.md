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

## Bug reports

### Bug in getInstalledDir() prevents picking up the correct headers when clang is started via a link

- https://github.com/llvm/llvm-project/issues/66704

### Catching custom exceptions thrown from shared libraries fail when using -flto

- https://github.com/llvm/llvm-project/issues/64471

### Building 16|17 fails on macOS 10.13 due to incompatible 'optional' header

- https://github.com/llvm/llvm-project/issues/64472
