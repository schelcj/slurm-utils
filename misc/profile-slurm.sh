declare -A _node_attrs

function _show_alloc_header() {
  printf "%-10s %-10s %-10s %-10s\n" "Node" "Allocated" "Total" "Percent Used"
  echo "---------------------------------------------"
}

function _show_alloc_result() {
  local node=$1
  local alloc=$2
  local total=$3

  printf "%-10s %-10s %-10s %-10.2f\n" $node $alloc $total $(_get_percent_used $alloc $total)
}

function _build_node_attrs() {
  local node=$1

  for attr in $(scontrol -o show node $node); do
    name=$(echo $attr|cut -d\= -f1)
    val=$(echo $attr|cut -d\= -f2)

    _node_attrs[$name]=$val
  done
}

function _get_percent_used() {
  printf '%.2f' $(echo "($1 / $2) * 100"|bc -l)
}

function get_nodes() {
  echo $(scontrol -o show node|awk {'print $1'}|cut -d\= -f2)
}

function get_users() {
  echo "$(sacctmgr -n -p show users|grep -v root|cut -d\| -f1)" 
}

function get_node_attr() {
  local node=$1
  local item=$2
  _build_node_attrs $node
  echo "${_node_attrs[$item]}"
}

function get_total_cores_for_node() {
  local node=$1
  echo $(get_node_attr $node "CPUTot")
}

function get_allocated_cores_for_node() {
  local node=$1
  echo $(get_node_attr $node "CPUAlloc")
}

function get_total_cores_for_cluster() {
  local total=0

  for node in $(get_nodes); do
    $total=$(( $total + $(get_total_cores_for_node $node) ))
  done

  echo $total
}

function get_total_memory_for_node() {
  local node=$1
  echo $(get_node_attr $node "RealMemory")
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
  local user=$1
  for i in $(squeue -h -u $user -o %i); do
    scontrol -d show job $i
  done
}

function show_jobs_for_node() {
  local node=$1
  for i in $(squeue -h -n $node -o %i); do
    scontrol -d show job $i
  done
}

function show_jobs_for_part() {
  local part=$1
  for i in $(squeue -n -p $part -o %i); do
    scontrol -d show job $i
  done
}

function show_core_alloc() {
  _show_alloc_header

  for node in $(get_nodes); do
    _show_alloc_result $node $(get_allocated_cores_for_node $node) $(get_total_cores_for_node $node)
  done
}

function show_core_alloc_for_node() {
  local node=$1

  _show_alloc_header
  _show_alloc_result $node $(get_allocated_cores_for_node $node) $(get_total_cores_for_node $node)
}

function show_mem_alloc() {
  _show_alloc_header

  for node in $(get_nodes); do
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
    local core_perc="$(_get_percent_used $core_alloc $core_total)"
    local mem_perc="$(_get_percent_used $mem_alloc $mem_total)"

    printf "%-10s %-10s %-10s %-15.2f %-10s %-10s %-10.2f\n" $node $core_alloc $core_total $core_perc $mem_alloc $mem_total $mem_perc
  done
}
