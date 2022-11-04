# -----------------------------------------------------------------------------
# This file is part of the xPack distribution.
#   (https://xpack.github.io)
# Copyright (c) 2020 Liviu Ionescu.
#
# Permission to use, copy, modify, and/or distribute this software
# for any purpose is hereby granted, under the terms of the MIT license.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------

function tests_update_system()
{
  local image_name="$1"

  # Make sure that the minimum prerequisites are met.
  # The GCC libraries and headers are required by clang.
  if [[ ${image_name} == github-actions-ubuntu* ]]
  then
    : # sudo apt-get -qq install -y XXX
  elif [[ ${image_name} == *ubuntu* ]] || [[ ${image_name} == *debian* ]] || [[ ${image_name} == *raspbian* ]]
  then
    run_verbose apt-get -qq install -y g++ libc6-dev libstdc++6
  elif [[ ${image_name} == *centos* ]] || [[ ${image_name} == *redhat* ]] || [[ ${image_name} == *fedora* ]]
  then
    run_verbose yum install -y -q gcc-c++ glibc-devel libstdc++-devel
  elif [[ ${image_name} == *suse* ]]
  then
    run_verbose zypper -q --no-gpg-checks in -y gcc-c++ glibc-devel libstdc++6 glibc-static
  elif [[ ${image_name} == *manjaro* ]]
  then
    run_verbose pacman -S -q --noconfirm --noprogressbar gcc gcc-libs
  elif [[ ${image_name} == *archlinux* ]]
  then
    run_verbose pacman -S -q --noconfirm --noprogressbar gcc gcc-libs
  fi

  echo
  echo "The system C/C++ libraries..."
  find /usr/lib* /lib -name 'libc.*' -o -name 'libstdc++.*' -o -name 'libgcc_s.*' -o -name 'libunwind*'
}

# -----------------------------------------------------------------------------
