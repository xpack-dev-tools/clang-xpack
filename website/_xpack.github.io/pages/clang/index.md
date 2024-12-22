---

title: The LLVM clang
permalink: /dev-tools/clang/

summary: "A binary distribution of the LLVM clang."
keywords:
  - LLVM
  - clang
  - c++

comments: true

date: 2021-05-22 00:27:00 +0300

redirect_to: https://xpack-dev-tools.github.io/clang-xpack/

---

## Quicklinks

If you already know the general facts about the xPack LLVM clang, you can
directly skip to the desired pages.

User pages:

- [install]({{ site.baseurl }}/clang/install/)
- [support]({{ site.baseurl }}/clang/support/)
- [releases]({{ site.baseurl }}/clang/releases/)

Developer & maintainer pages:

- [GitHub](https://github.com/xpack-dev-tools/clang-xpack/)
- [README-MAINTAINER](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/README-MAINTAINER.md)

## Overview

The **xPack LLVM clang**
is an cross-platform standalone binary distribution of the
[LLVM clang](https://clang.llvm.org).

## Benefits

The main advantages of using the **xPack LLVM clang** are:

- a convenient, uniform and portable install/uninstall/upgrade procedure,
  the same procedure is used for all major
  platforms (Intel Windows 64-bit, Intel GNU/Linux 64-bit, Arm GNU/Linux
  64/32-bit, Intel macOS 64-bit, Apple Silicon macOS 64-bit)
- a convenient integration with Continuous Integration environments,
  like GitHub Actions
- a better integration with development environments
  like **Eclipse Embedded CDT**.

All binaries are self-contained, they include all required libraries,
and can be installed in any location.

## Compatibility

The **xPack LLVM clang** is fully compatible with the
original LLVM releases.

## Install

The details of installing the **xPack LLVM clang** on various
platforms are presented in the separate
[install]({{ site.baseurl }}/clang/install/) page.

## Documentation

To save space and bandwidth, the original documentation is available
[online](https://clang.llvm.org/docs/UsersManual.html).

## Predefined macros

The list of build-in macros is available in a
[separate page]({{ site.baseurl }}/clang/predefined-macros/).

## Support

For the various support options, please read the separate
[support]({{ site.baseurl }}/clang/support/) page.

## Change log

The release and change log is available in the repository
[`CHANGELOG.md`](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/CHANGELOG.md) file.

## Build details

For those interested in building the binaries, please read the
[README-MAINTAINER](https://github.com/xpack-dev-tools/clang-xpack/blob/xpack/README-MAINTAINER.md)
page.
However, the ultimate source for details are the build scripts themselves,
all available from the
[`clang-xpack.git/scripts`](https://github.com/xpack-dev-tools/clang-xpack/tree/xpack/scripts/)
folder.

## Releases

See the [releases]({{ site.baseurl }}/clang/releases/) pages.

## Tests reports

- [16.0.6-1]({{ site.baseurl }}/clang/tests/16.0.6-1/)
- [17.0.6-2]({{ site.baseurl }}/clang/tests/17.0.6-2/)
- [17.0.6-3]({{ site.baseurl }}/clang/tests/17.0.6-3/)
- [18.1.8-1]({{ site.baseurl }}/clang/tests/18.1.8-1/)
