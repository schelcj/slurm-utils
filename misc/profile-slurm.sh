function show_jobs_for_user() {
  local user=$1
  for i in $(squeue -h -u $user -o %i); do
    scontrol -d show job $i
  done
}

function show_jobs_for_node() {
  local node=$1
  for i in $(squeue -h -w $node -o %i); do
    scontrol -d show job $i
  done
}

function show_jobs_for_part() {
  local part=$1
  for i in $(squeue -p $part -o %i); do
    scontrol -d show job $i
  done
}

function show_sstat_for_user() {
  local user=$1
  local jobs=($(squeue -h -t r -u $user|awk {'print $1'}))

  sstat -a -j $(echo ${jobs[*]}|tr ' ' ',')
}

function show_sstat_for_jobs() {
  local jobs=($(squeue -h -t r|awk {'print $1'}))
  sstat -a -j $(echo ${jobs[*]}|tr ' ' ',')
}
