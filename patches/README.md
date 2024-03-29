# Patches

For macOS, check [HomeBrew](https://github.com/Homebrew/homebrew-core/blob/master/Formula/l/llvm.rb).
For Windows, check [llvm-mingw](https://github.com/mstorsjo/llvm-mingw/releases).

## llvm-16.0.6

A patch from HomeBrew, apparently for meson.

<https://github.com/Homebrew/homebrew-core/blob/58bcd53f0cc021afaf6aaa7fbfd72c43fd51c911/Formula/llvm.rb>

## llvm-15.0.7

No patches in HomeBrew:

<https://github.com/Homebrew/homebrew-core/blob/207de704c332ada38c835c0ae1b275058c7dff82/Formula/llvm.rb>

Patch for 32-bit Arm.

- <https://github.com/llvm/llvm-project/issues/60115>

## llvm-14.0.6-2

In addition, patch the clangd bug
[1072](https://github.com/clangd/clangd/issues/1072).

## llvm-12.0.1

This patch adds `/Library/Developer/CommandLineTools/usr/include/c++/v1`
to the search path for headers.

Without it the build fails in compiler-rt, complaining about missing
system C++ headers.

The patch was generated with git by comparing the `12.0.1-xpack` branch
with the official `llvmorg-12.0.1` tag in the llvm-project.git fork,
then the paths were manually edited to remove the a/b parts.
