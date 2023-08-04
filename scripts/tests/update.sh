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
  if [[ ${image_name} == github-actions-ubuntu* ]]
  then
    run_verbose sudo apt-get update
    # To make 32-bit tests possible.
    run_verbose sudo apt-get -qq install --yes g++-multilib
  elif [[ ${image_name} == *ubuntu* ]] || [[ ${image_name} == *debian* ]]
  then
    run_verbose apt-get -qq install --yes g++
    if [ "$(uname -m)" == "x86_64" ]
    then
      run_verbose apt-get -qq install --yes g++-multilib
    fi
  elif [[ ${image_name} == *raspbian* ]]
  then
    run_verbose apt-get -qq install --yes g++
  elif [[ ${image_name} == *centos* ]] || [[ ${image_name} == *redhat* ]] || [[ ${image_name} == *fedora* ]]
  then
    run_verbose yum install --assumeyes --quiet gcc-c++ glibc glibc-common libstdc++ libatomic
    if [ "$(uname -m)" == "x86_64" ]
    then
      run_verbose yum install --assumeyes --quiet libgcc*i686 libstdc++*i686 glibc*i686 libatomic*i686 # libgfortran*i686
    fi
  elif [[ ${image_name} == *suse* ]]
  then
    run_verbose zypper --quiet --no-gpg-checks install --no-confirm gcc-c++ glibc
    if [ "$(uname -m)" == "x86_64" ]
    then
      run_verbose zypper --quiet --no-gpg-checks install --no-confirm gcc-32bit
    fi
  elif [[ ${image_name} == *manjaro* ]]
  then
    run_verbose pacman -S --quiet --noconfirm --noprogressbar gcc
    if [ "$(uname -m)" == "x86_64" ]
    then
      run_verbose pacman -S --quiet --noconfirm --noprogressbar lib32-gcc-libs
    fi
  elif [[ ${image_name} == *archlinux* ]]
  then
    run_verbose pacman -S --quiet --noconfirm --noprogressbar gcc
    if [ "$(uname -m)" == "x86_64" ]
    then
      run_verbose pacman -S --quiet --noconfirm --noprogressbar lib32-gcc-libs
    fi
  fi

  echo
  echo "The system C/C++ libraries..."
  find /usr/lib* /lib -name 'libc.*' -o -name 'libstdc++.*' -o -name 'libgcc_s.*'
}

# -----------------------------------------------------------------------------
