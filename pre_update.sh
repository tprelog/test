#!/usr/bin/env bash
# plugin version 5.0

# shellcheck disable=SC1091,2154
. /etc/rc.subr && load_rc_config

if [ "${plugin_ver}" == "v_0.4.0" ]; then
  warn "Version 5 is now available! Please see the wiki for breaking changes."
  warn "You may need a fresh install of this plugin in order to upgrade!"
  rm -f /root/post_install.sh
elif [ "${plugin_version%%.*}" == "5" ]; then
  true
else ## if plugin_ver != 4 then suggested a fresh install and fail.
# TODO if plugin_force_update then attempt to force upgrade (useful for debugging)
  warn "Version 5 now is available! Please see the wiki for breaking changes."
  warn "Unsupported update path! Please reinstall this plugin."
  err 1 "BREAKING CHANGES - Manual intervention is required!"
fi

exit 0
