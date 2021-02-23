#!/usr/bin/env bash
# plugin version 5.0

# shellcheck disable=SC1091
. /etc/rc.subr && load_rc_config
: "${plugin_enable_pkglist:="NO"}"

install_pkglist() {
  ## If enabled, re-install packages from a pkglist, after a Plugin UPDATE
  ## Use `sysrc plugin_pkglist="/path/to/pkglist"` to set a pkglist
  ## Use `sysrc plugin_enable_pkglist=YES` to enable
  local pkgs ; pkgs=$(cat "${plugin_pkglist:-/dev/null}")
  echo -e "\nChecking for additional packages to install..."
  echo "${pkgs}" | xargs pkg install -y
}

checkyesno plugin_enable_pkglist && install_pkglist

echo "TODO: Update the PLUGIN_INFO"
