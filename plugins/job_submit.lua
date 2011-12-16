function _build_part_table ( part_list )
  local part_rec = {}
  for i in ipairs(part_list) do
    part_rec[i] = { part_rec_ptr=part_list[i] }
    setmetatable (part_rec[i], part_rec_meta)
  end
  return part_rec
end

function slurm_job_submit ( job_desc, part_list )
  setmetatable (job_desc, job_req_meta)
  local part_rec = _build_part_table (part_list)

  if job_desc.partition == bigmem_part_name then
    local req_mem = job_desc.pn_min_memory

    if req_mem >= mem_per_cpu_base then
      req_mem = req_mem - mem_per_cpu_base
    end

    log_debug("slurm_job_submit: mem_per_cpu_base: %d pn_min_memory: %d req_mem: %d",
      mem_per_cpu_base, job_desc.pn_min_memory, req_mem)

    if bigmem_min > req_mem then
      log_info("slurm_job_submit: rejecting %s job for min memory %d", bigmem_part_name, req_mem)
      return 2044
    end

  end

  return 0
end

function slurm_job_modify ( job_desc, job_rec, part_list )
  setmetatable (job_desc, job_req_meta)
  setmetatable (job_rec,  job_rec_meta)
  local part_rec = _build_part_table (part_list)

  return 0
end

-- Magic number: not sure yet where this comes from
mem_per_cpu_base = 2147483648
bigmem_min = 30000
bigmem_part_name = 'biostat-bigmem'

log_info = slurm.log_info
log_verbose = slurm.log_verbose
log_debug = slurm.log_debug
log_err = slurm.error

job_rec_meta = {
  __index = function (table, key)
    return _get_job_rec_field(table.job_rec_ptr, key)
  end
}
job_req_meta = {
  __index = function (table, key)
    return _get_job_req_field(table.job_desc_ptr, key)
  end,
  __newindex = function (table, key, value)
    return _set_job_req_field(table.job_desc_ptr, key, value or "")
  end
}
part_rec_meta = {
  __index = function (table, key)
    return _get_part_rec_field(table.part_rec_ptr, key)
  end
}

log_info("initialized")

return slurm.SUCCESS
