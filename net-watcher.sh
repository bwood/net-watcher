#!/bin/bash
# sets the exit code of a pipeline to that of the rightmost command to
# exit with a non-zero status, or to zero if all commands of the
# pipeline exit successfully.
set -o pipefail
seconds=5

while true; do
  configured_ip_addresses="$((ifconfig | \
    grep -iEo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    grep -vi '127.0.0.1' | tr '\n' ' ') || echo NONE_CONFIGURED)"
  externally_visible_ip_address="$(curl -m 1 ipinfo.io/ip 2>/dev/null || echo NO_CONNECTIVITY)"
  computed_state="Actual:  $externally_visible_ip_address, Configured: $configured_ip_addresses"
  
  statefile="/tmp/net-watcher.state"
  if [ -f $statefile ]; then
    echo "$computed_state" > "${statefile}-new"
    new_chksum="$(md5 "${statefile}-new" | awk '{print $NF}')"
    existing_chksum="$(md5 "${statefile}" | awk '{print $NF}')"
    if [[ "${new_chksum}" != "${existing_chksum}" ]]; then
      mv "${statefile}-new" "${statefile}"
      osascript -e "display notification \"$(cat $statefile)\" with title \"ALERT: Network Changed\" sound name \"Tink\""
    else
      rm "${statefile}-new"
    fi
  else
    echo "$computed_state" > $statefile
  fi
  sleep $seconds
done
