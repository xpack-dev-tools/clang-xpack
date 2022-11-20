# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function build_binutils_ld_gold()
{
  # https://www.gnu.org/software/binutils/
  # https://ftp.gnu.org/gnu/binutils/

  # https://archlinuxarm.org/packages/aarch64/binutils/files/PKGBUILD
  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=gdb-git

  # https://aur.archlinux.org/cgit/aur.git/tree/PKGBUILD?h=mingw-w64-binutils
  # https://github.com/msys2/MINGW-packages/blob/master/mingw-w64-binutils/PKGBUILD


  # 2017-07-24, "2.29"
  # 2018-01-28, "2.30"
  # 2018-07-18, "2.31.1"
  # 2019-02-02, "2.32"
  # 2019-10-12, "2.33.1"
  # 2020-02-01, "2.34"
  # 2020-07-24, "2.35"
  # 2020-09-19, "2.35.1"
  # 2021-01-24, "2.36"
  # 2021-01-30, "2.35.2"
  # 2021-02-06, "2.36.1"
  # 2021-07-18, "2.37"
  # 2022-02-09, "2.38"
  # 2022-08-05, "2.39"

  local binutils_version="$1"

  local binutils_src_folder_name="binutils-${binutils_version}"

  local binutils_archive="${binutils_src_folder_name}.tar.xz"
  local binutils_url="https://ftp.gnu.org/gnu/binutils/${binutils_archive}"

  local binutils_folder_name="binutils-ld.gold-${binutils_version}"

  mkdir -pv "${XBB_LOGS_FOLDER_PATH}/${binutils_folder_name}"

  local binutils_patch_file_name="binutils-${binutils_version}.patch"
  local binutils_stamp_file_path="${XBB_STAMPS_FOLDER_PATH}/stamp-${binutils_folder_name}-installed"
  if [ ! -f "${binutils_stamp_file_path}" ]
  then

    mkdir -pv "${XBB_SOURCES_FOLDER_PATH}"
    cd "${XBB_SOURCES_FOLDER_PATH}"

    download_and_extract "${binutils_url}" "${binutils_archive}" \
      "${binutils_src_folder_name}" "${binutils_patch_file_name}"

    (
      mkdir -p "${XBB_BUILD_FOLDER_PATH}/${binutils_folder_name}"
      cd "${XBB_BUILD_FOLDER_PATH}/${binutils_folder_name}"

      xbb_activate_dependencies_dev

      CPPFLAGS="${XBB_CPPFLAGS}"
      CFLAGS="${XBB_CFLAGS_NO_W}"
      CXXFLAGS="${XBB_CXXFLAGS_NO_W}"

      # LDFLAGS="${XBB_LDFLAGS_APP_STATIC_GCC}"
      LDFLAGS="${XBB_LDFLAGS_APP}"
      xbb_adjust_ldflags_rpath

      if [ "${XBB_HOST_PLATFORM}" == "win32" ]
      then
        if [ "${TARGET_ARCH}" == "x32" -o "${TARGET_ARCH}" == "ia32" ]
        then
          # From MSYS2 MINGW
          LDFLAGS+=" -Wl,--large-address-aware"
        fi

        # Used to enable wildcard; inspired from arm-none-eabi-gcc.
        LDFLAGS+=" -Wl,${XBB_FOLDER_PATH}/usr/${XBB_TARGET_TRIPLET}/lib/CRT_glob.o"
      fi

      export CPPFLAGS
      export CFLAGS
      export CXXFLAGS
      export LDFLAGS

      if [ ! -f "config.status" ]
      then
        (
          xbb_show_env_develop

          echo
          echo "Running binutils-ld.gold configure..."

          bash "${XBB_SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/configure" --help
          bash "${XBB_SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/ld/configure" --help

          # ? --without-python --without-curses, --with-expat
          config_options=()

          config_options+=("--prefix=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")

          config_options+=("--infodir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/info")
          config_options+=("--mandir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/man")
          config_options+=("--htmldir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/html")
          config_options+=("--pdfdir=${XBB_LIBRARIES_INSTALL_FOLDER_PATH}/share/pdf")

          config_options+=("--build=${XBB_BUILD_TRIPLET}")
          config_options+=("--host=${XBB_HOST_TRIPLET}")
          config_options+=("--target=${XBB_TARGET_TRIPLET}")

          config_options+=("--program-suffix=")
          config_options+=("--with-pkgversion=${XBB_BINUTILS_BRANDING}")

          # config_options+=("--with-lib-path=/usr/lib:/usr/local/lib")
          config_options+=("--with-sysroot=${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}")

          config_options+=("--without-system-zlib")
          config_options+=("--with-pic")

          if [ "${XBB_HOST_PLATFORM}" == "win32" ]
          then

            config_options+=("--enable-ld")

            if [ "${TARGET_ARCH}" == "x64" ]
            then
              # From MSYS2 MINGW
              config_options+=("--enable-64-bit-bfd")
            fi

            config_options+=("--enable-shared")
            config_options+=("--enable-shared-libgcc")

          elif [ "${XBB_HOST_PLATFORM}" == "linux" ]
          then

            config_options+=("--enable-ld")

            config_options+=("--disable-shared")
            config_options+=("--disable-shared-libgcc")

          else
            echo "Unsupported ${XBB_HOST_PLATFORM} in ${FUNCNAME[0]}()"
            exit 1
          fi

          config_options+=("--enable-static")

          config_options+=("--enable-gold")
          config_options+=("--enable-lto")
          config_options+=("--enable-libssp")
          config_options+=("--enable-relro")
          config_options+=("--enable-threads")
          config_options+=("--enable-interwork")
          config_options+=("--enable-plugins")
          config_options+=("--enable-build-warnings=no")
          config_options+=("--enable-deterministic-archives")

          # TODO
          # config_options+=("--enable-nls")
          config_options+=("--disable-nls")

          config_options+=("--disable-werror")
          config_options+=("--disable-sim")
          config_options+=("--disable-gdb")

          run_verbose bash ${DEBUG} "${XBB_SOURCES_FOLDER_PATH}/${binutils_src_folder_name}/configure" \
            "${config_options[@]}"

          cp "config.log" "${XBB_LOGS_FOLDER_PATH}/${binutils_folder_name}/config-log-$(ndate).txt"
        ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${binutils_folder_name}/configure-output-$(ndate).txt"
      fi

      (
        echo
        echo "Running binutils-ld.gold make..."

        # Build.
        run_verbose make -j ${XBB_JOBS} all-gold

        if [ "${XBB_WITH_TESTS}" == "y" ]
        then
          # gcctestdir/collect-ld: relocation error: gcctestdir/collect-ld: symbol _ZNSt7__cxx1112basic_stringIcSt11char_traitsIcESaIcEE9_M_createERmm, version GLIBCXX_3.4.21 not defined in file libstdc++.so.6 with link time reference
          : # make maybe-check-gold
        fi

        # Avoid strip here, it may interfere with patchelf.
        # make install-strip
        run_verbose make maybe-install-gold

        # Remove the separate folder, the xPack distribution is single target.
        rm -rf "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/${XBB_BUILD_TRIPLET}"

        if [ "${XBB_HOST_PLATFORM}" == "darwin" ]
        then
          : # rm -rv "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/strip"
        fi

        show_libs "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin/ld.gold"

      ) 2>&1 | tee "${XBB_LOGS_FOLDER_PATH}/${binutils_folder_name}/make-output-$(ndate).txt"

      copy_license \
        "${XBB_SOURCES_FOLDER_PATH}/${binutils_src_folder_name}" \
        "${binutils_folder_name}"

    )

    mkdir -pv "${XBB_STAMPS_FOLDER_PATH}"
    touch "${binutils_stamp_file_path}"

  else
    echo "Component binutils ld.gold already installed."
  fi

  tests_add "test_binutils_ld_gold" "${XBB_EXECUTABLES_INSTALL_FOLDER_PATH}/bin"
}

function test_binutils_ld_gold()
{
  local test_bin_path="$1"

  show_libs "${test_bin_path}/ld.gold"

  echo
  echo "Testing if binutils ld.gold starts properly..."

  run_app "${test_bin_path}/ld.gold" --version

  echo
  echo "Local binutils ld.gold tests completed successfuly."
}

# -----------------------------------------------------------------------------
