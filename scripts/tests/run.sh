# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function tests_run_all()
{
  local test_bin_path="$1"

  # GCC_VERSION="$(echo "${XBB_RELEASE_VERSION}" | sed -e 's|-.*||')"

  # Call the functions defined in the build code.
  test_llvm "${test_bin_path}"

  if [ "${XBB_TARGET_PLATFORM}" == "linux" ]
  then
    test_binutils_ld_gold "${test_bin_path}"
  fi
}

# -----------------------------------------------------------------------------
