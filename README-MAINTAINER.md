[![license](https://img.shields.io/github/license/xpack-dev-tools/clang-xpack)](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/xpack-dev-tools/clang-xpack.svg)](https://github.com/xpack-dev-tools/clang-xpack/issues/)
[![GitHub pulls](https://img.shields.io/github/issues-pr/xpack-dev-tools/clang-xpack.svg)](https://github.com/xpack-dev-tools/clang-xpack/pulls)

# Maintainer info

## Prerequisites

The build scripts run on GNU/Linux and macOS. The Windows binaries are
generated on Intel GNU/Linux, using [mingw-w64](https://mingw-w64.org).

For details on installing the prerequisites, please read the
[XBB prerequisites page](https://xpack.github.io/xbb/prerequisites/).

## Get project sources

The project is hosted on GitHub:

- <https://github.com/xpack-dev-tools/clang-xpack.git>

To clone the stable branch (`xpack`), run the following commands in a
terminal (on Windows use the _Git Bash_ console):

```sh
rm -rf ~/Work/xpack-dev-tools/clang-xpack.git && \
git clone https://github.com/xpack-dev-tools/clang-xpack.git \
  ~/Work/xpack-dev-tools/clang-xpack.git
```

For development purposes, clone the `xpack-develop` branch:

```sh
rm -rf ~/Work/xpack-dev-tools/clang-xpack.git && \
mkdir -p ~/Work/xpack-dev-tools && \
git clone \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/clang-xpack.git \
  ~/Work/xpack-dev-tools/clang-xpack.git
```

Or, if the repo was already cloned:

```sh
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull
```

## Get helper sources

The project has a dependency to a common **helper**; clone the
`xpack-develop` branch and link it to the central xPacks store:

```sh
rm -rf ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
mkdir -p ~/Work/xpack-dev-tools && \
git clone \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/xbb-helper-xpack.git \
  ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git
```

Or, if the repo was already cloned:

```sh
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git
```

## Release schedule

This distribution follows the official
[LLVM clang](https://github.com/llvm/llvm-project/releases/) releases,
but only the final patch of each version is released (like *.0.6).
The rule is to wait for the new upstream release (like X.0.0), and
release the previous one (X-1.0.[567])

However, in order to spot possible issues, it is recommended to run
builds as soon as new versions are available (like X.0.1),
without making releases.

For Windows builds, wait for
[llvm-mingw releases](https://github.com/mstorsjo/llvm-mingw/releases).

## How to make new releases

Before starting the build, perform some checks and tweaks.

### Download the build scripts

The build scripts are available in the `scripts` folder of the
[`xpack-dev-tools/clang-xpack`](https://github.com/xpack-dev-tools/clang-xpack)
Git repo.

To download them on a new machine, clone the `xpack-develop` branch,
as seen above.

### Check Git

In the `xpack-dev-tools/clang-xpack` Git repo:

- switch to the `xpack-develop` branch
- pull new changes
- if needed, merge the `xpack` branch

No need to add a tag here, it'll be added when the release is created.

### Update helper & other dependencies

Check the latest versions at <https://github.com/xpack-dev-tools/> and
update the dependencies in `package.json`.

### Check the latest upstream release

Check the LLVM GitHub [Releases](https://github.com/llvm/llvm-project/releases)
and compare the the xPack [Releases](https://github.com/xpack-dev-tools/clang-xpack/releases/).
Find the latest release that seems stable, usually like X.0.6, sometimes X.0.7.

### Increase the version

Determine the version (like `18.1.7`) and update the `scripts/VERSION`
file; the format is `18.1.7-1`. The fourth number is the xPack release number
of this version. A fifth number will be added when publishing
the package on the `npm` server.

### Fix possible open issues

Check GitHub issues and pull requests:

- <https://github.com/xpack-dev-tools/clang-xpack/issues/>

and fix them; assign them to a milestone (like `18.1.7-1`).

### Check `README.md`

Normally `README.md` should not need changes, but better check.
Information related to the new version should not be included here,
but in the web release files.

### Update version in `README` files

- update version in `README-MAINTAINER.md`
- update version in `README.md`

### Update version in `package.json` to a pre-release

Use the new version, suffixed by `pre`, like `18.1.7-1.pre`.

### Update `CHANGELOG.md`

- open the `CHANGELOG.md` file
- check if all previous fixed issues are in
- add a new entry like _* v18.1.7-1 prepared_
- commit with a message like _prepare v18.1.7-1_

### Update the version specific code

- open the `scripts/versioning.sh` file
- add a new `if` with the new version before the existing code

### Merge upstream repo & prepare patch

To keep the development repository fork in sync with the upstream LLVM
repository, in the `xpack-dev-tools/llvm-project` Git repo:

- fetch `upstream`
- checkout the `llvmorg-18.1.7` tag in detached state HEAD
- create a branch like `v18.1.7-xpack`
- cherry pick the commit to _clang: add /Library/... to headers search path_ from a previous release;
  enable commit immediately
- push branch to `origin`
- add a `v18.1.7-1-xpack` tag; enable push to origin
- select the commit with the patch
- save as patch
- move to `patches`
- rename `llvm-18.1.7-1.git.patch`

Note: currently the patch is required to fix the CLT library path.

### Update Windows specifics

Identify the release and the tag at:

- <https://github.com/mstorsjo/llvm-mingw/releases>

```sh
rm -rf ~/Work/mstorsjo/llvm-mingw.git
mkdir -pv ~/Work/mstorsjo
git clone https://github.com/mstorsjo/llvm-mingw ~/Work/mstorsjo/llvm-mingw.git

git -C ~/Work/mstorsjo/llvm-mingw.git checkout 20231128
```

Compare with the previous release. If the differences are small, possibly
make the necessary adjustments and proceed.

If the changes are major, run the llvm-mingw build as documented in the
[README-DEVELOP-MSTORSJO](README-DEVELOP-MSTORSJO.md) to understand the
extend of the changes.

Check if there are changes in the tests, and update.

Check if there are changes in the wrappers, and update.

## Build

The builds currently run on 5 dedicated machines (Intel GNU/Linux,
Arm 32 GNU/Linux, Arm 64 GNU/Linux, Intel macOS and Apple Silicon macOS).

### Development run the build scripts

Before the real build, run test builds on all platforms.

#### Visual Studio Code

All actions are defined as **xPack actions** and can be conveniently
triggered via the VS Code graphical interface, using the
[xPack extension](https://marketplace.visualstudio.com/items?itemName=ilg-vscode.xpack).

### Bootstrap

The first step is to build and test only the bootstrap,
for this, un-comment a line in `application.sh`:

```sh
XBB_APPLICATION_BOOTSTRAP_ONLY="y"
```

After the bootstrap passes the tests, comment out this line and repeat.

#### Intel macOS

For Intel macOS, first run the build on the development machine
(`wksi`, a recent macOS):

```sh
export XBB_ENVIRONMENT_SKIP_CHECKS="y"

# Update the build scripts.
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull

xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git

git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git

xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git

xpm run deep-clean --config darwin-x64  -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm install --config darwin-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run build-develop --config darwin-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

For a debug build:

```sh
xpm run build-develop-debug --config darwin-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

The build takes about 80 minutes (1h20).

The tests report is:

```txt
Tests summary for clang 18.1.7-1 on darwin-x64 (macOS 14.3.1)

272 test cases passed, 0 skipped, 4 failed:

- xfail: lto-throwcatch-main
- xfail: gc-lto-throwcatch-main
- xfail: lto-lld-throwcatch-main
- xfail: gc-lto-lld-throwcatch-main

Verdict: tests reluctantly accepted
```

When functional, push the `xpack-develop` branch to GitHub.

Run the native build on the production machine
(`xbbmi`, an older macOS);
start a VS Code remote session, or connect with a terminal:

```sh
caffeinate ssh xbbmi
```

Repeat the same steps as before.

```sh
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json && \
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull && \
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git && \
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git && \
\
xpm run deep-clean --config darwin-x64  -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm install --config darwin-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run build-develop --config darwin-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

About 93 minutes later (1h33), the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xpack-dev-tools/clang-xpack.git/build/darwin-x64/deploy
total 229672
-rw-r--r--  1 ilg  staff  101978812 Jun 13 21:23 xpack-clang-18.1.7-1-darwin-x64.tar.gz
-rw-r--r--  1 ilg  staff        105 Jun 13 21:23 xpack-clang-18.1.7-1-darwin-x64.tar.gz.sha
```

The tests report is:

```txt
Tests summary for clang 18.1.7-1 on darwin-x64 (MacOSX 10.14.6)

256 test cases passed, 0 skipped, 20 failed:

- xfail: gc-hello-exception
- xfail: gc-exception-reduced
- xfail: lto-hello-exception
- xfail: lto-exception-reduced
- xfail: lto-throwcatch-main
- xfail: gc-lto-hello-exception
- xfail: gc-lto-exception-reduced
- xfail: gc-lto-throwcatch-main
- xfail: lld-hello-exception
- xfail: lld-exception-reduced
- xfail: lld-throwcatch-main
- xfail: gc-lld-hello-exception
- xfail: gc-lld-exception-reduced
- xfail: gc-lld-throwcatch-main
- xfail: lto-lld-hello-exception
- xfail: lto-lld-exception-reduced
- xfail: lto-lld-throwcatch-main
- xfail: gc-lto-lld-hello-exception
- xfail: gc-lto-lld-exception-reduced
- xfail: gc-lto-lld-throwcatch-main

Verdict: tests reluctantly accepted
```

#### Apple Silicon macOS

Run the native build on the production machine
(`xbbma`, an older macOS);
start a VS Code remote session, or connect with a terminal:

```sh
caffeinate ssh xbbma
```

Update the build scripts (or clone them at the first use):

```sh
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json && \
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull && \
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git && \
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git && \
\
xpm run deep-clean --config darwin-arm64  -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm install --config darwin-arm64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run build-develop --config darwin-arm64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

About 37 minutes later, the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xpack-dev-tools/clang-xpack.git/build/darwin-arm64/deploy
total 197848
-rw-r--r--  1 ilg  staff  95637479 Jun 13 20:28 xpack-clang-18.1.7-1-darwin-arm64.tar.gz
-rw-r--r--  1 ilg  staff       107 Jun 13 20:28 xpack-clang-18.1.7-1-darwin-arm64.tar.gz.sha
```

The tests report is:

```txt
Tests summary for clang 18.1.7-1 on darwin-arm64 (macOS 11.7.10)

262 test cases passed, 0 skipped, 14 failed:

- xfail: gc-hello-exception
- xfail: gc-exception-reduced
- xfail: lto-hello-exception
- xfail: lto-exception-reduced
- xfail: gc-lto-hello-exception
- xfail: gc-lto-exception-reduced
- xfail: lld-hello-exception
- xfail: lld-exception-reduced
- xfail: gc-lld-hello-exception
- xfail: gc-lld-exception-reduced
- xfail: lto-lld-hello-exception
- xfail: lto-lld-exception-reduced
- xfail: gc-lto-lld-hello-exception
- xfail: gc-lto-lld-exception-reduced

Verdict: tests reluctantly accepted
```

#### Intel GNU/Linux

Run the docker build on the production machine (`xbbli`);
start a VS Code remote session, or connect with a terminal:

```sh
caffeinate ssh xbbli
```

##### Build the Intel GNU/Linux binaries

Update the build scripts (or clone them at the first use):

```sh
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json && \
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull && \
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git && \
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git && \
\
xpm run deep-clean --config linux-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-prepare --config linux-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-link-deps --config linux-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-build-develop --config linux-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

About 110 minutes later (1h50), the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xpack-dev-tools/clang-xpack.git/build/linux-x64/deploy
total 215724
-rw-r--r-- 1 ilg ilg 220891481 Jun 13 18:17 xpack-clang-18.1.7-1-linux-x64.tar.gz
-rw-r--r-- 1 ilg ilg       104 Jun 13 18:17 xpack-clang-18.1.7-1-linux-x64.tar.gz.sha
```

The tests report is:

```txt
Tests summary for clang 18.1.7-1 on linux-x64 (Ubuntu 18.04)

2518 test cases passed, 0 skipped, 56 failed:

- xfail: static-sleepy-threads-cv-64
- xfail: static-gc-sleepy-threads-cv-64
- xfail: static-lto-sleepy-threads-cv-64
- xfail: static-gc-lto-sleepy-threads-cv-64
- xfail: static-lld-sleepy-threads-cv-64
- xfail: static-gc-lld-sleepy-threads-cv-64
- xfail: static-lto-lld-sleepy-threads-cv-64
- xfail: static-gc-lto-lld-sleepy-threads-cv-64
- xfail: static-sleepy-threads-cv-32
- xfail: static-gc-sleepy-threads-cv-32
- xfail: static-lto-sleepy-threads-cv-32
- xfail: static-gc-lto-sleepy-threads-cv-32
- xfail: static-lld-simple-hello-cout-one-32
- xfail: static-lld-simple-hello-cout-two-32
- xfail: static-lld-simple-exception-32
- xfail: static-lld-simple-str-exception-32
- xfail: static-lld-simple-int-exception-32
- xfail: static-lld-sleepy-threads-cv-32
- xfail: static-lld-hello2-cpp-32
- xfail: static-lld-exception-locale-32
- xfail: static-lld-cnrt-test-32
- xfail: static-lld-hello-weak2-cpp-32
- xfail: static-lld-overload-new-cpp-32
- xfail: static-gc-lld-simple-hello-cout-one-32
- xfail: static-gc-lld-simple-hello-cout-two-32
- xfail: static-gc-lld-simple-exception-32
- xfail: static-gc-lld-simple-str-exception-32
- xfail: static-gc-lld-simple-int-exception-32
- xfail: static-gc-lld-sleepy-threads-cv-32
- xfail: static-gc-lld-hello2-cpp-32
- xfail: static-gc-lld-exception-locale-32
- xfail: static-gc-lld-cnrt-test-32
- xfail: static-gc-lld-hello-weak2-cpp-32
- xfail: static-gc-lld-overload-new-cpp-32
- xfail: static-lto-lld-simple-hello-cout-one-32
- xfail: static-lto-lld-simple-hello-cout-two-32
- xfail: static-lto-lld-simple-exception-32
- xfail: static-lto-lld-simple-str-exception-32
- xfail: static-lto-lld-simple-int-exception-32
- xfail: static-lto-lld-sleepy-threads-cv-32
- xfail: static-lto-lld-hello2-cpp-32
- xfail: static-lto-lld-exception-locale-32
- xfail: static-lto-lld-cnrt-test-32
- xfail: static-lto-lld-hello-weak2-cpp-32
- xfail: static-lto-lld-overload-new-cpp-32
- xfail: static-gc-lto-lld-simple-hello-cout-one-32
- xfail: static-gc-lto-lld-simple-hello-cout-two-32
- xfail: static-gc-lto-lld-simple-exception-32
- xfail: static-gc-lto-lld-simple-str-exception-32
- xfail: static-gc-lto-lld-simple-int-exception-32
- xfail: static-gc-lto-lld-sleepy-threads-cv-32
- xfail: static-gc-lto-lld-hello2-cpp-32
- xfail: static-gc-lto-lld-exception-locale-32
- xfail: static-gc-lto-lld-cnrt-test-32
- xfail: static-gc-lto-lld-hello-weak2-cpp-32
- xfail: static-gc-lto-lld-overload-new-cpp-32

Verdict: tests reluctantly accepted
```

##### Build the Intel Windows binaries

Clean the build folder and prepare the docker container:

```sh
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json && \
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull && \
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git && \
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git && \
\
xpm run deep-clean --config win32-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-prepare --config win32-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-link-deps --config win32-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-build-develop --config win32-x64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

About 180 minutes later (3h00), the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xpack-dev-tools/clang-xpack.git/build/win32-x64/deploy
total 403676
-rw-r--r-- 1 ilg ilg 413355016 Apr  6 23:56 xpack-clang-18.1.7-1-win32-x64.zip
-rw-r--r-- 1 ilg ilg       101 Apr  6 23:56 xpack-clang-18.1.7-1-win32-x64.zip.sha
```

The tests report is:

```txt
Tests summary for clang 18.1.7-1 on win32-x64 (Ubuntu 18.04)

1532 test cases passed, 0 skipped
Verdict: tests accepted
```

#### Arm GNU/Linux 64-bit

Run the docker build on the production machine (`xbbla`);
start a VS Code remote session, or connect with a terminal:

```sh
caffeinate ssh xbbla
```

Update the build scripts (or clone them at the first use):

```sh
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json && \
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull && \
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git && \
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git && \
\
xpm run deep-clean --config linux-arm64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-prepare --config linux-arm64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-link-deps --config linux-arm64 -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-build-develop --config linux-arm64 -C ~/Work/xpack-dev-tools/clang-xpack.git
```

About 12h later (2h30 on ampere), the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm64/deploy
total 192976
-rw-r--r-- 1 ilg ilg 197597695 Jun 13 19:13 xpack-clang-18.1.7-1-linux-arm64.tar.gz
-rw-r--r-- 1 ilg ilg       106 Jun 13 19:13 xpack-clang-18.1.7-1-linux-arm64.tar.gz.sha
```

The tests report is:

```txt
Tests summary for clang 18.1.7-1 on linux-arm64 (Ubuntu 18.04)

1332 test cases passed, 0 skipped, 8 failed:

- xfail: static-sleepy-threads-cv
- xfail: static-gc-sleepy-threads-cv
- xfail: static-lto-sleepy-threads-cv
- xfail: static-gc-lto-sleepy-threads-cv
- xfail: static-lld-sleepy-threads-cv
- xfail: static-gc-lld-sleepy-threads-cv
- xfail: static-lto-lld-sleepy-threads-cv
- xfail: static-gc-lto-lld-sleepy-threads-cv

Verdict: tests reluctantly accepted
```

#### Arm GNU/Linux 32-bit

Run the docker build on the production machine (`xbbla32`);
start a VS Code remote session, or connect with a terminal:

```sh
caffeinate ssh xbbla32
```

Update the build scripts (or clone them at the first use):

```sh
rm -f ~/Work/xpack-dev-tools/clang-xpack.git/package-lock.json && \
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull && \
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git && \
git -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git pull && \
xpm link -C ~/Work/xpack-dev-tools/xbb-helper-xpack.git && \
xpm run link-deps -C ~/Work/xpack-dev-tools/clang-xpack.git && \
\
xpm run deep-clean --config linux-arm -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-prepare --config linux-arm -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-link-deps --config linux-arm -C ~/Work/xpack-dev-tools/clang-xpack.git && \
xpm run docker-build-develop --config linux-arm -C ~/Work/xpack-dev-tools/clang-xpack.git
```

About 10h30 later, the output of the build script is a compressed
archive and its SHA signature, created in the `deploy` folder:

```console
$ ls -l ~/Work/xpack-dev-tools/clang-xpack.git/build/linux-arm/deploy
total 174560
-rw-r--r-- 1 ilg ilg 178739683 Apr  7 07:24 xpack-clang-18.1.7-1-linux-arm.tar.gz
-rw-r--r-- 1 ilg ilg       104 Apr  7 07:24 xpack-clang-18.1.7-1-linux-arm.tar.gz.sha
```

The tests report is:

```txt
1246 test(s) passed, 130 failed:

fail: lto-adder-shared
fail: lto-simple-exception
fail: lto-sleepy-threads
fail: lto-hello-cpp
fail: lto-longjmp-cleanup
fail: lto-hello-weak-cpp
fail: lto-normal
fail: lto-weak-undef-c
fail: lto-weak-defined-c
fail: lto-weak-use-c
fail: lto-weak-override-c
fail: gc-lto-adder-shared
fail: gc-lto-simple-exception
fail: gc-lto-sleepy-threads
fail: gc-lto-hello-cpp
fail: gc-lto-longjmp-cleanup
fail: gc-lto-hello-weak-c
fail: gc-lto-hello-weak-cpp
fail: gc-lto-normal
fail: gc-lto-weak-undef-c
fail: gc-lto-weak-defined-c
fail: gc-lto-weak-use-c
fail: gc-lto-weak-override-c
fail: static-lib-lto-adder-shared
fail: static-lib-lto-simple-exception
fail: static-lib-lto-sleepy-threads
fail: static-lib-lto-longjmp-cleanup
fail: static-lib-lto-hello-weak-c
fail: static-lib-lto-normal
fail: static-lib-lto-weak-undef-c
fail: static-lib-lto-weak-defined-c
fail: static-lib-lto-weak-use-c
fail: static-lib-lto-weak-override-c
fail: static-lib-gc-lto-adder-shared
fail: static-lib-gc-lto-simple-exception
fail: static-lib-gc-lto-sleepy-threads
fail: static-lib-gc-lto-hello-cpp
fail: static-lib-gc-lto-longjmp-cleanup
fail: static-lib-gc-lto-hello-weak-c
fail: static-lib-gc-lto-hello-weak-cpp
fail: static-lib-gc-lto-normal
fail: static-lib-gc-lto-weak-undef-c
fail: static-lib-gc-lto-weak-defined-c
fail: static-lib-gc-lto-weak-use-c
fail: static-lib-gc-lto-weak-override-c
fail: static-sleepy-threads
fail: static-sleepy-threads-cv
fail: static-gc-sleepy-threads
fail: static-gc-sleepy-threads-cv
fail: static-lto-simple-exception
fail: static-lto-sleepy-threads
fail: static-lto-sleepy-threads-cv
fail: static-lto-longjmp-cleanup
fail: static-lto-exception-reduced
fail: static-lto-hello-weak-c
fail: static-lto-normal
fail: static-lto-weak-undef-c
fail: static-lto-weak-defined-c
fail: static-lto-weak-use-c
fail: static-lto-weak-override-c
fail: static-gc-lto-simple-exception
fail: static-gc-lto-simple-str-exception
fail: static-gc-lto-sleepy-threads
fail: static-gc-lto-sleepy-threads-cv
fail: static-gc-lto-hello-cpp
fail: static-gc-lto-longjmp-cleanup
fail: static-gc-lto-exception-reduced
fail: static-gc-lto-hello-weak-c
fail: static-gc-lto-normal
fail: static-gc-lto-weak-undef-c
fail: static-gc-lto-weak-defined-c
fail: static-gc-lto-weak-use-c
fail: static-gc-lto-weak-override-c
fail: static-lld-sleepy-threads
fail: static-lld-sleepy-threads-cv
fail: static-gc-lld-sleepy-threads
fail: static-gc-lld-sleepy-threads-cv
fail: static-lto-lld-sleepy-threads
fail: static-lto-lld-sleepy-threads-cv
fail: static-gc-lto-lld-sleepy-threads
fail: static-gc-lto-lld-sleepy-threads-cv
fail: crt-hello-exception
fail: crt-exception-locale
fail: crt-exception-reduced
fail: gc-crt-hello-exception
fail: gc-crt-exception-locale
fail: gc-crt-exception-reduced
fail: lto-crt-adder-shared
fail: lto-crt-simple-exception
fail: lto-crt-sleepy-threads
fail: lto-crt-hello-cpp
fail: lto-crt-longjmp-cleanup
fail: lto-crt-hello-exception
fail: lto-crt-exception-locale
fail: lto-crt-exception-reduced
fail: lto-crt-hello-weak-c
fail: lto-crt-normal
fail: lto-crt-weak-undef-c
fail: lto-crt-weak-defined-c
fail: lto-crt-weak-use-c
fail: lto-crt-weak-override-c
fail: lto-crt-weak-duplicate-c
fail: gc-lto-crt-adder-shared
fail: gc-lto-crt-simple-exception
fail: gc-lto-crt-sleepy-threads
fail: gc-lto-crt-hello-cpp
fail: gc-lto-crt-longjmp-cleanup
fail: gc-lto-crt-hello-exception
fail: gc-lto-crt-exception-locale
fail: gc-lto-crt-exception-reduced
fail: gc-lto-crt-hello-weak-c
fail: gc-lto-crt-hello-weak-cpp
fail: gc-lto-crt-normal
fail: gc-lto-crt-weak-undef-c
fail: gc-lto-crt-weak-defined-c
fail: gc-lto-crt-weak-use-c
fail: gc-lto-crt-weak-override-c
fail: gc-lto-crt-weak-duplicate-c
fail: crt-lld-hello-exception
fail: crt-lld-exception-locale
fail: crt-lld-exception-reduced
fail: gc-crt-lld-hello-exception
fail: gc-crt-lld-exception-locale
fail: gc-crt-lld-exception-reduced
fail: lto-crt-lld-hello-exception
fail: lto-crt-lld-exception-locale
fail: lto-crt-lld-exception-reduced
fail: gc-lto-crt-lld-hello-exception
fail: gc-lto-crt-lld-exception-locale
fail: gc-lto-crt-lld-exception-reduced
```

### Update README-MAINTAINER listing output

- check and possibly update the `ls -l` output in README-MAINTAINER

### Update the list of links in package.json

Copy/paste the full list of links displayed at the end of the build, in
sequence, for each platform (GNU/Linux, macOS, Windows), and check the
differences compared to the repository.

Commit if necessary.

### How to build a debug version

In some cases it is necessary to run a debug session in the binaries,
or even in the libraries functions.

For these cases, the build script accepts the `--debug` options.

There are also xPack actions that use this option (`build-develop-debug`
and `docker-build-develop-debug`).

### Files cache

The XBB build scripts use a local cache such that files are downloaded only
during the first run, later runs being able to use the cached files.

However, occasionally some servers may not be available, and the builds
may fail.

The workaround is to manually download the files from an alternate
location (like
<https://github.com/xpack-dev-tools/files-cache/tree/master/libs>),
place them in the XBB cache (`Work/cache`) and restart the build.

## Run the CI build

The automation is provided by GitHub Actions and three self-hosted runners.

### Generate the GitHub workflows

Run the `generate-workflows` to re-generate the
GitHub workflow files; commit and push if necessary.

### Start the self-hosted runners

- on the development machine (`wksi`) open ssh sessions to the build
machines (`xbbmi`, `xbbma`, `xbbli`, `xbbla` and `xbbla32`):

```sh
caffeinate ssh xbbmi
caffeinate ssh xbbma
caffeinate ssh xbbli
caffeinate ssh xbbla
caffeinate ssh xbbla32
```

For `xbbli` & `xbbla` start two runners:

```sh
screen -S ga

~/actions-runners/xpack-dev-tools/1/run.sh &
~/actions-runners/xpack-dev-tools/2/run.sh &

# Ctrl-a Ctrl-d
```

On all other machines start a single runner:

```sh
screen -S ga

~/actions-runners/xpack-dev-tools/run.sh &

# Ctrl-a Ctrl-d
```

### Push the build scripts

- push the `xpack-develop` branch to GitHub
- possibly push the helper project too

From here it'll be cloned on the production machines.

### Publish helper

Publish a new release of the helper and update the reference in `package.json`.

### Check for disk space

Check if the build machines have enough free space and eventually
do some cleanups (`df -BG -H /` on Linux, `df -gH /` on macOS).

To remove previous builds, use:

```sh
rm -rf ~/Work/xpack-dev-tools/*/build
```

### Manually trigger the build GitHub Actions

To trigger the GitHub Actions builds, use the xPack actions:

- `trigger-workflow-build-darwin-x64`
- `trigger-workflow-build-darwin-arm64`
- `trigger-workflow-build-linux-x64`
- `trigger-workflow-build-win32-x64`
- `trigger-workflow-build-linux-arm64`
- `trigger-workflow-build-linux-arm`

These are equivalent to:

```sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-build.sh --workflow build-darwin-x64.yml
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-build.sh --workflow build-darwin-arm64.yml
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-build.sh --workflow build-linux-x64.yml
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-build.sh --workflow build-win32-x64.yml
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-build.sh --workflow build-linux-arm64.yml
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-build.sh --workflow build-linux-arm.yml
```

These scripts require the `GITHUB_API_DISPATCH_TOKEN` variable to be present
in the environment, and the organization `PUBLISH_TOKEN` to be visible in the
Settings → Action →
[Secrets](https://github.com/xpack-dev-tools/clang-xpack/settings/secrets/actions)
page.

These commands use the `xpack-develop` branch of this repo.

## Durations & results

The builds take more than 11 hours to complete:

- `xbbmi`: 1h33 (nuc)
- `xbbma`: 0h38
- `xbbli`: 1h59 Linux, 2h48 Windows
- `xbbla`: 12h24
- `xbbla32`: 10h29

The workflow result and logs are available from the
[Actions](https://github.com/xpack-dev-tools/clang-xpack/actions/) page.

The resulting binaries are available for testing from
[pre-releases/test](https://github.com/xpack-dev-tools/pre-releases/releases/tag/test/).

## Testing

### CI tests

The automation is provided by GitHub Actions.

To trigger the GitHub Actions tests, use the xPack actions:

- `trigger-workflow-test-prime`
- `trigger-workflow-test-docker-linux-intel`
- `trigger-workflow-test-docker-linux-arm`

These are equivalent to:

```sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-test-prime.sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-test-docker-linux-intel.sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-test-docker-linux-arm.sh
```

These scripts require the `GITHUB_API_DISPATCH_TOKEN` variable to be present
in the environment.

These actions use the `xpack-develop` branch of this repo and the
[pre-releases/test](https://github.com/xpack-dev-tools/pre-releases/releases/tag/test/)
binaries.

The tests results are available from the
[Actions](https://github.com/xpack-dev-tools/clang-xpack/actions/) page.

Since GitHub Actions provides a single version of macOS, the
multi-version macOS tests run on Travis.

To trigger the Travis test, use the xPack action:

- `trigger-travis-macos`

This is equivalent to:

```sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-travis-macos.sh
```

This script requires the `TRAVIS_COM_TOKEN` variable to be present
in the environment.

The test results are available from
[Travis CI](https://app.travis-ci.com/github/xpack-dev-tools/clang-xpack/builds/).

### Manual tests

To download the pre-released archive for the specific platform
and run the tests, use:

```sh
git -C ~/Work/xpack-dev-tools/clang-xpack.git pull
xpm run install -C ~/Work/xpack-dev-tools/clang-xpack.git
xpm run test-pre-release -C ~/Work/xpack-dev-tools/clang-xpack.git
```

For even more tests, on each platform (MacOS, GNU/Linux, Windows),
download the archive from
[pre-releases/test](https://github.com/xpack-dev-tools/pre-releases/releases/tag/test/)
and check the binaries.

On macOS, remove the `com.apple.quarantine` flag:

```sh
xattr -cr ${HOME}/Downloads/xpack-*
```

On GNU/Linux and macOS systems, use:

```sh
.../xpack-clang-18.1.7-1/bin/clang --version
xPack x86_64 clang version 18.1.7
```

On Windows use:

```dos
...\xpack-clang-18.1.7-1\bin\clang --version
xPack x86_64 clang version 18.1.7
```

### Running the tests with the system clang

To calibrate the tests with the system compiler:

```
bash ~/Work/xpack-dev-tools/clang-xpack.git/scripts/test.sh --system
```

On Ubuntu, to install clang and libraries, use:

```sh
sudo apt-get install --yes clang lld libc++-dev libc++abi-dev
```

On Manjaro, install `clang lld libc++ libc++abi`.

On Linux x64, the 32-bit clang libraries are not available, skip the tests:

```sh
bash ~/Work/xpack-dev-tools/clang-xpack.git/scripts/test.sh --system --skip-32
```

## Create a new GitHub pre-release draft

- in `CHANGELOG.md`, add the release date and a message like _* v18.1.7-1 released_
- commit with _CHANGELOG update_
- check and possibly update the `templates/body-github-release-liquid.md`
- push the `xpack-develop` branch
- run the xPack action `trigger-workflow-publish-release`

The workflow result and logs are available from the
[Actions](https://github.com/xpack-dev-tools/clang-xpack/actions/) page.

The result is a
[draft pre-release](https://github.com/xpack-dev-tools/clang-xpack/releases/)
tagged like **v18.1.7-1** (mind the dash in the middle!) and
named like **xPack LLVM clang v18.1.7-1** (mind the dash),
with all binaries attached.

- edit the draft and attach it to the `xpack-develop` branch (important!)
- save the draft (do **not** publish yet!)

## Prepare a new blog post

- check and possibly update the `templates/body-jekyll-release-*-liquid.md`
 (for the release dates use <https://github.com/llvm/llvm-project/releases/>)
- run the xPack action `generate-jekyll-post`; this will leave a file
on the Desktop.

In the `xpack/web-jekyll` GitHub repo:

- select the `develop` branch
- copy the new file to `_posts/releases/clang`

If any, refer to closed
[issues](https://github.com/xpack-dev-tools/clang-xpack/issues/).

## Update the preview Web

- commit the `develop` branch of `xpack/web-jekyll` GitHub repo;
  use a message like _xPack LLVM clang v18.1.7-1 released_
- push to GitHub
- wait for the GitHub Pages build to complete
- the preview web is <https://xpack.github.io/web-preview/news/>

## Create the pre-release

- go to the GitHub [Releases](https://github.com/xpack-dev-tools/clang-xpack/releases/) page
- perform the final edits and check if everything is fine
- temporarily fill in the _Continue Reading »_ with the URL of the
  web-preview release
- **keep the pre-release button enabled**
- do not enable Discussions yet
- publish the release

Note: at this moment the system should send a notification to all clients
watching this project.

## Update the READMEs listings and examples

- check and possibly update the output of `tree -L 2` in README
- check and possibly update the output of the `--version` runs in README-MAINTAINER
- commit changes

## Check the list of links in package.json

- open the `package.json` file
- check if the links in the `bin` property cover the actual binaries
- if necessary, also check on Windows

## Update package.json binaries

- select the `xpack-develop` branch
- run the xPack action `update-package-binaries`
- open the `package.json` file
- check the `baseUrl:` it should match the file URLs (including the tag/version);
  no terminating `/` is required
- from the release, check the SHA & file names
- compare the SHA sums with those shown by `cat *.sha`
- check the executable names
- commit all changes, use a message like
  _package.json: update urls for 18.1.7-1.1 release_ (without _v_)

## Publish on the npmjs.com server

- select the `xpack-develop` branch
- check the latest commits `npm run git-log`
- update `CHANGELOG.md`, add a line like _* v18.1.7-1.1 published on npmjs.com_
- commit with a message like _CHANGELOG: publish npm v18.1.7-1.1_
- `npm pack` and check the content of the archive, which should list
  only the `package.json`, the `README.md`, `LICENSE` and `CHANGELOG.md`;
  possibly adjust `.npmignore`
- `npm version 18.1.7-1.1`; the first 4 numbers are the same as the
  GitHub release; the fifth number is the npm specific version
- the commits and the tag should have been pushed by the `postversion` script;
  if not, push them with `git push origin --tags`
- `npm publish --tag next` (use `npm publish --access public`
  when publishing for the first time; add the `next` tag)

After a few moments the version will be visible at:

- <https://www.npmjs.com/package/@xpack-dev-tools/clang?activeTab=versions>

## Test if the binaries can be installed with xpm

Run the xPack action `trigger-workflow-test-xpm`, this
will install the package via `xpm install` on all supported platforms.

The tests results are available from the
[Actions](https://github.com/xpack-dev-tools/clang-xpack/actions/) page.

The Windows tests take more than 20 minutes to complete.

## Prepare the test results page

Download the `tests-report` artefact, unpack it and copy
the `18.1.7-1.md` file to the web site `pages/dev-tools/clang/tests` folder.

Generating the tests results for a specific version can be done with the
command:

```bash
bash ~/Work/xpack-dev-tools/clang-xpack.git/xpacks/@xpack-dev-tools/xbb-helper/github-actions/trigger-workflow-test-xpm.sh --package-version 18.1.7-1.1
```

## Update the repo

- merge `xpack-develop` into `xpack`
- push to GitHub

## Tag the npm package as `latest`

When the release is considered stable, promote it as `latest`:

- `npm dist-tag ls @xpack-dev-tools/clang`
- `npm dist-tag add @xpack-dev-tools/clang@18.1.7-1.1 latest`
- `npm dist-tag ls @xpack-dev-tools/clang`

In case the previous version is not functional and needs to be unpublished:

- `npm unpublish @xpack-dev-tools/clang@18.1.7-1.1`

## Update the Web

- in the `master` branch, merge the `develop` branch
- wait for the GitHub Pages build to complete
- the result is in <https://xpack.github.io/news/>
- remember the post URL, since it must be updated in the release page

## Create the final GitHub release

- go to the GitHub [Releases](https://github.com/xpack-dev-tools/clang-xpack/releases/) page
- check the download counter, it should match the number of tests
- add a link to the Web page `[Continue reading »]()`; use an same blog URL
- remove the _tests only_ notice
- **disable** the **pre-release** button
- click the **Update Release** button

## Share on Twitter

- in a separate browser windows, open [X/Twitter](https://twitter.com)
- using the `@xpack_project` account
- paste the release name like **xPack LLVM clang v18.1.7-1 released**
- paste the link to the Web page
  [release](https://xpack.github.io/clang/releases/)
- click the **Tweet** button

## Check SourceForge mirror

- <https://sourceforge.net/projects/clang-xpack/files/>

## Remove the pre-release binaries

- go to <https://github.com/xpack-dev-tools/pre-releases/releases/tag/test/>
- remove the test binaries

## Clean the work area

Run the xPack action `trigger-workflow-deep-clean`, this
will remove the build folders on all supported platforms.

The results are available from the
[Actions](https://github.com/xpack-dev-tools/clang-xpack/actions/) page.
