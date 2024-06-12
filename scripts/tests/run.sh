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

  # Call the functions defined in the build code.
  llvm_test "${test_bin_path}"

  if [ "${XBB_HOST_PLATFORM}" == "linux" ] && [ "${XBB_TEST_SYSTEM_TOOLS}" != "y" ]
  then
    binutils_test_ld_gold "${test_bin_path}"
  fi
}

# -----------------------------------------------------------------------------
