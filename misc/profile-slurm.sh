function get_nodes() {
  echo $(scontrol -o show node|awk {'print $1'}|cut -d\= -f2)
}

function get_total_cores() {
  local total_cores=0

  for i in $(scontrol -o show node|cut -d\  -f6|cut -d\= -f2); do
    total_cores=$(($total_cores + $i))
  done

  echo $total_cores
}

function get_allocated_cores() {
  local allocated_cores=0

  for i in $(scontrol -o show node|cut -d\  -f4|cut -d\= -f2); do
    allocated_cores=$(($allocated_cores + $i))
  done

  echo $allocated_cores
}

function get_total_memory_for_node() {
  local node=$1
  echo $(scontrol show node $node|grep 'RealMem'|awk {'print $2'}|cut -d\= -f2)
}

function get_allocated_memory_for_node() {
  local node=$1
  local allocated_memory=0

  for i in $(show_jobs_for_node $node|grep 'Mem='|awk {'print $3'}|cut -d\= -f2); do
    allocated_memory=$(($allocated_memory + $i))
  done 
  echo $allocated_memory
}

function show_jobs_for_user() {
  local user="$1"
  for i in $(squeue -h -u $user -o %i); do
    scontrol -d show job $i
  done
}

function show_jobs_for_node() {
  local node="$1"
  for i in $(squeue -h -n $node -o %i); do
    scontrol -d show job $i
  done
}

function show_jobs_for_part() {
  local part="$1"
  for i in $(squeue -n -p $part -o %i); do
    scontrol -d show job $i
  done
}

function hold_jobs_for_user() {
  local user=$1
  for i in $(sprio -l -u $user -h -o %i); do
    sudo scontrol update JobId=${i} Priority=0
  done
}

function show_core_alloc() {
  allocated=$(get_allocated_cores)
  total=$(get_total_cores)
  percent_use_by_core=$(( ($allocated / $total) * 100 ))
  percent_use_by_core="$(echo "($allocated / $total) * 100"|bc -l)"

  echo "Overall Core Usage"
  echo "----------------------"
  printf "Allocated: %9d\n" $allocated
  printf "Total: %13d\n" $total
  printf "Percent by core: %4.2f%%\n" $percent_use_by_core
}

function show_mem_alloc() {
  local nodes=($(get_nodes))

  printf "%-10s %-10s %-10s %-10s\n" "Node" "Allocated" "Total" "Percent Used"
  echo "---------------------------------------------"

  for node in "${nodes[@]}"; do
    local total=$(get_total_memory_for_node $node)
    local alloc=$(get_allocated_memory_for_node $node)
    local percent_used="$(echo "($alloc / $total) * 100"|bc -l)"

    printf "%-10s %-10s %-10s %-10.2f\n" $node $alloc $total $percent_used
  done
}

function show_mem_alloc_for_node() {
  local node=$1
  local alloc=0
  local total=$(get_total_memory_for_node $node)
  local alloc=$(get_allocated_memory_for_node $node)
  local percent_used="$(echo "($alloc / $total) * 100"|bc -l)"

  printf "Node: %13s\n" $node
  printf "Allocated: %8d\n" $alloc
  printf "Total: %12d\n" $total
  printf "Percent used: %4.2f%%\n" $percent_used
}
