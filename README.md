
[![GitHub package.json version](https://img.shields.io/github/package-json/v/xpack-dev-tools/clang-xpack)](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/package.json)
[![GitHub release (latest by date)](https://img.shields.io/github/v/release/xpack-dev-tools/clang-xpack)](https://github.com/xpack-dev-tools/clang-xpack/releases/)
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/clang.svg?color=blue)](https://www.npmjs.com/package/@xpack-dev-tools/clang/)
[![license](https://img.shields.io/github/license/xpack-dev-tools/clang-xpack)](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/LICENSE)

# The xPack LLVM clang

A standalone cross-platform (Windows/macOS/Linux) **LLVM clang**
binary distribution, intended for reproducible builds.

In addition to the the binary archives and the package meta data,
this project also includes the build scripts.

## Overview

This open source project is hosted on GitHub as
[`xpack-dev-tools/clang-xpack`](https://github.com/xpack-dev-tools/clang-xpack)
and provides the platform specific binaries for the
[xPack LLVM clang](https://xpack.github.io/clang/);
it includes, in addition to project metadata, the full build scripts.

This distribution follows the official [LLVM clang](https://clang.llvm.org).

The binaries can be installed automatically as **binary xPacks** or manually as
**portable archives**.

## Release schedule

This distribution follows the official
[LLVM clang](https://github.com/llvm/llvm-project/releases/) releases,
but only the final patch of each version is released (like 15.0.7).

## User info

This section is intended as a shortcut for those who plan
to use the LLVM clang binaries. For full details please read the
[xPack LLVM clang](https://xpack.github.io/clang/) pages.

### Supported languages

The xPack LLVM clang binaries include support for C/C++ and the LLVM utilities.

### Easy install

The easiest way to install LLVM clang is using the **binary xPack**, available as
[`@xpack-dev-tools/clang`](https://www.npmjs.com/package/@xpack-dev-tools/clang)
from the [`npmjs.com`](https://www.npmjs.com) registry.

#### Prerequisites

A recent [xpm](https://xpack.github.io/xpm/),
which is a portable [Node.js](https://nodejs.org/) command line application
that complements [npm](https://docs.npmjs.com)
with several extra features specific to
**C/C++ projects**.

It is recommended to install/update to the latest version with:

```sh
npm install --location=global xpm@latest
```

For details please follow the instructions in the
[xPack install](https://xpack.github.io/install/) page.

#### Install

With the `xpm` tool available, installing
the latest version of the package and adding it as
a development dependency for a project is quite easy:

```sh
cd my-project
xpm init # Add a package.json if not already present

xpm install @xpack-dev-tools/clang@latest --verbose

ls -l xpacks/.bin
```

This command will:

- install the latest available version,
into the central xPacks store, if not already there
- add symbolic links (`.cmd` forwarders on Windows) into
the local `xpacks/.bin` folder to the central store

The central xPacks store is a platform dependent
location in the home folder;
check the output of the `xpm` command for the actual
folder used on your platform.
This location is configurable via the environment variable
`XPACKS_STORE_FOLDER`; for more details please check the
[xpm folders](https://xpack.github.io/xpm/folders/) page.

It is also possible to install LLVM clang globally, in the user home folder:

```sh
xpm install --global @xpack-dev-tools/clang@latest --verbose
```

After install, the package should create a structure like this (macOS files;
only the first two depth levels are shown):

```console
$ tree -L 2 /Users/ilg/Library/xPacks/\@xpack-dev-tools/clang/15.0.7-3.1/.content/
/Users/ilg/Library/xPacks/@xpack-dev-tools/clang/15.0.7-3.1/.content/
├── README.md
├── bin
│   ├── UnicodeNameMappingGenerator
│   ├── analyze-build
│   ├── clang -> clang-15
│   ├── clang++ -> clang
│   ├── clang-15
│   ├── clang-check
│   ├── clang-cl -> clang
│   ├── clang-cpp -> clang
│   ├── clang-doc
│   ├── clang-format
│   ├── clang-linker-wrapper
│   ├── clang-nvlink-wrapper
│   ├── clang-offload-bundler
│   ├── clang-offload-packager
│   ├── clang-offload-wrapper
│   ├── clang-pseudo
│   ├── clang-refactor
│   ├── clang-rename
│   ├── clang-repl
│   ├── clang-scan-deps
│   ├── clang-tidy
│   ├── clangd
│   ├── clangd-xpc-test-client
│   ├── darwin-debug
│   ├── diagtool
│   ├── git-clang-format
│   ├── hmaptool
│   ├── intercept-build
│   ├── ld.lld -> lld
│   ├── ld64.lld -> lld
│   ├── lld
│   ├── lld-link -> lld
│   ├── lldb
│   ├── lldb-argdumper
│   ├── lldb-instr
│   ├── lldb-server
│   ├── lldb-vscode
│   ├── llvm-addr2line -> llvm-symbolizer
│   ├── llvm-ar
│   ├── llvm-as
│   ├── llvm-bitcode-strip -> llvm-objcopy
│   ├── llvm-config
│   ├── llvm-cov
│   ├── llvm-cxxdump
│   ├── llvm-cxxfilt
│   ├── llvm-cxxmap
│   ├── llvm-debuginfod
│   ├── llvm-debuginfod-find
│   ├── llvm-diff
│   ├── llvm-dis
│   ├── llvm-dlltool -> llvm-ar
│   ├── llvm-dwarfutil
│   ├── llvm-lib -> llvm-ar
│   ├── llvm-libtool-darwin
│   ├── llvm-nm
│   ├── llvm-objcopy
│   ├── llvm-objdump
│   ├── llvm-otool -> llvm-objdump
│   ├── llvm-profdata
│   ├── llvm-ranlib -> llvm-ar
│   ├── llvm-rc
│   ├── llvm-readelf -> llvm-readobj
│   ├── llvm-readobj
│   ├── llvm-remark-size-diff
│   ├── llvm-sim
│   ├── llvm-size
│   ├── llvm-strings
│   ├── llvm-strip -> llvm-objcopy
│   ├── llvm-symbolizer
│   ├── llvm-tapi-diff
│   ├── llvm-tblgen
│   ├── llvm-tli-checker
│   ├── llvm-windres -> llvm-rc
│   ├── run-clang-tidy
│   ├── scan-build-py
│   ├── set-xcode-analyzer
│   ├── split-file
│   └── wasm-ld -> lld
├── distro-info
│   ├── CHANGELOG.md
│   ├── licenses
│   ├── patches
│   └── scripts
├── include
├── lib
│   ├── LLVMPolly.so
│   ├── clang
│   ├── cmake
│   ├── libLLVM.dylib
│   ├── libLTO.dylib
│   ├── libRemarks.dylib
│   ├── libclang-cpp.dylib
│   ├── libclang.dylib
│   ├── libear
│   ├── liblldb.15.0.6.dylib
│   ├── liblldb.dylib -> liblldb.15.0.6.dylib
│   └── libscanbuild
├── libexec
│   ├── analyze-c++
│   ├── analyze-cc
│   ├── c++-analyzer
│   ├── ccc-analyzer
│   ├── intercept-c++
│   ├── intercept-cc
│   ├── libedit.0.dylib
│   ├── libffi.8.dylib
│   ├── libform.6.dylib
│   ├── libiconv.2.dylib
│   ├── liblzma.5.dylib
│   ├── libncurses.6.dylib
│   ├── libpanel.6.dylib
│   ├── libxml2.2.dylib
│   ├── libz.1.2.13.dylib
│   └── libz.1.dylib -> libz.1.2.13.dylib
└── share
    ├── clang
    ├── opt-viewer
    ├── scan-build
    └── scan-view

17 directories, 104 files
```

No other files are installed in any system folders or other locations.

#### Uninstall

To remove the links created by xpm in the current project:

```sh
cd my-project

xpm uninstall @xpack-dev-tools/clang
```

To completely remove the package from the central xPack store:

```sh
xpm uninstall --global @xpack-dev-tools/clang
```

### Manual install

For all platforms, the **xPack LLVM clang**
binaries are released as portable
archives that can be installed in any location.

The archives can be downloaded from the
GitHub [Releases](https://github.com/xpack-dev-tools/clang-xpack/releases/)
page.

For more details please read the
[Install](https://xpack.github.io/clang/install/) page.

### Versioning

The version strings used by the LLVM project are three number strings
like `15.0.7`; to this string the xPack distribution adds a four number,
but since semver allows only three numbers, all additional ones can
be added only as pre-release strings, separated by a dash,
like `15.0.7-3`. When published as a npm package, the version gets
a fifth number, like `15.0.7-3.1`.

Since adherence of third party packages to semver is not guaranteed,
it is recommended to use semver expressions like `^15.0.7` and `~15.0.7`
with caution, and prefer exact matches, like `15.0.7-3.1`.

## Maintainer info

For maintainer info, please see the
[README-MAINTAINER](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/README-MAINTAINER.md).

## Support

The quick advice for getting support is to use the GitHub
[Discussions](https://github.com/xpack-dev-tools/clang-xpack/discussions/).

For more details please read the
[Support](https://xpack.github.io/clang/support/) page.

## License

Unless otherwise stated, the content is released under the terms of the
[MIT License](https://opensource.org/licenses/mit/),
with all rights reserved to
[Liviu Ionescu](https://github.com/ilg-ul).

The binary distributions include several open-source components; the
corresponding licenses are available in the installed
`distro-info/licenses` folder.

## Download analytics

- GitHub [`xpack-dev-tools/clang-xpack`](https://github.com/xpack-dev-tools/clang-xpack/) repo
  - latest xPack release
[![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/clang-xpack/latest/total.svg)](https://github.com/xpack-dev-tools/clang-xpack/releases/)
  - all xPack releases [![Github All Releases](https://img.shields.io/github/downloads/xpack-dev-tools/clang-xpack/total.svg)](https://github.com/xpack-dev-tools/clang-xpack/releases/)
  - [individual file counters](https://somsubhra.github.io/github-release-stats/?username=xpack-dev-tools&repository=clang-xpack) (grouped per release)
- npmjs.com [`@xpack-dev-tools/clang`](https://www.npmjs.com/package/@xpack-dev-tools/clang/) xPack
  - latest release, per month
[![npm (scoped)](https://img.shields.io/npm/v/@xpack-dev-tools/clang.svg)](https://www.npmjs.com/package/@xpack-dev-tools/clang/)
[![npm](https://img.shields.io/npm/dm/@xpack-dev-tools/clang.svg)](https://www.npmjs.com/package/@xpack-dev-tools/clang/)
  - all releases [![npm](https://img.shields.io/npm/dt/@xpack-dev-tools/clang.svg)](https://www.npmjs.com/package/@xpack-dev-tools/clang/)

Credit to [Shields IO](https://shields.io) for the badges and to
[Somsubhra/github-release-stats](https://github.com/Somsubhra/github-release-stats)
for the individual file counters.
