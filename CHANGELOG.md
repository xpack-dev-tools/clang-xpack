# Change & release log

Entries in this file are in reverse chronological order.

## 2024-08-31

* v18.1.8-2 published on npmjs.com
* e94424e package.json: update urls for 18.1.8-2.1 release
* e0762fd blog post release 18.1.8-2 published
* b2546bf CHANGELOG update
* 7540776 llvm.sh: ignore two coverage tests

## 2024-08-30

* 590ed0b build-assets/package.json bump deps
* d1ab8c0 website/development-durations update
* 5dc6fa9 prepare v18.1.8-2
* d80a02c llvm*.sh: use --clang-coverage
* 0ce42b5 llvm.sh: run coverage test on all Linux architectures
* 0ecd41d llvm.sh: run coverage test on arm64 macOS too
* feb08d9 llvm-mingw.sh: fix dynamic sanitizers

## 2024-08-29

* 9e45b32 llvm-mingw.sh: use ${bits_option}
* 40b67e9 llvm*.sh: add --coverage
* 8f131a3 build compiler_rt --bootstrap
* 3ee65c7 README update
* f188482 llvm-mingw.sh: build entire /compiler-rt
* 0202bc5 llvm-mingw.sh: explicit COMPILER_RT_BUILD_PROFILE & SANITIZERS
* da5433f llvm*.sh: move download up

## 2024-08-17

* c2dec6c website update
* 9479c60 build-assets/package.json update
* df27ccd templates updates
* d5dab63 re-generate workflows
* 1906cc0 website update
* baaaf4b website update
* 11d7eca build-assets/templates updates
* e654fc4 website: add tests folder
* ea7c91a website update
* b43eb92 README update
* d23bbf9 build-assets/templates updates
* 9ab400e build-assets/package.json: customFields

## 2024-08-16

* d6db961 website: re-generate commons
* cc5fb08 build-assets/package.json: bump deps
* 4bcf7a2 re-generate workflows
* 04a9ee5 templates/body-github: update

## 2024-08-14

* c98b155 build-assets/package.json: updates

## 2024-08-09

* 6b15d6d READMEs update
* c97e2a4 package.json: git+https
* f778202 build-assets/package.json: updates
* 2d66b44 templates/body-blog update

## 2024-08-07

* 4af3b48 build-assets/package.json: updates
* 16c7116 build-assets/package.json: updates
* 5774a08 website: preliminary content
* 48e192f re-generate workflows
* 0e3d952 move to build-assets

## 2024-08-06

* b813718 package.json: bump deps

## 2024-08-04

* 99e52f7 package.json: bump deps
* ece6517 package.json: update generate-workflows
* bcf677f templates/jekyll update
* edf40e9 versioning.sh: use XBB_BUILD_ROOT_PATH
* 1729925 llvm-*.sh : use is_development
* 8ce8779 READMEs update
* 4534895 package.json: add actions, bump deps

## 2024-07-27

* 5d6d6f9 package.json: add actions, bump deps
* 8b0848b templates/jekyll update

## 2024-07-23

* b7f2706 READMEs update
* cdf37cb README update
* 8dc991a body-jekyll update
* c3c8f3f re-generate workflows
* f1e097b package.json: rework generate workflows
* dcd2e78 package.json: loglevel info
* c846cfb package.json: bump deps

## 2024-06-25

* bde765e 18.1.8-1.1
* 4cd3176 CHANGELOG: publish npm v18.1.8-1.1
* fa26cc8 package.json: update urls for 18.1.8-1.1 release
* cb8c90e README update
* b5da3f0 body-jekyll update
* e21ced6 CHANGELOG update
* bde765e 18.1.8-1.1
* 4cd3176 CHANGELOG: publish npm v18.1.8-1.1
* fa26cc8 package.json: update urls for 18.1.8-1.1 release
* cb8c90e README update
* b5da3f0 body-jekyll update
* e21ced6 CHANGELOG update
* f78ebfe README update

## 2024-06-24

* 4802079 package.json: bump deps
* 3c15b59 README update
* a40b446 llvm.sh: skip --crt without --libc++
* 4abc439 llvm.sh: XBB_SKIP_TESTS_ALL_LTO_LD
* 974e109 llvm.sh: XBB_SKIP_TESTS_ALL_LTO_LD for arm
* d980ac9 package.json: bump deps
* a68af3a llvm.sh: XBB_SKIP_TESTS_ALL_LTO_LD

## 2024-06-22

* 7e04f4d llvm.sh: update arm ignores
* f684c4e prepare v18.1.8-1
* 375d1fb package.json: bump deps
* ef54f13 re-generate workflows

## 2024-06-21

* 3eadee3 re-generate workflows
* c84d50d 17.0.6-3.1
* 5eba4df CHANGELOG: publish npm v17.0.6-3.1
* v17.0.6-3.1 published on npmjs.com
* 5e31ab4 package.json: update urls for 17.0.6-3.1 release
* 52a8c5c README update
* 6b4c320 package.json: bump deps
* bcfc303 llvm.sh: more ignores for intel 32-bit static
* e30dc09 package.json: bump deps
* 07e5074 llvm.sh: cosmetics
* bbf395b llvm.sh: XBB_SKIP_TEST_ALL_STATIC_ATOMIC
* db9816c run.sh: add verbosity
* 73eba5d README update
* cd6363f llvm.sh: add more arm32 ignores

## 2024-06-20

* fb0ec15 package.json: bump deps
* f9ddf7a prepare v17.0.6-3
* 1c389a7 README update
* c096f01 prepare v18.1.8-1
* b71198a prepare v18.1.8-1
* a4ad300 llvm.sh: cosmetics
* 6ebdfd2 llvm.sh: ignore some more arm 32 tests
* 86cbd29 llvm.sh: loop 32 64 in x64 tests
* e243a16 llvm.sh: no explicit RUNTIME_TARGETS for Arm
* 01aa5dd body-jekyll-release update
* 09eb07f llvm.sh cosmetics
* 48bfb29 re-generate workflows

## 2024-06-18

* 8b41c5b READMEs update

## 2024-06-17

* 6a8cf67 package.json: rework generate workflows
* 51bc264 package.json: bump deps

## 2024-06-14

* 1efee76 README update
* 9d10888 versioning.sh: add empty libssp.a to bootstrap
* 920b954 llvm-mingw.sh: add --bootstrap
* 8fab7d2 llvm.sh: add quotes to libcxx_file_path

## 2024-06-13

* b1f0dd3 versioning.sh: add empty libssp.a
* cbace30 llsn.sh: rename XBB_SKIP_TEST_ALL_BUFFEROVERFLOW
* d766270 llvm.sh: validate libc++.dll path

## 2024-06-12

* d33d963 README update
* 0217507 llvm.sh: update comments
* 076244f run.sh: skip ld.gold test if SYSTEM_TOOLS
* 86514f7 llvm.sh: cosmetics
* 8ad353a llvm.sh: fix comment
* cd6ef78 llvm.sh: fix old compiler version 4
* 18ab4e6 llvm.sh: reorder LLVM_VERSION to front
* 032add6 Merge branch 'xpack-develop' of https://github.com/xpack-dev-tools/clang-xpack into xpack-develop
* c4b234b llvm.sh: ignore throwcatch-main -flto only on intel
* 81c2c9c llvm.sh: skip some -print-* on older clang
* 49048b8 llvm.sh: disable SDK test
* e6b6770 llvm.sh: add support for XBB_TEST_SYSTEM_TOOLS
* a491ded llvm*.sh: modularise
* ea91824 llvm.sh: fix export
* 4c3ec0d llvm.sh: XBB_SKIP_TEST_BUFFEROVERFLOW
* 5bef30d llvm.sh: add ignore 16 arm

## 2024-06-11

* 619de30 llvm.sh: XBB_IGNORE 16 update
* 1b6ef77 llvm.sh: update XBB_IGNORE for 16
* 2509ba7 application.sh: update NPM_PACKAGE
* 78e60c1 llvm.sh: update XBB_IGNORE_*
* eeeaac4 re-generate scripts
* 5fb9ec5 re-generate workflows
* ea73cab llvm.sh: clangd tests cases

## 2024-06-10

* f5f1334 CHANGELOG update
* f5d7264 llvm*.sh: update XBB_IGNORE_*
* 42c9bb2 package.json: bump deps
* 89f994f README update
* 6d8454c prepare v18.1.7-1

## 2024-05-29

* 0246321 llvm*.sh: rename XBB_IGNORE_TEST_
* b86fcd4 llvm*.sh: update skips for 18
* be0e60e llvm.sh: update skips for 18
* bf88f77 prepare v18.1.6-1

## 2024-05-28

* f5b7c95 llvm.sh: more skips
* 0ba675e test-xpm.yml: try macos-14
* 12f5e16 llvm.sh: more arm 32 skips
* 2689f24 package.json: bump deps
* 31e7b08 package.json: bump deps
* 2d61121 llvm.sh: reorder skips for arm
* 5d6c717 17.0.6-2.1
* de316f0 CHANGELOG: publish npm v17.0.6-2.1
* b929cdd package.json: update urls for 17.0.6-2.1 release
* fc476a2 CHANGELOG update
* 7203256 README update
* 89a594d llvm.sh: update skips
* 21ad0d9 package.json: bump deps
* 58ed89e re-generate workflows
* e91901b build-xbbla32.yml: try to restart tests
* f9d0b42 build-xbbla32.yml: try to restart tests
* 8e5c935 build-xbbla32.yml: try to restart tests
* 012d684 build-xbbla32.yml: try to restart tests
* 2f5fe99 llvm.sh: fix arm 32 skip
* 49db494 test-docker-linux-intel.yml: temporarily simplified
* 52de703 package.json: bump deps

## 2024-05-27

* f1d98c4 llvm.sh: fix Arch conditionals
* 4482a5c llvm.sh: add openSUSE static skips
* 5f630f6 re-generate workflows
* 575b4cc test-docker-linux-intel: temporarily simplify for arch
* f1abe5b llvm.sh: verbose lsb_release
* 2da7380 llvm.sh: skip static for archlinux
* 5cb8548 package.json: bump deps
* 02e2368 package.json: bump deps
* 1888b85 Revert "test-prime.yml: enable -x for macOS"
* 15a4eed package.json: bump deps
* b8a3bcc test-prime.yml: enable -x for macOS
* bae9eac package.json: bump deps
* 89a6cf8 re-generate workflows
* 9a347e3 re-generate workflows
* 71769d3 package.json: bump deps
* 0947ad3 llvm.sh: skip static tests in redhat and fedora
* b9a9fb7 Revert "temporarily skip cleaning"
* 70dbc6b temporarily skip cleaning
* 81b933d llvm.sh: skip 2 more arm32 tests
* 19ef537 re-generate workflows
* 0e35075 llvm-mingw.sh: make c-cpp folder writable
* f744fe0 llvm.sh: make c-cpp folder writable

## 2024-05-26

* 5ac0245 re-generate workflows
* 4f2da05 .vscode/settings.json: ignoreWords
* dfc9c39 README update
* 86b767c package.json: bump deps

## 2024-05-25

* 1d77ff6 CHANGELOG update
* d4cee0b llvm-mingw.sh: skip bufferoverflow
* 555fab6 llvm.sh: update arm skips
* 275b588 llvm.sh: separate arm64 skips
* c623eb7 llvm.sh: update skips
* c74d379 llvm.sh: more comments

## 2024-05-24

* 51bc355 llvm.sh: update tests for macOS
* a15b3c1 Merge branch 'xpack-develop' of https://github.com/xpack-dev-tools/clang-xpack into xpack-develop
* 9384794 llvm.sh: update skips for continuation
* f6905e0 llvm.sh: arm64 skips from x64
* abd70a5 llvm.sh: skipsome tests for arm (not all)

## 2024-05-23

* 3623d6e llvm.sh: skip tests for 17
* 1aad9e5 llvm.sh: skip tests for 17
* 2507768 Merge branch 'xpack-develop' of https://github.com/xpack-dev-tools/clang-xpack into xpack-develop
* b7ca190 VERSION 17.0.6-2 for release
* be38112 llvm.sh: skip more macOS for 18
* f21d371 llvm.sh: skip tests on 18
* 91fb21a package.json: clang 16.0.6-1.1
* df0c846 CHANGELOG update
* 2b9e8a2 CHANGELOG update

## 2024-05-19

* 7fea3b9 llvm*.sh: rename XBB_ACTUAL_LLVM_VERSION
* d45c35d VERSION 18.1.6-1
* fd6124d llvm.sh: add 18 to test skips

## 2024-05-18

* 38c9f6f llvm-*.sh: add llvm_download
* 9caaa05 READMEs update
* be09e11 package.json: XBB_ENVIRONMENT_SKIP_CHECKS

## 2024-05-16

* 4ce6f1e READMEs update
* 75157c4 versioning.sh: ncurses with --disable-lib-suffixes

## 2024-05-15

* e2b3b06 llvm.sh: no need to disable curses
* 4e5f8aa llvm.sh: LLDB_ENABLE_CURSES=OFF only for linux
* 8d428c4 llvm.sh: disable curses for clang 17
* 98f1049 llvm-17: remove terminfo patch (again)

## 2024-05-14

* dfb4101 Revert "llvm-17... remove terminfo patch"
* 03c8746 versioning.sh: ncurses with --disable-lib-suffixes
* ec7b322 VERSION 17.0.6-2
* d5af1e8 llvm-17... remove terminfo patch
* 7bedb28 remove llvm-18 patch
* c682cdd llvm.sh: remove ref to include/ncurses

## 2024-05-13

* fcb462e versioning.sh: remove --disable-widec
* f28a4f3 versioning.sh: ncurses_build --disable-widec
* 09af880 Merge branch 'xpack-develop' of https://github.com/xpack-dev-tools/clang-xpack into xpack-develop
* c4547ea llvm-17.0.6-2.git.patch: add AddLLDB.cmake patch
* 5c66cad VERSION 18.1.5-1
* 82ef616 llvm.sh: re-enable macOS tests
* 1140926 llvm-17.0.6-2.git.patch: add Terminfo::terminfo
* 8ff30f3 llvm.sh: comment out explicit -lncurses

## 2024-05-09

* 5cc1090 versioning.sh: add comments
* f6401ef use is_develop and with_strip

## 2024-05-07

* 9aff28f llvm.sh: add unsupported case
* 7699c4f llvm.sh: disable static sleepy cv on linux
* 4c8644b versioning.sh: remove DISABLE_WIDEC

## 2024-05-03

* 4f2db2c README update
* 1b79709 README update
* 8da4603 versioning.sh: update 18.x deps

## 2024-05-02

* 7295d02 package.json: clang 17.0.6-1.1
* a77c0d1 llvm.sh: use both -L and -rpath
* 4355faa llvm.sh: use -rpath

## 2024-04-30

* 2b6d2a6 llvm.sh: macOS tests update
* 2edcbae llvm.sh: rework tests for macOS arm
* 09f08c0 llvm.sh: fix syntax
* 510b549 llvm.sh: reorder Linux x64 tests
* 66b3713 llvm.sh: reorder Linux arm tests
* 6225767 package.json: add bison to silence macOS
* c87ae0e llvm.sh: cosmetics
* 46b7084 llvm.sh: linux skips for arm too

## 2024-04-29

* 1b054cd llvm.sh: add more linux tests
* 6a89965 llvm-mingw.sh: update tests
* 9e51098 llvm.sh: cosmetics
* 3990a1f llvm.sh: update linux & win32 tests
* 3a6167b versioning.sh: skip bootstrap tests if not bootstrap only

## 2024-04-27

* a593adf llvm.sh: comment out mkdir
* 8720bc8 llvm.sh: conditional -DCMAKE_OSX_DEPLOYMENT_TARGET
* 3525761 application.sh: update deps
* 1175849 llvm-mingw.sh: update tests
* 824a897 llvm.sh: update tests for macOS

## 2024-04-22

* 1bfd73c rename test_compiler_*

## 2024-04-07

* 86a2e94 READMEs updates
* 0980ad6 versioning.sh: add xz warning
* 274c0de llvm.sh: create lib folder for rpath
* 4f62ceb README update

## 2024-04-06

* 530bad6 llvm.sh: add ${llvm_folder_name}/lib to rpath
* 299cc37 package.json: build 17.0.6-2 with 16.0.6

## 2024-04-05

* bc3de71 README update
* 69437ac llvm-17.0.6-2 path with latest hb content
* 07babd6 llvm.sh: move compiler-rt to RUNTIMES

## 2024-04-04

* 00657b1 VERSION 17.0.6-2
* 34cf82d add 17.0.6-2 patch
* 95d0dfe package.json: bump deps
* 87f7637 llvm*.sh: cp -R

## 2024-03-22

* c993075 package.json: xpm-version 0.18.0

## 2024-03-08

* 24efb0e package.json: xpm-version 0.18.0

## 2024-03-07

* c5d1853 package.json: xpm-version 0.18.0
* 51e42b1 package.json: bump deps

## 2024-03-06

* 85b2cef versioning.sh: use released 18.1.0
* 2079c73 body-jekyll update
* b8c4ab0 package.json: bump deps

## 2024-02-08

* 0a665ca patches README update
* 2502a4b versioning.sh: add 18.x
* 57687aa llvm.sh: customise archive via environment

## 2024-02-07

* 01bc5ea prepare v18.1.0-1
* 3e6e338 READMEs update
* 5cdb88c package.json: bump deps

## 2023-12-04

* aa6e3ca 17.0.6-1.1
* c97636e package.json: update urls for 17.0.6-1.1 release
* db0ea9a README update
* cc16ad7 CHANGELOG update

## 2023-12-03

* 1a16300 package.json: bump deps
* 5d69434 re-generate workflows
* 833d4c9 body-jekyll update
* 6e01873 README update

## 2023-12-01

* 38f9c3d README update
* 9b36a75 CHANGELOG update
* 6390f72 package.json: update bins
* e56f686 package-lock.json update
* 0ee8e14 README update
* bd0e812 versioning.sh: bump deps
* 0f7c3b4 llvm.sh: edit less used files
* 0a2499a llvm*.sh: add llvm-cxxfilt
* 3cf68aa prepare v17.0.6-1
* 62d6611 README update
* 79ab3e3 Revert "wrappers: temporarily disable *-no-unused-arguments"
* f7b54e8 llvm-mingw.sh: disable HELLO_WEAK_CPP for 14
* cbdc459 llvm.sh: disable HELLO_WEAK_CPP for 14
* e8f8714 README update
* e5e4f26 llvm.sh: disable throwcatch for 14, 13
* ce7429d llvm.sh: disable clangd unchecked-exception for 14 too

## 2023-11-30

* 7c8f109 VERSION 14.0.6-3
* 58a292e add llvm-14.0.6-3.git.patch
* 5ca48fd wrappers: temporarily disable *-no-unused-arguments
* c139563 llvm.sh: skip clangd on all platforms
* 8a41095 llvm.sh: skip clangd unchecked-exception on 13
* a4fd752 add 13.0.1-2
* cb5def4 README update

## 2023-11-14

* c3a705f 17.0.5-1
* 26a6229 17.0.5-1

## 2023-11-13

* 982a0b9 llvm.sh: no LLVM_USE_LINKER=ld for macOS

## 2023-11-12

* c6b0833 package.json: bump deps

## 2023-10-31

* 26c149d 17.0.4-1

## 2023-10-10

* 759dfbe llvm-*.sh: use XBB_WITH_STRIP to strip
* ce62f08 README update
* fb08fe1 llvm-17.0.2-1.git.patch remove CMAKE_BUILD_WITH_INSTALL_RPATH

## 2023-10-09

* 65ff9d2 llvm.sh: use LLVM_NATIVE_TOOL_DIR for windows
* e7f351b llvm-mingw.sh: explicit HAS_WIN32_THREAD
* db03b10 llvm-mingw.sh: use XBB_WITH_STRIP for non DEVELOP
* 9e61d97 llvm-mingw.sh: do not strip in DEVELOP
* 348487a versioning.sh: bump deps

## 2023-10-06

* 46bae30 llvm.sh: use check-clang
* 625a164 llvm.sh: CMAKE_BUILD_WITH_INSTALL_RPATH=ON for windows
* a168fb9 llvm-17.0.2-1.git.patch update

## 2023-10-05

* 724702e add .vscode/launch.json
* 7163f00 llvm.sh: explicit ON to enable tests
* 6e2dc65 llvm.sh: full check
* bfa0834 llvm.sh: add -lncurses for macOS
* dbd406b prepare v17.0.2-1
* c133469 add llvm-17.0.2-1 patch
* ed91025 llvm.sh: add llvm_enable_tests
* de6c91c llvm.sh: use XBB_WITH_STRIP on non develop
* ba3a0f6 llvm.sh: disable InstalledDir test

## 2023-09-28

* 269454d README update
* f0ccf0a llvm.sh: skip some LTO tests on macOS
* c16b374 README update
* a87c1cd prepare v17.0.1-1

## 2023-09-25

* a7914c2 README update
* be4c98a body-jekyll update

## 2023-09-20

* 3164a57 package.json: bump deps

## 2023-09-19

* 0e1bd5e README-DEVELOP: add link to bug

## 2023-09-16

* 63e1f63 package.json: add linux32
* c447a8f body-jekyll update

## 2023-09-11

* 915caee package.json: bump deps

## 2023-09-08

* 18772f6 package.json: bump deps
* e075fde clang.sh: cleanups
* 855bdca llvm.sh: xbb_get_libs_path "${CXX}"
* 11bb34d re-enable libiconv_build

## 2023-09-07

* 5785339 README update

## 2023-09-06

* 86c491d README update
* c575586 package.json: bump deps
* c18a463 READMEs update
* dec756d body-jekyll update

## 2023-09-05

* 11c3418 llvm.sh: run_verbose diff
* 1558e58 dot.*ignore update
* 626c5d9 re-generate workflows
* 726accd READMEs update
* 4892e62 package.json: bump deps

## 2023-09-03

* 34169cd package.json: bump deps
* b123b64 application.sh: remove autotools
* b3e4af2 versioning.sh: disable autotools

## 2023-08-28

* 4ecd182 READMEs update

## 2023-08-25

* 6343788 package.json: rm xpack-dev-tools-build/*
* 8dbfe2b remove tests/update.sh
* 3631e02 package.json: bump deps

## 2023-08-21

* e018e5c READMEs update
* 646bd37 package.json: bump deps

## 2023-08-19

* 0da0e2d READMEs update
* 8503fab package.json: bump deps

## 2023-08-15

* f4911c8 re-generate workflows
* 80916c4 README-MAINTAINER rename xbbla
* c2c68d1 package.json: rename xbbla
* 74caa21 package.json: bump deps
* b674116 READMEs update
* 242e3c3 README update

## 2023-08-14

* 8182d40 add 16.0.6-2 patch
* 80f7c49 16.0.6-2.1.pre

## 2023-08-06

* 023b563 16.0.6-1.1
* d89cff8 .npmignore wrappers
* 75fd2c2 CHANGELOG: publish npm v16.0.6-1.1
* 86ea389 package.json: update urls for 16.0.6-1.1 release
* cbb2414 package.json: update bins
* 6142b84 README: update tree -L 2
* 8133ee6 templates/jekyll update
* 9e20f36 CHANGELOG update
* ccf3180 templates/jekyll: update
* 177d568 llvm*.sh: fix typo in comments
* cc300ae README update
* c26de86 README-MAINTENANCE update durations
* c4edcc2 CHANGELOG update

## 2023-08-05

* f30423c llvm.sh: skip InstalledDir for windows
* a27571c llvm.sh: test InstalledDir
* 0b903db READMEs update
* dc93119 prepare v16.0.6-1
* 982586a llvm-16.0.6-1.git.patch update
* 1a879ea package.json: bump clang 15.0.7-4.1
* 674edac 15.0.7-4.1
* dbbcc90 CHANGELOG: publish npm v15.0.7-4.1
* 0a6565a package.json: update urls for 15.0.7-4.1 release
* b5f98b2 CHANGELOG update
* 99b29c0 llvm-15.0.7-4.git.patch fix int len for mingw
* 2110354 CHANGELOG update

## 2023-08-04

* d048d53 llvm-15.0.7-4.git.patch PROC_PIDPATHINFO_SIZE+1
* a057b14 llvm-15.0.7-4.git.patch clang-format
* 777220f llvm-15.0.7-4.git.patch update
* 537280f READMEs update
* b8dd94d package.json: version 15.0.7-4.1.pre
* 8da2604 prepare v15.0.7-4
* f660dac READMEs update
* eada3a8 package.json: add build-develop-debug
* a1c526b package.json: version 16.0.6-1.1.pre
* 6dd4d22 package.json: bump clang 15.0.7-3.1
* a482ea8 prepare v16.0.6-1
* 965e207 15.0.7-3.1
* 2338d8e CHANGELOG: publish npm v15.0.7-3.1
* v15.0.7-3.1 published on npmjs.com
* a6fd6bb package.json: update urls for 15.0.7-3.1 release
* 22387bd templates/jekyll update
* 8b04236 CHANGELOG update
* v15.0.7-3 released
* 5634e96 llvm.sh: --lto --lld for linux x64 tests
* 9f0d8b1 update.sh: add libatomic for redhat/fedora
* 042c330 READMEs update

## 2023-08-03

* 9b1ff65 package.json: reorder build actions
* 32fb061 .vscode/settings.json: ignoreWords
* 54f2cb5 READMEs update
* 8086620 package.json: bump helper 1.5.0
* 4529607 re-generate workflows
* 00bc9ba llvm.sh: skip weak.cpp -flto
* 6b3b740 llvm-mingw.sh: skip weak.cpp -flot
* 4ebac02 llvm.sh: document -print-file-name
* ade55b8 llvm-mingw.sh: WINEPATH -print-file-name
* de34e1d README update
* 9f57a4d versioning.sh: use apple_clang only for 15.0.7-3
* aaae5a5 prepare v15.0.7-3 (again)
* c39c94d VERSION 16.0.6-1
* 4cdfd69 versioning.sh: temporarily all use apple_clang_env
* 206fb18 llvm.sh: remove patch to disable XRAY
* 98c2fd4 llvm.sh: add DARWIN_osx_*
* 48de38e llvm.sh: EXTERNAL_COMPILER_RT=OFF

## 2023-08-02

* f3fb95e VERSION 15.0.7-3
* 9e99ccf llvm.sh: disable XRAY for macOS
* 036993e .git/.npm ignore build*/
* 67711f3 llvm-15.0.7-3.patch: remove CLT c++/v1 path
* ef80a68 versioning.sh: # XBB_DO_REQUIRE_RPATH="n"
* 45d7402 versioning.sh: fix condition for apple_clang_env
* db8347f versioning.sh: apple_clang_env only x64 15.0.7-3
* ef2bd0d llvm.sh:  skip LTO_THROWCATCH_MAIN for clang 15
* 010efc9 llvm.sh: add --libc++ --crt tests for linux x64
* ed78823 llvm.sh: platform specific linker definitions
* dd8dd76 16.0.6-1 patch from homebrew

## 2023-08-01

* 12a47df remove 16.0.6-1 patch
* f2eaf25 llvm.sh: ${llvm_version_major} -ge 16
* 5c8e1ce llvm-mingw.sh: ${llvm_version_major} -ge 16
* c57a659 llvm-mingw.sh: cleanups
* 2008ab8 llvm.sh: adjust SKIP_RUN_TEST for clang 16
* 0bc2178 llvm*.sh: fix clang/${llvm_version_major} path
* 74a7f80 llvm-mingw.sh: list llvm-mingw releases
* 8213aa4 llvm.sh: comment out SKIP_TEST for windows
* fcd3126 llvm.sh: comment out SKIP_RUN_TEST for linux
* 3e5d92d llvm.sh: compute llvm_version_major
* 213c643 README update
* 5d56958 split README-DEVELOP-MSTORSJO
* 23327cb llvm.sh: cosmetics in comments
* 1f6f085 llvm.sh: -DCMAKE_LINKER=${LD}
* 9920f8d llvm.sh: -DLLD_DEFAULT_LD_LLD_IS_MINGW=ON win32
* b6f842c versioning.sh: comments
* 8555615 versioning.sh: reorder mingw_wrappers
* e6588ec llvm-mingw.sh: cosmetics
* bfe56e5 llvm-mingw.sh: refer to mstorsjo/llvm-mingw
* cb7205c llvm-mingw.sh: comment out tests skips, 16 all ok
* fe571a2 llvm-mingw.sh: compute llvm_version_major
* 87fc073 llvm-mingw.sh:  explicit --${bits} in tests
* 33fb772 llvm-mingw.sh: commented -mguard=cf
* cacbd5a llvm-mingw.sh: COMPILER_TARGET -w64-
* 7ad2d2e llvm-mingw.sh: explicit -DCMAKE_LINKER
* 4046a7f llvm-mingw.sh: explicit C/CXX_COMPILER_WORKS
* ab5d817 llvm-mingw.sh: /lib/clang/${clang_version_major}
* b768cef run_verbose_develop cd
* 619b632 wrappers: update from MS 20230614

## 2023-07-30

* d5fef62 VERSION temporarily 16.0.6-1
* 1032747 llvm.sh: add simple test with defaults for macOS
* 2323f4a llvm.sh: add simple test with defaults
* bfb126c llvm.sh: add clang -v to show selected gcc
* 1648240 add llvm-15.0.7-3.git.patch
* 7bca49b prepare v15.0.7-3

## 2023-07-29

* v15.0.7-3 prepared
* 5c226b3 README update
* fc747ec README update
* dfff0ce add llvm-16.0.6-1.git.patch
* 12d1b41 llvm.sh: disable compiler-rt on linux
* e22874c versioning.sh: add 16.*
* 51d93ff package-lock.json: update
* b2aef00 llvm.sh: remove XBB_SKIP_TEST_* for macOS 10.13

## 2023-07-28

* 90927b2 READMEs update
* 86762e9 READMEs update
* fcbea02 package.json: bump deps
* 2906240 package.json: liquidjs --context --template
* a25df25 scripts cosmetics
* 5538c58 re-generate workflows
* 6b33d7b READMEs update
* bded1a4 package.json: minXpm 0.16.3 & @xpack-dev-tools/xbb-helper
* a85e3ea READMEs update
* 2204b93 package.json: bump deps

## 2023-07-26

* 27a5e8d package.json: move scripts to actions
* b03c429 package.json: update xpack-dev-tools path
* 8810dc9 READMEs update xpack-dev-tools path
* cc58b05 body-jekyll update
* 2c30c15 READMEs update

## 2023-07-17

* 87d6eb1 package.json: bump deps

## 2023-03-31

* 7a2ea68 dependencies CMAKE=$(which cmake)

## 2023-03-25

* fb716dd READMEs update
* 1f7c1f0 READMEs update prerequisites
* 29bba41 package.json: mkdir -pv cache

## 2023-02-22

* 08ca79b READMEs update

## 2023-02-14

* f403243 body-jekyll update

## 2023-02-10

* 185e9f6 package.json: update Work/xpacks
* 2e05444 READMEs update

## 2023-02-07

* e91e4af READMEs update
* aaa5602 body-jekyll update
* a5838ed body-github update

## 2023-01-28

* d1b4e08 README-MAINTAINER remove caffeinate xpm
* 682e14d 15.0.7-2.1
* 0b2e318 CHANGELOG: publish npm v15.0.7-2.1
* 857c492 package.json: update urls for 15.0.7-2.1 release
* c9dbb55 body-jekyll update
* 10762e0 templates updates
* 5514716 CHANGELOG update
* 72a2829 llvm-mingw.sh: skip lto hello-weak.cpp
* v15.0.7-2 released
* 518c68e re-generate workflows
* ead1a25 package.json: bump deps
* 3ad9b1c CHANGELOG update

## 2023-01-27

* f0e47bd llvm*.sh: rework clangd test
* 5157bfa llvm.sh: use xbb_strip_macosx_version_min
* 539f211 use versioning functions
* ebfe33b README update
* 342db2c add llvm-15.0.7-2.git.patch
* 6ed6094 CHANGELOG update
* 637fbaa llvm-mingw.sh: cleanups
* f5b2397 package.json: bump deps
* 7d73ed9 package.json: reorder scripts
* 7f29c4f llvm.sh: filter out -mmacosx-version-min=
* 849fa98 llvm.sh: use MACOSX_DEPLOYMENT_TARGET
* v15.0.7-2 prepared
* 637fbaa llvm-mingw.sh: cleanups
* f5b2397 package.json: bump deps
* 7d73ed9 package.json: reorder scripts
* 7f29c4f llvm.sh: filter out -mmacosx-version-min=
* 849fa98 llvm.sh: use MACOSX_DEPLOYMENT_TARGET

## 2023-01-26

* f189fb4 prepare v15.0.7-2
* 1bd7e25 llvm.sh: check for libclang_rt.profile_osx.a
* b251f05 llvm.sh: cosmetics
* 4beb2a0 package.json: bump deps

## 2023-01-24

* 329f416 README updates

## 2023-01-22

* 9f916f9 package.json: bump deps
* de63159 llvm.sh: cleanups
* 23d40fe llvm.sh: enable clangd test for all platforms
* 01d1d41 templates/body-jekyll update
* e78c4f5 templates/body-jekyll update
* 6123f46 re-generate workflows
* v15.0.7-1.1 published on npmjs.com
* 7c2d6fd package.json: update urls for 15.0.7-1.1 release
* c7a1288 READMEs updates
* 36a69ec templates/body-jekyll update
* e955f14 CHANGELOG update
* c2aed60 README update
* 3a20bb7 tests/update.sh: fix redhat & suse 32-bit
* v15.0.7-1 released
* c2aed60 README update
* f4fd8c7 tests/update.sh: install 32-bit libs
* 696960b llvm.sh: skip tests that fail on windows
* 2d8a4ee llvm.sh: skip throwcatch-main refinements
* 2ffb87d llvm.sh: add XBB_SKIP_TEST* for macOS
* a0b54d7 llvm.sh: skip --crt tests on macOS
* c9e483b README update
* 5c18d35 package.json: bump deps
* 685a612 llvm.sh: automate multilib detection

## 2023-01-21

* 66df7cb README update
* fc13eda README update
* 58e176b Revert "llvm.sh: do not use XBB_LIBRARY_PATH on macOS"
* 7079a42 llvm.sh: do not use XBB_LIBRARY_PATH on macOS
* 51cf67b versioning.sh: comment out prepare_gcc
* 7810c34 package.json: bump deps

## 2023-01-20

* ebd39a6 llvm.sh: explicit aarch64 target
* 313a2c7 llvm.sh: cleanup arm config
* 76a1e60 llvm.sh: explicit LLVM_RUNTIME_TARGETS=armv7l
* bbefb72 llvm.sh: move ENABLE_PER_TARGET_RUNTIME to x64
* 02321bb update the 15.0.7-1 patch with CLT
* 1a26060 llvm.sh: explain why C_INCLUDE_DIR is not useful
* 15abb23 README update
* 565abed llvm.sh: enable defaults for linux
* a622654 llvm.sh: update macOS defaults
* c6babdf llvm.sh: remove include/polly
* 54f5da1 llvm.sh: split PROJECTS & RUNTIMES as per warning
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
