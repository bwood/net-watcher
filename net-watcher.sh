#!/bin/bash
# sets the exit code of a pipeline to that of the rightmost command to
# exit with a non-zero status, or to zero if all commands of the
# pipeline exit successfully.
set -o pipefail
seconds=5

down_message="NO CONNECTION"

while true; do
  configured_ip_addresses="$((ifconfig | \
    grep -iEo '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | \
    grep -vi '127.0.0.1' | tr '\n' ' ') || echo 'NONE')"
  externally_visible_ip_address="$(curl -m 1 ipinfo.io/ip 2>/dev/null || echo $down_message)"
  computed_state="Public: $externally_visible_ip_address\nWiFi:   $configured_ip_addresses"
  
  statefile="/tmp/net-watcher.state"
  
  if [ -f $statefile ]; then
    echo "$computed_state" > "${statefile}-new"
    new_chksum="$(md5 "${statefile}-new" | awk '{print $NF}')"
    existing_chksum="$(md5 "${statefile}" | awk '{print $NF}')"
    if [[ "${new_chksum}" != "${existing_chksum}" ]]; then

	if [[ "$externally_visible_ip_address" != "$down_message" ]]; then
            state="UP"
	else
	    state="DOWN"
	fi
	
	mv "${statefile}-new" "${statefile}"
	timestamp=$(date "+%H:%M:%S")
	osascript -e "display notification \"$(cat $statefile)\" with title \"$timestamp: Network $state\" sound name \"Tink\""
    else
      rm "${statefile}-new"
    fi
  else
    echo "$computed_state" > $statefile
  fi
  sleep $seconds
done
