TODO

## ubuntu-latest

Tests fail on ubuntu-latest, in crt-simple-exception, with:

```console
[/home/runner/Work/linux-x64/tests/xpack-clang-14.0.6-1/bin/clang++ simple-exception.cpp -o crt-simple-exception -rtlib=compiler-rt -stdlib=libc++ -fuse-ld=lld]
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
