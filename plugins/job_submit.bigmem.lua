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

  if job_desc.partition == 'biostat-bigmem' then
    log_info("Job submitted to the bigmem partition")
-- check the requested memory is greater then the required minimum
-- if not log this and kill the request
  end

  return 0
end

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
