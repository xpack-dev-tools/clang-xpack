# -----------------------------------------------------------------------------
#
# This file is part of the xPack project (http://xpack.github.io).
# Copyright (c) 2020-2026 Liviu Ionescu. All rights reserved.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
#
# If a copy of the license was not distributed with this file, it can
# be obtained from https://opensource.org/licenses/mit.
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function tests_run_all()
{
  echo
  echo "[${FUNCNAME[0]} $@]"

  local test_bin_path="$1"

  # Call the functions defined in the build code.
  llvm_test "${test_bin_path}"

  # if [ "${XBB_HOST_PLATFORM}" == "linux" ] && [ "${XBB_TEST_SYSTEM_TOOLS}" != "y" ]
  # then
  #   binutils_test_ld_gold "${test_bin_path}"
  # fi
}

# -----------------------------------------------------------------------------
