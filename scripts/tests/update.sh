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

  export XBB_SKIP_32_BIT_TESTS="y"

  # Make sure that the minimum prerequisites are met.
  if [[ ${image_name} == github-actions-ubuntu* ]]
  then
    :
  elif [[ ${image_name} == *ubuntu* ]] || [[ ${image_name} == *debian* ]]
  then
    run_verbose apt-get -qq install --yes g++
  elif [[ ${image_name} == *raspbian* ]]
  then
    run_verbose apt-get -qq install --yes g++
  elif [[ ${image_name} == *centos* ]] || [[ ${image_name} == *redhat* ]] || [[ ${image_name} == *fedora* ]]
  then
    run_verbose yum install --assumeyes --quiet gcc-c++ glibc glibc-common libstdc++
  elif [[ ${image_name} == *suse* ]]
  then
    run_verbose zypper --quiet --no-gpg-checks install --no-confirm gcc-c++ glibc
  elif [[ ${image_name} == *manjaro* ]]
  then
    run_verbose pacman -S --quiet --noconfirm --noprogressbar gcc
  elif [[ ${image_name} == *archlinux* ]]
  then
    run_verbose pacman -S --quiet --noconfirm --noprogressbar gcc
  fi
}

# -----------------------------------------------------------------------------
