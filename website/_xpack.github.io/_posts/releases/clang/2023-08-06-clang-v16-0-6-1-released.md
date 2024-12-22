---

title:  xPack LLVM clang v16.0.6-1 released

summary: "Version **16.0.6-1** is a new release; it follows the upstream release."

clang_version: "16.0.6"
clang_date: "14 June 2023"

version: "16.0.6-1"
npm_subversion: "1"

download_url: https://github.com/xpack-dev-tools/clang-xpack/releases/tag/v16.0.6-1/

comments: true

date: 2023-08-06 09:25:40 +0300

redirect_to: https://xpack-dev-tools.github.io/clang-xpack/blog/2023/08/06/clang-v16-0-6-1-released/

categories:
  - releases
  - clang

tags:
  - releases
  - clang

---

The [xPack LLVM clang](https://xpack.github.io/clang/)
is a standalone cross-platform binary distribution of
[LLVM clang](https://clang.llvm.org).

There are separate binaries for **Windows** (x64),
**macOS** (x64, arm64)
and **GNU/Linux** (x64, arm64 and arm).

{% include note.html content="The main targets for the GNU/Linux Arm
binaries are the **Raspberry Pi** class devices (armv7l and aarch64;
armv6 is not supported)." %}

## Download

The binary files are available from [GitHub Releases]({{ page.download_url }}).

## Prerequisites

- x64 GNU/Linux: any system with **GLIBC 2.27** or higher
  (like Ubuntu 18 or later, Debian 10 or later, RedHat 8 or later,
  Fedora 29 or later, etc)
- arm64/arm GNU/Linux: any system with **GLIBC 2.27** or higher
  (like Raspberry Pi OS, Ubuntu 18 or later, Debian 10 or later, RedHat 8 or later,
  Fedora 29 or later, etc)
- x64 Windows: Windows 7 with the Universal C Runtime
  ([UCRT](https://support.microsoft.com/en-us/topic/update-for-universal-c-runtime-in-windows-c0514201-7fe6-95a3-b0a5-287930f3560c)),
  Windows 8, Windows 10
- x64 macOS: 10.13 or later
- arm64 macOS: 11.6 or later

## Install

The full details of installing the **xPack LLVM clang** on various platforms
are presented in the separate [Install]({{ site.baseurl }}/dev-tools/clang/install/) page.

### Easy install

The easiest way to install LLVM clang is with
[`xpm`]({{ site.baseurl }}/xpm/)
by using the **binary xPack**, available as
[`@xpack-dev-tools/clang`](https://www.npmjs.com/package/@xpack-dev-tools/clang)
from the [`npmjs.com`](https://www.npmjs.com) registry.

With the `xpm` tool available, installing
the latest version of the package and adding it as
a development dependency for a project is quite easy:

```sh
cd my-project
xpm init # Add a package.json if not already present

xpm install @xpack-dev-tools/clang@latest --verbose

ls -l xpacks/.bin
```

To install this specific version, use:

```sh
xpm install @xpack-dev-tools/clang@{{ page.version }}.{{ page.npm_subversion }} --verbose
```

It is also possible to install LLVM clang globally, in the user home folder,
but this requires xPack aware tools to automatically identify them and
manage paths.

```sh
xpm install --global @xpack-dev-tools/clang@latest --verbose
```

### Uninstall

To remove the links created by xpm in the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/clang
```

To completely remove the package from the central xPack store:

```sh
xpm uninstall --global @xpack-dev-tools/clang
```

## Compliance

The xPack LLVM clang generally follows the official
[LLVM clang](https://clang.llvm.org) releases.

The current version is based on:

- LLVM clang version [{{ page.clang_version }}](https://releases.llvm.org/download.html#{{ page.clang_version }}), from {{ page.clang_date }}.

For x64 GNU/Linux and Windows, multilib (32/64-bit) libraries are provided.

## LLVM libraries

On macOS and Windows the compiler defaults are set to the LLVM libraries
(`libc++` and `compiler-rt`).

For historical reasons, on GNU/Linux, the defaults are set to the host
system (`libstdc++` and `glibc`).

To use the LLVM libraries, add the following options:

```sh
-stdlib=libc++ -rtlib=compiler-rt -lunwind
```

For LTO builds, also use LLD:

```sh
-flto -fuse-ld=lld
```

## `-m32` / `-m64`

For x64 GNU/Linux and Windows, multilib libraries are provided
and can be selected using the `-m32` / `-m64` options.

## `-print-search-dirs`

Since the toolchain can be installed in any location, and the binaries
compiled with it need to access the libraries, it is necessary to
get the actual path and pass it via `LD_LIBRARY_PATH` and/or
set the `-rpath`.

This can be achieved by querying the compiler
for `-print-search-dirs` and processing the output.

For example, for the 32-bit libraries:

```sh
${CXX} -m32 -print-search-dirs | grep 'libraries: =' | sed -e 's|libraries: =||'
```

On Windows the DLLs are usually in `bin`, but for consistency within GCC,
they are also copied to `lib`; it is recommended to ask the compiler for
the actual path.

For example, for the 32-bit libraries:

```sh
${CXX} -m32 -print-file-name=libc++.dll
```

## Changes

Compared to the upstream, there are no major functional changes.

Since 15.0.7-4, there is a small patch in Driver.cpp that fixes the
function that computes
`InstalledDir` when clang is invoked via a link from a different folder.

## Bug fixes

- none

## Enhancements

- none

## Known problems

Please see the separate
[tests results page]({{ site.baseurl }}/dev-tools/clang/tests/16.0.6-1/).

## Shared libraries

On all platforms the packages are standalone, and expect only the standard
runtime to be present on the host.

All dependencies that are build as shared libraries are copied locally
in the `libexec` folder (or in the same folder as the executable for Windows).

### `DT_RPATH` and `LD_LIBRARY_PATH`

On GNU/Linux the binaries are adjusted to use a relative path:

```console
$ readelf -d library.so | grep runpath
 0x000000000000001d (RPATH)            Library rpath: [$ORIGIN]
```

In the GNU ld.so search strategy, the `DT_RPATH` has
the highest priority, higher than `LD_LIBRARY_PATH`, so if this later one
is set in the environment, it should not interfere with the xPack binaries.

Please note that previous versions, up to mid-2020, used `DT_RUNPATH`, which
has a priority lower than `LD_LIBRARY_PATH`, and does not tolerate setting
it in the environment.

### `@rpath` and `@loader_path`

Similarly, on macOS, the binaries are adjusted with `install_name_tool` to use a
relative path.

## Documentation

The original documentation is available
[online](https://clang.llvm.org/docs/UsersManual.html).

## Build

The binaries for all supported platforms
(Windows, macOS and GNU/Linux) were built using the
[xPack Build Box (XBB)](https://xpack.github.io/xbb/), a set
of build environments based on slightly older distributions, that should be
compatible with most recent systems.

For the prerequisites and more details on the build procedure, please see the
[How to build](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/README-BUILD.md) page.

## CI tests

Before publishing, a set of simple tests were performed on an exhaustive
set of platforms. The results are available from:

- [GitHub Actions](https://github.com/xpack-dev-tools/clang-xpack/actions/)
- [Travis CI](https://app.travis-ci.com/github/xpack-dev-tools/clang-xpack/builds/)

## Tests

The binaries were tested on a variety of platforms,
but mainly to check the integrity of the
build, not the compiler functionality.

## Checksums

The SHA-256 hashes for the files are:

```txt
f908977be0c0ec4e2f8e35990eb318696c9e48dc78aff5e5186f2f4e628f5016
xpack-clang-16.0.6-1-darwin-arm64.tar.gz

a5c3b686685e7e0afe0eff4700c3d3c393664c51dd47b4863ebc1d5b470bd037
xpack-clang-16.0.6-1-darwin-x64.tar.gz

0b8923ede765cd3a06f44296eef8ce55d60158589d23f94f6d4892dfe94fab8b
xpack-clang-16.0.6-1-linux-arm.tar.gz

96dcb8b239cde59d0f2e95e071e9f6117de81da589695d8a35ae674761205d4b
xpack-clang-16.0.6-1-linux-arm64.tar.gz

7a58706d004fa4f4e94005d9c87f1d311b46709cc3766c85a6b98a2bfd0ae15b
xpack-clang-16.0.6-1-linux-x64.tar.gz

5356509c1958a801686971ee1a833f60e107ca639bfa61c1a3a1bc656bdd5c0e
xpack-clang-16.0.6-1-win32-x64.zip

```

## Deprecation notices

### 32-bit support

Support for 32-bit x86 GNU/Linux and x86 Windows was
dropped in 2022. Support for 32-bit Arm GNU/Linux (armv7l) will be preserved
for a while, due to the large user base of 32-bit Raspberry Pi systems.

### GNU/Linux minimum requirements

Support for RedHat 7 was dropped in 2022 and the
minimum requirement was raised to GLIBC 2.27, available starting
with Ubuntu 18, Debian 10 and RedHat 8.

## Pre-deprecation notice for Ubuntu 18.04

Ubuntu 18.04 LTS _Bionic Beaver_ reached the end of the standard five-year
maintenance window for Long-Term Support (LTS) release on 31 May 2023.

As a courtesy, the xPack GNU/Linux releases will continue to be based on
Ubuntu 18.04 for another year.

From 2025 onwards, the GNU/Linux binaries will be built on **Debian 10**,
(**GLIBC 2.28**), and are also expected to run on RedHat 8.

Users are urged to update their build and test infrastructure to
ensure a smooth transition to the next xPack releases.

## Download analytics

- GitHub [xpack-dev-tools/clang-xpack](https://github.com/xpack-dev-tools/clang-xpack/)
  - this release [![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/clang-xpack/v{{ page.version }}/total.svg)](https://github.com/xpack-dev-tools/clang-xpack/releases/v{{ page.version }}/)
  - all xPack releases [![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/clang-xpack/total.svg)](https://github.com/xpack-dev-tools/clang-xpack/releases/)
  - [individual file counters](https://somsubhra.github.io/github-release-stats/?username=xpack-dev-tools&repository=clang-xpack) (grouped per release)
- npmjs.com [@xpack-dev-tools/clang](https://www.npmjs.com/package/@xpack-dev-tools/clang)
  - latest releases [![npm](https://img.shields.io/npm/dw/@xpack-dev-tools/clang.svg)](https://www.npmjs.com/package/@xpack-dev-tools/clang/)
  - all @xpack-dev-tools releases [![npm](https://img.shields.io/npm/dt/@xpack-dev-tools/clang.svg)](https://www.npmjs.com/package/@xpack-dev-tools/clang/)

Credit to [Shields IO](https://shields.io) for the badges and to
[Somsubhra/github-release-stats](https://github.com/Somsubhra/github-release-stats)
for the individual file counters.
