---

title:  xPack LLVM clang v12.0.1-1 released
sidebar: clang

summary: "Version **12.0.1-1** is the first release of the **xPack LLVM clang** package."

version: 12.0.1-1
npm_subversion: 2

download_url: https://github.com/xpack-dev-tools/clang-xpack/releases/tag/v12.0.1-1/

date: 2021-10-22 00:51:58 +0300

redirect_from:
  - /blog/2021/10/22/clang-v12-0-1-1-released/

redirect_to: https://xpack-dev-tools.github.io/clang-xpack/blog/2021/10/21/clang-v12-0-1-1-released/

comments: true

categories:
  - releases
  - clang

tags:
  - releases
  - clang

---

The [xPack LLVM clang](https://xpack.github.io/dev-tools/clang/)
is a standalone cross-platform binary distribution of
[LLVM clang](https://clang.llvm.org).

There are separate binaries for **Windows** (x64 and x86),
**macOS** (x64) and **GNU/Linux** (x64 and x86, arm64 and arm).

{% include note.html content="The main targets for the GNU/Linux Arm
binaries are the **Raspberry Pi** class devices (armv7l and aarch64;
armv6 is not supported)." %}

## Download

The binary files are available from [GitHub Releases]({{ page.download_url }}).

## Prerequisites

- x86/x64 GNU/Linux: any system with **GLIBC 2.15** or higher
  (like Ubuntu 12 or later, Debian 8 or later, RedHat/CentOS 7 later,
  Fedora 20 or later, etc)
- arm64/arm GNU/Linux: any system with **GLIBC 2.23** or higher
  (like Ubuntu 16 or later, Debian 9 or later, RedHat/CentOS 8 or later,
  Fedora 24 or later, etc)
- x86/x64 Windows: Windows 7 with the Universal C Runtime
  ([UCRT](https://support.microsoft.com/en-us/topic/update-for-universal-c-runtime-in-windows-c0514201-7fe6-95a3-b0a5-287930f3560c)),
  Windows 8, Windows 10
- x64 macOS: 10.13 or later

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
a dependency for a project is quite easy:

```sh
cd my-project
xpm init # Only at first use.

xpm install @xpack-dev-tools/clang@latest

ls -l xpacks/.bin
```

To install this specific version, use:

```sh
xpm install @xpack-dev-tools/clang@{{ page.version }}.{{ page.npm_subversion }}
```

It is also possible to install LLVM clang globally, in the user home folder,
but this requires xPack aware tools to automatically identify them and
manage paths.

```sh
xpm install --global @xpack-dev-tools/clang@latest --verbose
```

### Uninstall

To remove the links from the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/clang
```

To completely remove the package from the central xPacks store:

```sh
xpm uninstall --global @xpack-dev-tools/clang
```

## Compliance

The xPack LLVM clang generally follows the official
[LLVM clang](https://clang.llvm.org) releases.

The current version is based on:

- LLVM clang version [12.0.1](https://releases.llvm.org/download.html#12.0.1), from July 8th, 2021.

## Changes

Compared to the upstream, there are no functional changes.

## Bug fixes

- none

## Enhancements

- none

## Known problems

- on macOS, the `/Library/Developer/CommandLineTools/usr/include/c++/v1`
  was added to the include path; unfortunately this may crash some builds;
  removed in 15.0.7-3
- when clang is invoked via a link from a different folder, the `InstalledDir`
  does not reflect the correct install folder, and the new clang system headers
  are either not found or the host system headers are used; fixed in 15.0.7-4

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

### `@executable_path`

Similarly, on macOS, the binaries are adjusted with `otool` to use a
relative path.

## Documentation

To save space and bandwidth, the original documentation is available
[online](https://clang.llvm.org/docs/UsersManual.html).

## Build

The binaries for all supported platforms
(Windows, macOS and GNU/Linux) were built using the
[xPack Build Box (XBB)](https://xpack.github.io/xbb/), a set
of build environments based on slightly older distributions, that should be
compatible with most recent systems.

The scripts used to build this distribution are in:

- `distro-info/scripts`

For the prerequisites and more details on the build procedure, please see the
[README-MAINTAINER](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/README-MAINTAINER.md) page.

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
c89264fcb7045421f897c3beb1d70b510aab2ee33d9a9d123a18b73e3f8b72c3
xpack-clang-12.0.1-1-darwin-x64.tar.gz

3844fb7a70d519722b07bba4c4846ffa7cba8f3b19440746c2db1145b31e7993
xpack-clang-12.0.1-1-linux-arm.tar.gz

a5005d804700cf02f88d37bd53cff72ed788487326538f80a35c314fa11d5919
xpack-clang-12.0.1-1-linux-arm64.tar.gz

5945a56690f9c2d39f822305a3d2f01429d6a7bc4e745a722bdfaad2623e3022
xpack-clang-12.0.1-1-linux-ia32.tar.gz

2645701c746a8ba49ddf6b3223acae99bef449ffb23b2a71f8b1364e61ab710c
xpack-clang-12.0.1-1-linux-x64.tar.gz

82d42ea1d81462bdda1f36b8bb0dc4f00d31764ea559c112b6d5d8d226c03762
xpack-clang-12.0.1-1-win32-ia32.zip

a6417c60ae33b41844ed84185f017c056a4c35116e8c87566222f56b024035e3
xpack-clang-12.0.1-1-win32-x64.zip

```

## Deprecation notices

### 32-bit support

Support for 32-bit x86 GNU/Linux and x86 Windows will most probably
be dropped in 2022. Support for 32-bit Arm GNU/Linux will be preserved
for a while, due to the large user base of 32-bit Raspberry Pi systems.

### GNU/Linux minimum requirements

Support for RedHat 7 will most probably be dropped in 2022, and the
minimum requirement will be raised to GLIBC 2.27, available starting
with Ubuntu 18 and RedHat 8.

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
