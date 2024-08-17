---
title: Test results

---

## Reports by version

- [18.1.8-1](/docs/tests/18.1.8-1/)
- [17.0.6-3](/docs/tests/17.0.6-3/)
- [17.0.6-2](/docs/tests/17.0.6-2/)
- [16.0.6-1](/docs/tests/16.0.6-1/)

## Notes

### x64 GNU/Linux

All tests passed.

### arm64 GNU/Linux

All tests passed.

### arm GNU/Linux

Many LTO and some LLD fail; skipped.

### x64 macOS

Most are fine, except LTO **throwcatch-main**.

#### Failed test throwcatch-main

- xfail: lto-throwcatch-main
- xfail: gc-lto-throwcatch-main
- xfail: lto-lld-throwcatch-main
- xfail: gc-lto-lld-throwcatch-main

This issue affects catching custom exceptions
thrown from shared libraries when using `-flto`. The issue is old and was
already reported, but got no much feedback:
https://github.com/llvm/llvm-project/issues/64471.
It can also be reproduced with Apple clang 15 on macOS 14.3.1 x86_64.

### arm64 macOS

Most are fine, except some exception tests with lld.

- xfail: lld-hello-exception
- xfail: lld-exception-reduced
- xfail: gc-lld-hello-exception
- xfail: gc-lld-exception-reduced
- xfail: lto-lld-hello-exception
- xfail: lto-lld-exception-reduced
- xfail: gc-lto-lld-hello-exception
- xfail: gc-lto-lld-exception-reduced

#### Failed test hello-exception

Not yet explained. Not seen on HB.

#### Failed test exception-reduced

Not yet explained. Not seen on HB.

### Mingw-w64 Windows x86_64

All tests passed.
