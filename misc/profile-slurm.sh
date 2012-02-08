function _show_alloc_header() {
  printf "%-10s %-10s %-10s %-10s\n" "Node" "Allocated" "Total" "Percent Used"
  echo "---------------------------------------------"
}

function _show_alloc_result() {
  local node=$1
  local alloc=$2
  local total=$3
  local percent_used="$(echo "($alloc / $total) * 100"|bc -l)"

  printf "%-10s %-10s %-10s %-10.2f\n" $node $alloc $total $percent_used
}

function get_nodes() {
  echo $(scontrol -o show node|awk {'print $1'}|cut -d\= -f2)
}

function get_total_cores_for_node() {
  local node=$1
  echo $(scontrol -o show node $node|cut -d\  -f6|cut -d\= -f2)
}

function get_allocated_cores_for_node() {
  local node=$1
  echo $(scontrol -o show node $1|cut -d\  -f4|cut -d\= -f2)
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
  local nodes=($(get_nodes))

  _show_alloc_header

  for node in "${nodes[@]}"; do
    _show_alloc_result $node $(get_allocated_cores_for_node $node) $(get_total_cores_for_node $node)
  done
}

function show_core_alloc_for_node() {
  local node=$1

  _show_alloc_header
  _show_alloc_result $node $(get_allocated_cores_for_node $node) $(get_total_cores_for_node $node)
}

function show_mem_alloc() {
  local nodes=($(get_nodes))

  _show_alloc_header

  for node in "${nodes[@]}"; do
    _show_alloc_result $node $(get_allocated_memory_for_node $node) $(get_total_memory_for_node $node)
  done
}

function show_mem_alloc_for_node() {
  local node=$1

  _show_alloc_header
  _show_alloc_result $node  $(get_allocated_memory_for_node $node) $(get_total_memory_for_node $node)
}

function show_core_mem_alloc() {
  printf "%-10s %-10s %-10s %-15s %-10s %-10s %-10s\n" "Node" "AllocCPU" "TotalCPU" "PercentUsedCPU" "AllocMem" "TotalMem" "PercentUsedMem"
  echo "-------------------------------------------------------------------------------------"
  
  for node in $(get_nodes); do
    local core_alloc=$(get_allocated_cores_for_node $node)
    local core_total=$(get_total_cores_for_node $node)
    local mem_alloc=$(get_allocated_memory_for_node $node)
    local mem_total=$(get_total_memory_for_node $node)
    local core_perc="$(echo "($core_alloc / $core_total) * 100"|bc -l)"
    local mem_perc="$(echo "($mem_alloc / $mem_total) * 100"|bc -l)"

    printf "%-10s %-10s %-10s %-15.2f %-10s %-10s %-10.2f\n" $node $core_alloc $core_total $core_perc $mem_alloc $mem_total $mem_perc
  done
}
