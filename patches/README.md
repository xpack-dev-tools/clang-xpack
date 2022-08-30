# Patches

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
then the paths were manually editted to remove the a/b parts.
