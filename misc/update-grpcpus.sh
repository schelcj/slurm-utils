#!/bin/bash

TOTAL_CORES=$(get_total_cores_for_cluster)
TOTAL_CORE_PERCENTAGE=75
MAX_CORES="$(printf '%0.f' $(echo "$TOTAL_CORES * (0.01 * $TOTAL_CORE_PERCENTAGE)"|bc))"

for user in $(get_users); do
  echo "sacctmgr -i update user where name=${user} set grpcpus=${MAX_CORES}"
done
