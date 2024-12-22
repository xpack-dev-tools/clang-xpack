---

title: How to install the xPack LLVM clang binaries
permalink: /dev-tools/clang/install/

summary: "The recommended method is via xpm."

version: "13.0.1"
xpack-subversion: "1"
version-major: "13"

comments: true
toc: false

date: 2021-05-22 00:27:00 +0300

redirect_to: https://xpack-dev-tools.github.io/clang-xpack/docs/install/

---

## Overview

The **xPack LLVM clang** can be installed automatically,
via `xpm` (the recommended method), or manually,
by downloading and unpacking one of the portable archives.

{% capture easy_install %}

## Easy install

The easiest way to install the xPack LLVM clang is by using the
**binary xPack**, available as
[`@xpack-dev-tools/clang`](https://www.npmjs.com/package/@xpack-dev-tools/clang)
from the [`npmjs.com`](https://www.npmjs.com) registry.

### Prerequisites

The only requirement is a recent
`xpm`, which is a portable
[Node.js](https://nodejs.org) command line application. To install it,
follow the instructions from the
[xpm install]({{ site.baseurl }}/xpm/install/) page.

### Install

With xpm available, installing
the latest version of the package is quite easy:

```sh
cd my-project
xpm init # Only at first use.

xpm install @xpack-dev-tools/clang@latest --verbose
```

This command will always install the latest available version,
in the global xPacks store, which is a platform dependent folder
(check the output of the `xpm` command for the actual folder used on
your platform).

{% capture include_1 %}
The install location can be configured using the
`XPACKS_STORE_FOLDER` environment variable; for more details please check the
[xpm folders]({{ site.baseurl }}/xpm/folders/) page.
{% endcapture %}

{% include tip.html content=include_1 %}

{% include tip.html content="The archive content is unpacked into a folder
named `.content`. On some platforms
this might be hidden for normal browsing, and require
separate options (like `ls -A`) or, in file browsers, to enable
settings like **Show Hidden Files**." %}

### Update

For the moment, to update the package, try to install the latest release again,
as shown before. If there is a new release, it will be installed,
otherwise a message will warn that the package is already installed.

Future versions of xpm will implement the `outdated` and `update` commands,
as npm does.

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

{% endcapture %}

{% capture manual_install %}

## Manual install

For all platforms, the **xPack LLVM clang** binaries are
released as portable
archives that can be installed in any location.

The archives can be downloaded from the
GitHub [releases](https://github.com/xpack-dev-tools/clang-xpack/releases/) pages.
{% endcapture %}

{% capture windows %}

{{ easy_install }}

### Test

To check if the xpm installed GCC starts, use something like:

```doscon
C:\>%USERPROFILE%\AppData\Roaming\xPacks\@xpack-dev-tool\clang\{{ page.version }}-{{ page.xpack-subversion }}.1\.content\bin\clang.exe" --version
xPack MinGW-w64 x86_64 clang version {{ page.version }}
Target: x86_64-w64-windows-gnu
Thread model: posix
```

{{ manual_install }}

### Download

The Windows versions of **xPack LLVM clang**
are packed as ZIP files.
Download the latest version named like:

- `xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-win32-x64.zip`

{% include note.html content="In case you wonder where the suffix comes
from, it is exactly the Node.js `process.platform` and `process.arch`.
The `win32` part is confusing, but we have to live with it." %}

### Unpack

To manually install the xPack LLVM clang,
unpack the archive and copy the versioned folder into the
`%USERPROFILE%\AppData\Roaming\xPacks\clang`
(for example `C:\Users\ilg\AppData\Roaming\xPacks\clang`) folder;
according to Microsoft, `AppData\Roaming` is the recommended location for
installing user specific packages.

You may shorten the last folder name and keep only the version.

{% include note.html content="For manual installs, the recommended
install location is slightly different from the xpm install folders,
which use the scope (like `@xpack-dev-tools`) to group different tools,
and `.content` to store the unpacked archive." %}

### Test

To check if the manually installed GCC starts, use something like:

```doscon
C:\>%USERPROFILE%\AppData\Roaming\xPacks\clang\xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}\bin\clang.exe" --version
xPack MinGW-w64 x86_64 clang version {{ page.version }}
Target: x86_64-w64-windows-gnu
Thread model: posix
```

{% endcapture %}

{% capture macos %}

{{ easy_install }}

### Test

To check if the xpm installed GCC starts, use something like:

```console
$ ~/Library/xPacks/@xpack-dev-tools/clang/{{ page.version }}-{{ page.xpack-subversion }}.1/.content/bin/clang --version
xPack x86_64 clang version {{ page.version }}
Target: x86_64-apple-darwin21.5.0
Thread model: posix
```

{{ manual_install }}

### Download

The macOS versions of **xPack LLVM clang** are packed as a
`.tar.gz` archive.
Download the latest version named like:

- `xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-darwin-x64.tar.gz`
- `xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-darwin-arm64.tar.gz`

### Unpack

To manually install the xPack LLVM clang,
unpack the archive and copy it to
`~/.local/xPacks/clang/xpack-clang-<version>`:

```sh
mkdir -p ~/.local/xPacks/clang
cd ~/.local/xPacks/clang

tar xvf ~/Downloads/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-darwin-x64.tar.gz
chmod -R -w xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}
```

You may shorten the last folder name and keep only the version.

{% include note.html content="For manual installs, the recommended
install location is different from the xpm install folders." %}

The result is a structure like:

```console
$ tree -L 2 /Users/ilg/.local/xPacks/clang/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}
/Users/ilg/.local/xPacks/clang/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}
├── README.md
├── bin
│   ├── analyze-build
│   ├── clang -> clang-{{ page.version-major }}
│   ├── clang++ -> clang
│   ├── clang-{{ page.version-major }}
│   ├── clang-check
│   ├── clang-cl -> clang
│   ├── clang-cpp -> clang
│   ├── clang-doc
│   ├── clang-format
│   ├── clang-offload-bundler
│   ├── clang-offload-wrapper
│   ├── clang-refactor
│   ├── clang-rename
│   ├── clang-repl
│   ├── clang-scan-deps
│   ├── clang-tidy
│   ├── clangd
│   ├── clangd-xpc-test-client
│   ├── darwin-debug
│   ├── diagtool
│   ├── git-clang-format
│   ├── hmaptool
│   ├── intercept-build
│   ├── ld.lld -> lld
│   ├── ld64.lld -> lld
│   ├── ld64.lld.darwinnew -> lld
│   ├── ld64.lld.darwinold -> lld
│   ├── lld
│   ├── lld-link -> lld
│   ├── lldb
│   ├── lldb-argdumper
│   ├── lldb-instr
│   ├── lldb-server
│   ├── lldb-vscode
│   ├── llvm-addr2line -> llvm-symbolizer
│   ├── llvm-ar
│   ├── llvm-as
│   ├── llvm-bitcode-strip -> llvm-objcopy
│   ├── llvm-config
│   ├── llvm-cov
│   ├── llvm-cxxdump
│   ├── llvm-cxxfilt
│   ├── llvm-cxxmap
│   ├── llvm-diff
│   ├── llvm-dis
│   ├── llvm-dlltool -> llvm-ar
│   ├── llvm-lib -> llvm-ar
│   ├── llvm-libtool-darwin
│   ├── llvm-nm
│   ├── llvm-objcopy
│   ├── llvm-objdump
│   ├── llvm-otool -> llvm-objdump
│   ├── llvm-profdata
│   ├── llvm-ranlib -> llvm-ar
│   ├── llvm-rc
│   ├── llvm-readelf -> llvm-readobj
│   ├── llvm-readobj
│   ├── llvm-sim
│   ├── llvm-size
│   ├── llvm-strings
│   ├── llvm-strip -> llvm-objcopy
│   ├── llvm-symbolizer
│   ├── llvm-tapi-diff
│   ├── llvm-tblgen
│   ├── llvm-windres -> llvm-rc
│   ├── run-clang-tidy
│   ├── scan-build-py
│   ├── set-xcode-analyzer
│   ├── split-file
│   └── wasm-ld -> lld
├── distro-info
│   ├── CHANGELOG.md
│   ├── licenses
│   ├── patches
│   └── scripts
├── include
├── lib
│   ├── LLVMPolly.so
│   ├── clang
│   ├── cmake
│   ├── libLLVM.dylib
│   ├── libLTO.dylib
│   ├── libRemarks.dylib
│   ├── libclang-cpp.dylib
│   ├── libclang.dylib
│   ├── libear
│   ├── liblldb.{{ page.version }}.dylib
│   ├── liblldb.dylib -> liblldb.{{ page.version }}.dylib
│   └── libscanbuild
├── libexec
│   ├── analyze-c++
│   ├── analyze-cc
│   ├── c++-analyzer
│   ├── ccc-analyzer
│   ├── intercept-c++
│   ├── intercept-cc
│   ├── libLLVM.dylib
│   ├── libclang-cpp.dylib
│   ├── libedit.0.dylib
│   ├── libffi.8.dylib
│   ├── libform.6.dylib
│   ├── libgcc_s.1.dylib
│   ├── libiconv.2.dylib
│   ├── liblldb.{{ page.version }}.dylib
│   ├── liblzma.5.dylib
│   ├── libncurses.6.dylib
│   ├── libpanel.6.dylib
│   ├── libxml2.2.dylib
│   ├── libz.1.2.11.dylib
│   └── libz.1.dylib -> libz.1.2.11.dylib
└── share
    ├── clang
    ├── opt-viewer
    ├── scan-build
    └── scan-view

17 directories, 100 files
```

### Test

To check if the manually installed GCC starts, use something like:

```console
$ ~/.local/xPacks/clang/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}.1/bin/clang --version
xPack x86_64 clang version {{ page.version }}
Target: x86_64-apple-darwin21.5.0
Thread model: posix
```

{% endcapture %}

{% capture linux %}

{{ easy_install }}

### Test

To check if the xpm installed GCC starts, use something like:

```console
$ ~/.local/xPacks/@xpack-dev-tools/clang/{{ page.version }}-{{ page.xpack-subversion }}.1/.content/bin/clang --version
xPack x86_64 clang version {{ page.version }}
Target: x86_64-pc-linux-gnu
Thread model: posix
```

{{ manual_install }}

### Download

The GNU/Linux versions of **xPack LLVM clang**
are packed as `.tar.gz` archives.
Download the latest version named like:

- `xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-linux-x64.tar.gz`
- `xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-linux-arm.tar.gz`
- `xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-linux-arm64.tar.gz`

As the name implies, these are GNU/Linux `tar.gz` archives; they were build on
Ubuntu, but can be executed on most recent GNU/Linux distributions.

### Unpack

To manually install the xPack LLVM clang,
unpack the archive and copy it to
`${HOME}/.local/xPacks/clang/xpack-clang-<version>`:

```sh
mkdir -p ~/.local/xPacks/clang
cd ~/.local/xPacks/clang

tar xvf ~/Downloads/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}-linux-x64.tar.gz
chmod -R -w xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}
```

You may shorten the last folder name and keep only the version.

{% include note.html content="For manual installs, the recommended
install location is slightly different from the xpm install folders,
which use the scope (like `@xpack-dev-tools`) to group different tools,
and `.content` to store the unpacked archive." %}

The result is a structure like:

```console
$ tree -L 2 /home/ilg/.local/xPacks/clang/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}
/home/ilg/.local/xPacks/clang/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}
├── bin
│   ├── analyze-build
│   ├── clang -> clang-{{ page.version-major }}
│   ├── clang++ -> clang
│   ├── clang-{{ page.version-major }}
│   ├── clang-check
│   ├── clang-cl -> clang
│   ├── clang-cpp -> clang
│   ├── clangd
│   ├── clang-doc
│   ├── clang-format
│   ├── clang-offload-bundler
│   ├── clang-offload-wrapper
│   ├── clang-refactor
│   ├── clang-rename
│   ├── clang-repl
│   ├── clang-scan-deps
│   ├── clang-tidy
│   ├── diagtool
│   ├── dwp
│   ├── git-clang-format
│   ├── hmaptool
│   ├── intercept-build
│   ├── ld64.lld -> lld
│   ├── ld64.lld.darwinnew -> lld
│   ├── ld64.lld.darwinold -> lld
│   ├── ld.gold
│   ├── ld.lld -> lld
│   ├── lld
│   ├── lldb
│   ├── lldb-argdumper
│   ├── lldb-instr
│   ├── lldb-server
│   ├── lldb-vscode
│   ├── lld-link -> lld
│   ├── llvm-addr2line -> llvm-symbolizer
│   ├── llvm-ar
│   ├── llvm-as
│   ├── llvm-bitcode-strip -> llvm-objcopy
│   ├── llvm-config
│   ├── llvm-cov
│   ├── llvm-cxxdump
│   ├── llvm-cxxfilt
│   ├── llvm-cxxmap
│   ├── llvm-diff
│   ├── llvm-dis
│   ├── llvm-dlltool -> llvm-ar
│   ├── llvm-lib -> llvm-ar
│   ├── llvm-libtool-darwin
│   ├── llvm-nm
│   ├── llvm-objcopy
│   ├── llvm-objdump
│   ├── llvm-otool -> llvm-objdump
│   ├── llvm-profdata
│   ├── llvm-ranlib -> llvm-ar
│   ├── llvm-rc
│   ├── llvm-readelf -> llvm-readobj
│   ├── llvm-readobj
│   ├── llvm-sim
│   ├── llvm-size
│   ├── llvm-strings
│   ├── llvm-strip -> llvm-objcopy
│   ├── llvm-symbolizer
│   ├── llvm-tapi-diff
│   ├── llvm-tblgen
│   ├── llvm-windres -> llvm-rc
│   ├── run-clang-tidy
│   ├── scan-build-py
│   ├── split-file
│   └── wasm-ld -> lld
├── distro-info
│   ├── CHANGELOG.md
│   ├── licenses
│   ├── patches
│   └── scripts
├── include
│   └── c++
├── lib
│   ├── clang
│   ├── cmake
│   ├── libc++.a
│   ├── libc++abi.a
│   ├── libc++abi.so -> libc++abi.so.1
│   ├── libc++abi.so.1 -> libc++abi.so.1.0
│   ├── libc++abi.so.1.0
│   ├── libc++experimental.a
│   ├── libclang-cpp.so -> libclang-cpp.so.{{ page.version-major }}
│   ├── libclang-cpp.so.{{ page.version-major }}
│   ├── libclang.so -> libclang.so.{{ page.version-major }}
│   ├── libclang.so.{{ page.version-major }} -> libclang.so.{{ page.version }}
│   ├── libclang.so.{{ page.version }}
│   ├── libc++.so
│   ├── libc++.so.1 -> libc++.so.1.0
│   ├── libc++.so.1.0
│   ├── libear
│   ├── liblldbIntelFeatures.so -> liblldbIntelFeatures.so.{{ page.version-major }}
│   ├── liblldbIntelFeatures.so.{{ page.version-major }}
│   ├── liblldb.so -> liblldb.so.{{ page.version-major }}
│   ├── liblldb.so.{{ page.version-major }} -> liblldb.so.{{ page.version }}
│   ├── liblldb.so.{{ page.version }}
│   ├── libLLVM-{{ page.version }}.so -> libLLVM-{{ page.version-major }}.so
│   ├── libLLVM-{{ page.version-major }}.so
│   ├── libLLVM.so -> libLLVM-{{ page.version-major }}.so
│   ├── libLTO.so -> libLTO.so.{{ page.version-major }}
│   ├── libLTO.so.{{ page.version-major }}
│   ├── libRemarks.so -> libRemarks.so.{{ page.version-major }}
│   ├── libRemarks.so.{{ page.version-major }}
│   ├── libscanbuild
│   ├── libunwind.a
│   ├── libunwind.so -> libunwind.so.1
│   ├── libunwind.so.1 -> libunwind.so.1.0
│   ├── libunwind.so.1.0
│   ├── LLVMgold.so
│   └── LLVMPolly.so
├── libexec
│   ├── analyze-c++
│   ├── analyze-cc
│   ├── c++-analyzer
│   ├── ccc-analyzer
│   ├── intercept-c++
│   ├── intercept-cc
│   ├── libatomic.so.1 -> libatomic.so.1.2.0
│   ├── libatomic.so.1.2.0
│   ├── libedit.so.0 -> libedit.so.0.0.68
│   ├── libedit.so.0.0.68
│   ├── libffi.so.8 -> libffi.so.8.1.0
│   ├── libffi.so.8.1.0
│   ├── libform.so.6 -> libform.so.6.3
│   ├── libform.so.6.3
│   ├── libgcc_s.so.1
│   ├── libiconv.so.2 -> libiconv.so.2.6.1
│   ├── libiconv.so.2.6.1
│   ├── liblzma.so.5 -> liblzma.so.5.2.5
│   ├── liblzma.so.5.2.5
│   ├── libncurses.so.6 -> libncurses.so.6.3
│   ├── libncurses.so.6.3
│   ├── libpanel.so.6 -> libpanel.so.6.3
│   ├── libpanel.so.6.3
│   ├── libstdc++.so.6 -> libstdc++.so.6.0.29
│   ├── libstdc++.so.6.0.29
│   ├── libxml2.so.2 -> libxml2.so.2.9.11
│   ├── libxml2.so.2.9.11
│   ├── libz.so.1 -> libz.so.1.2.11
│   └── libz.so.1.2.11
├── README.md
└── share
    ├── clang
    ├── opt-viewer
    ├── scan-build
    └── scan-view

18 directories, 132 files
```

### Test

To check if the manually installed GCC starts, use something like:

```console
$ ~/.local/xPacks/clang/xpack-clang-{{ page.version }}-{{ page.xpack-subversion }}/bin/clang --version
xPack x86_64 clang version {{ page.version }}
Target: x86_64-pc-linux-gnu
Thread model: posix
```

{% endcapture %}

{% include platform-tabs.html %}

{% include warning.html content="**DO NOT** add the path to
the user or system path!" %}
