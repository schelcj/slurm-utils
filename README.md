# Various Slurm utilities and plugins #

---

## sarray ##
  This script is an attempt at providing the array job concept from PBS in SLURM.
  You can run multiple jobs from a single batch script with the only difference in
  each job being the array index. The array index gives the script a means of changing
  parameters, loading differing data files or anything that requires a unique index.

## srunall ##
  This script allows a user to have a file with a list of commands to launch as batch jobs
  in the cluster without writing a batch file for each and that these commands don't
  fit well into the array format.

## plugins ##
  * __job_submit.bigmem.lua__

      Plugin to enforce minimum memory allocations in the bigmem partition

## misc ##
  * __profile-slurm.sh__

      Just a few bash functions I include in my login env to pull out some
      data that isn't directly accessible.

## utils ##
  * __cluster_status.pl__

      Displays a table of nodes with cores total and allocated and memory
      allocated and total with overall totals.

---

Chris Scheller <schelcj@umich.edu>

Copyright (C) 2011, all rights reserved by University of Michigan
