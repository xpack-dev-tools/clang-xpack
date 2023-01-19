# Change & release log

Entries in this file are in reverse chronological order.

## 2023-01-20

* v15.0.7-1 prepared
* 3c64431 add llvm-15.0.7-1.git.patch
* 9e8017c llvm.sh: RUNTIMES_COMPILER_RT_BUILD_GWP_ASAN=OFF
* dfa1cf2 llvm-mingw.sh: cleanup PER_TARGET_RUNTIME_DIR=OFF
* d930c70 llvm-mingw.sh: -DCMAKE_CROSSCOMPILING=ON
* eec3541 llvm-mingw.sh: revert to MS inconsistent targets
* 5b0088a llvm-mingw.sh: add CMAKE_SHARED_LINKER_FLAGS

## 2023-01-19

* e4a85a9 README updates
* 10801d5 llvm.sh: fix bash syntax
* df1b2c8 llvm-mingw.sh: reorder options
* 86edf5a llvm-mingw.sh: -DLLVM_ENABLE_WARNINGS=OFF
* 0b3e517 llvm-mingw.sh: rework triplets
* 2ef0212 llvm-mingw.sh: define CMAKE_OBJCOPY/OBJDUMP
* f60ab9d llvm-mingw.sh: conditional copy of clang-*-gen
* 99e9b11 llvm.sh: add CMAKE_SHARED_LINKER_FLAGS
* 0edcc56 llvm.sh: conditional configure CLANG_*_GEN
* cb0b6a7 llvm.sh: cosmetics
* d0a8171 llvm.sh: do not use lld at all for macOS
* 0bbe27a Merge branch 'xpack-develop' of https://github.com/xpack-dev-tools/clang-xpack into xpack-develop
* eef775a llvm.sh: do not use lld on new macOS
2023-01-18 * 858c604 llvm.sh: multilib tests only on x64

## 2023-01-18

* v14.0.6-3 prepared
* 831789b llvm.sh: disable macOS CLANG_DEFAULT_CXX_STDLIB
* b6dfa9b llvm.sh: disable CLANG_DEFAULTs for linux
* 744dad2 llvm.sh: consistent LLVM_* from 14.x
* b484b44 llvm.sh: temporary use only -DLLVM_ENABLE_PROJECTS
* 805537d CHANGELOG update
* e46cf28 llvm.sh: comment out triplet for aarch64
* d853c41 llvm.sh: keep only aarch64, remove arm
* 6fda26d llvm.sh: comment out triplet for armv7

## 2023-01-17

* 2832ef8 llvm.sh: LLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON
* 4f4b979 README updates

## 2023-01-16

* 96310fa llvm.sh: update triplets for arm

## 2023-01-15

* 76e97fc package.json: revert linux to gcc
* 42ded2b package.json: add llc, lli to bin
* 3231313 llvm-mingw.sh: remove -v from flags
* 7191043 versioning.sh: revert to *prepare_gcc_env
* 3e46727 llvm.sh: cleanups
* b83564e llvm.sh: fix 32-bit tests
* 0b0a016 llvm.sh: remove -DLLVM_TOOL_GOLD_BUILD=ON
* fadeb91 llvm.sh: remove -DLLVM_POLLY_LINK_INTO_TOOLS=ON
* 4bc5193 llvm.sh: remove -DLLVM_OPTIMIZED_TABLEGEN=ON
* ac6040b llvm.sh: remove -DLLVM_INSTALL_UTILS=ON
* 847490b llvm.sh: fix x64 multilib targets
* 2e13162 llvm.sh: remove -DLLVM_BUILD_LLVM_C_DYLIB=OFF

## 2023-01-14

* 796673d llvm.sh: add i386 to LLVM_RUNTIME_TARGETS on linux
* 8e032a6 llvm.sh: do not remove poly
* 55075e4 llvm.sh: do not remove llc lli
* f0dd658 versioning.sh: *_prepare_clang_env
* ec28fd2 package.json: switch linux to use clang
* 438cc8f Revert "llvm.sh: do not use ENABLE_RUNTIMES on linux"
* e6dfe3a llvm.sh: do not use ENABLE_RUNTIMES on linux

## 2023-01-13

* 6de4649 llvm.sh: define -DCMAKE_* only when available
* 9ffd54c llvm.sh: define -DCMAKE_DLLTOOL only on windows
* 1281475 README-DEVELOP updates
* d0e7a86 llvm.sh: prepare but not enable 32-bit linux tests
* f78bd04 llvm.sh: add 32-bit tests for windows
* b242910 llvm.sh: remove -DLIBUNWIND_ENABLE_SHARED=OFF
* d6b31d0 llvm.sh: no _RUNTIMES for windows
* 3471530 versioning.sh: explain windows difficulties
* 8d597cb versioning.sh: generic regexp for past releases
* b9fef2c llvm.sh: explicit CMAKE_* variables
* 24a955d llvm-mingw.sh: use cmake.done in rt & libcxx
* b209295 llvm-mingw.sh: define all binutils CMAKE_*
* ad3c280 package.sjon: add mingw-gcc back for windows
* 846f966 versioning.sh: add widl comment
* 770d9bf llvm.sh: move _DEBUGSERVER=ON to macOS only
* 33a963b llvm.sh: add WINEPATH & PATH
* cd82f04 llvm-mingw.sh: conditional tests
* 8533242 llvm-mingw.sh: copy bin/*.dll to lib
* 32c3d03 package.json: update xpack.bin

## 2023-01-12

* 69fe041 cmake -LAH
* 838f7ca README updates
* v15.0.7-1 prepared
* c89db1e llvm.sh: explicit mkdir applications/lib

## 2023-01-11

* 8a883ce llvm.sh: cleanups
* de46289 llvm.sh: remove mlir, it fails on windows
* b04cd5d llvm.sh: ENABLE_LZMA=OFF for windows
* a5d9db3 llvm-mingw.sh: cosmetize xbb_adjust_ldflags_rpath
* 388b0e0 llvm.sh: explicit application/lib to -rpath
* 2bc6f2d cosmetize xbb_adjust_ldflags_rpath

## 2023-01-10

* 9067c08 llvm.sh: -DLLVM_ENABLE_LTO=OFF for macOS
* f405d00 llvm.sh: Z3_SOLVER=OFF
* 80d5da5 llvm.sh: rework closer to HB & Arch
* d1d5e94 llvm.sh: comment out implicit -lpthread -ldl
* 38b98b0 lvm.sh: patch for libxar only on macOS
* 51c71df llvm-mingw.sh: cleanups (commented out code)
* dc88354 llvm-mingw.sh: copy *-gen binaries

## 2023-01-09

* 13607c3 llvm.sh: re-enable code to disable libxar
* 5b97f51 versioning.sh: use XBB_MINGW_TRIPLETS for windows
* cc2e465 versioning.sh: update clang_add_mingw_wrappers
* 9efecfc application.sh: cleanups
* a89df96 llvm-mingw.sh: set WINEPATH for tests
* 88fee08 llvm-mingw.sh: comment out libunwind merge
* 3568197 llvm-mingw.sh: -DLIBCXX_ENABLE_SHARED=ON
* abbe92e llvm-mingw.sh: -DLIBUNWIND_ENABLE_SHARED=ON
* 17ef5cb llvm.sh: comment out extra internal links
* e007c81 llvm.sh: cleanup and reformat
* bacbd8d llvm.sh: comment out -DBUILD_SHARED_LIBS=OFF
* 9c2fde9 llvm.sh: comment out some benign options
* f8f1ec1 llvm.sh: add -DZLIB_INCLUDE_DIR
* 1b8cd17 llvm.sh: cleanup & reformat
* 438646e llvm.sh: comment out explicit libs
* 7b22207 llvm.sh: cleanup & reformat
* 0458444 llvm.sh: comment out libxar patch
* 3749c93 llvm*.sh: add llvm-size

## 2023-01-07

* 895a0c8 README update
* 9970f9a versioning.sh: enable i686-w64-mingw32 triplet
* 4f28b1d versioning.sh: fix typo
* 50f5b78 llvm-mingw.sh: i686-windows-gnu
* da913f3 versioning.sh: fix *wrappers_stamp_file_path
* 15977bc llvm-mingw.sh: iterate test for all triplets
* 06b3875 llvm-mingw.sh: rework 32-bit triplets
* b830e28 llvm-mingw.sh: comment out unused definitions
* 9e74795 llvm-mingw.sh: more comments
* 0bbd4dd llvm-mingw.sh: cleanup test_mingw_llvm
* 89eaf1f llvm-mingw.sh: explicit -DZLIB_INCLUDE_DIR
* 3ff63a8 versioning.sh: rework x64 bootstrap
* db921b9 versioning.sh: rework clang_add_mingw_wrappers
* 1473108 application.sh: *_ALL_SYS_FOLDERS_TO_RPATH="y"
* 2c30cbe README-DEVELOP.md: update from upstream
* 337932e package.json: remove mingw-gcc dep for windows
* 77dbc2e wrappers: update from upstream

## 2023-01-06

* 9694dfd llvm.sh: *_RUNTIMES=libcxx;libcxxabi;libunwind
* 79c3e42 llvm*.sh: cmake -LH only when IS_DEVELOP

## 2023-01-05

* 9846f78 Revert "versioning.sh: prepare_clang_env"
* 291fcd4 Revert "package.json: use clang for linux"
* 5e72301 llvm-mingw.sh:  cmake ${XBB_JOBS}
* cbccfda llvm.sh:  cmake ${XBB_JOBS}
* 0b3409f llvm*.sh: -LH
* 678c6ef package.json: use clang for linux
* 6a6822c versioning.sh: REQUIRE_RPATH="n"
* d08253b versioning.sh: prepare_clang_env
* 8931d23 llvm.sh: explict --parallel ${XBB_JOBS}

## 2023-01-04

* 2e64a88 llvm.sh: add homebrew makefiles comment
* 83f913a llvm.sh: -DCOMPILER_RT_ENABLE_MACCATALYST=OFF
* c2cb9a7 llvm.sh: use llvm-libtool-darwin
* cf6d3db llvm.sh: -lrt -lpthread -lm
* 5ff566e llvm-mingw.sh: add -lm
* da39d37 llvm.sh: -DCOMPILER_RT_ENABLE_IOS=OFF
* 6b49b0f llvm-mingw.sh: -lrt -lpthread
* 52c8246 CHANGELOG update
* 2a1884c prepare v15.0.6-1

## 2023-01-04

* v15.0.6-1 prepared
* 6745afe versioning.sh: add 15.* definitions
* 7a38c86 add llvm-15.0.6-1.git.patch
* 5209844 llvm-mingw.sh: show_host_libs only on non windows
* f20d79a llvm.sh: show_host_libs only on non windows
* 6a2a7f2 llvm.sh: cleanup *_STATIC_GCC
* 512d3d9 package.json: xpm trace & next
* 22378de package.json: bump deps
* a85e535 re-generate workflows

## 2023-01-02

* 0420f9a package.json: add gcc to windows deps

## 2023-01-01

* ab61310 package.json: pass xpm version & loglevel
* 910ee02 README update

## 2022-12-31

* fdd15a6 llvm-mingw.sh: nm libc++.a only for IS_DEVELOP
* a13825c llvm-mingw.sh: LDFLAGS+=" -ldl"

## 2022-12-30

* 21339f0 llvm.sh: LDFLAGS+=" -ldl"
* 067b7eb README-MAINTAINER: xpm run install
* ab7f873 package.json: bump deps
* a9d1a28 regexp

## 2022-12-27

* 53ccba1 README update
* 862453f echo FUNCNAME[0]
* 9dbf92f use autotools_build
* 75d2320 re-generate from templates
* df1e5f4 cosmetics: move versions to the top

## 2022-12-26

* 0e42426 cosmetics: move shift inside case esac
* 9ef586c README updates

## 2022-12-25

* d6b6594 README update
* 8cfc9d6 versioning.sh: remove explicit xbb_set_executables_install_path
* 3bcbee0 package.json: add m4 dep
* d37cf53 versioning.sh: add comment M4

## 2022-12-24

* 03d370b versioning.sh: explicit set_executables
* 1cbe594 prepare v14.0.6-3
* 7c06ea2 rename *.git.patch
* a4c4a8a re-generate workflows
* a749b6d package.json: bump deps
* 4b3faaf README updates
* c82c57d CHANGELOG.md: bullet lists
* 3bf178e tests/update.sh: show libstdc++
* 4df890b rename functions

## 2022-08-31

* v14.0.6-2.1 published on npmjs.com
* v14.0.6-2 released

## 2022-08-30

* v14.0.6-2 prepared

## 2022-08-21

* v14.0.6-1.1 published on npmjs.com
* v14.0.6-1 released

## 2022-08-20

* v14.0.6-1 prepared

## 2022-03-24

* v13.0.1-1.1 published on npmjs.com
* v13.0.1-1 released

## 2022-03-23

* v13.0.1-1 prepared

## 2022-02-08

* v12.0.1-2.2 published on npmjs.com
* v12.0.1-2 released

## 2022-02-06

* v12.0.1-2 prepared again
* XBB_NCURSES_DISABLE_WIDEC="y"
* update for new helper

## 2021-11-21

* v12.0.1-2 prepared
* update for Apple Silicon

## 2021-10-22

* v12.0.1-1.2 published on npmjs.com
* v12.0.1-1.1 published on npmjs.com
* v12.0.1-1 released

## 2021-10-20

* v12.0.1-1 prepared

## 2021-07-09

* bump to 12.0.1, 11.1 fails to build with mingw

## 2021-05-27

* content copied from gcc-xpack
