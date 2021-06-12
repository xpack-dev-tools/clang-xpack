# Scripts to test the xPack clang

The binaries can be available from one of the pre-releases:

<https://github.com/xpack-dev-tools/pre-releases/releases>

## Download the repo

The test script is part of the GCC xPack:

```sh
rm -rf ~/Downloads/clang-xpack.git; \
git clone \
  --recurse-submodules \
  --branch xpack-develop \
  https://github.com/xpack-dev-tools/clang-xpack.git  \
  ~/Downloads/clang-xpack.git
```

## Start a local test

To check if GCC starts on the current platform, run a native test:

```sh
rm -rf ~/Work/cache/xpack-clang-*

bash ~/Downloads/clang-xpack.git/tests/scripts/native-test.sh \
  "https://github.com/xpack-dev-tools/pre-releases/releases/download/test/"
```

The script stores the downloaded archive in a local cache, and
does not download it again if available locally.

The initial remove is to force a new download.

## Start the Travis test

The multi-platform test runs on Travis CI; it is configured to not fire on
git actions, but only via a manual POST to the Travis API.

```sh
bash ~/Downloads/clang-xpack.git/tests/scripts/travis-trigger.sh
```

For convenience, on macOS this can be invoked from Finder, using
the `travis-trigger.mac.command` shortcut.
