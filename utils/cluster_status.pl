#!/usr/bin/env perl

use 5.010_000;
use strict;
use warnings;
use Slurm qw(:constant);
use feature qw(say);

my $INT     = 2**31;
my $HR      = q{-} x 96;
my $ROW_FMT = qq{%-10s %-10s %-10s %-15s %-10s %-10s %-15s %-10s\n};
my @HEADERS = (qw(Node AllocCPU TotalCPU PercentUsedCPU AllocMem TotalMem PercentUsedMem NodeState));
my $slurm   = Slurm::new();
my $nodes   = $slurm->load_node();
my $jobs    = $slurm->load_jobs({flags => PART_FLAG_HIDDEN_CLR});

my $total_allocated_cores = 0;
my $total_allocated_mem   = 0;
my $total_cores           = 0;
my $total_mem             = 0;

say $HR;
printf $ROW_FMT, @HEADERS;
say $HR;

for my $node (@{$nodes->{node_array}}) {
  next unless $node;

  my $allocated_memory = _get_allocated_memory_for_node($node->{name});

  $total_allocated_cores += $node->{alloc_cpus};
  $total_allocated_mem   += $allocated_memory;
  $total_cores           += $node->{cpus};
  $total_mem             += $node->{real_memory};

  printf $ROW_FMT,
    $node->{name},
    $node->{alloc_cpus},
    $node->{cpus},
    _get_percentage($node->{alloc_cpus}, $node->{cpus}),
    $allocated_memory,
    $node->{real_memory},
    _get_percentage($allocated_memory, $node->{real_memory}),
    $slurm->node_state_string($node->{node_state});
}

say $HR;
say 'Totals:';
say $HR;

printf $ROW_FMT,
  scalar @{$nodes->{node_array}},
  $total_allocated_cores,
  $total_cores,
  _get_percentage($total_allocated_cores, $total_cores),
  $total_allocated_mem,
  $total_mem,
  _get_percentage($total_allocated_mem, $total_mem),
  q{};

sub _get_percentage {
  my ($used, $total) = @_;
  return if not $total;
  return sprintf '%.2f', (($used / $total) * 100);    ## no critic (ProhibitMagicNumbers)
}

sub _get_allocated_memory_for_node {
  my ($node) = @_;
  my $total = 0;

  map {$total += $_}
    map {($_->{pn_min_memory} > $INT) ? $_->{pn_min_memory} - $INT : $_->{pn_min_memory}}
    grep {$_->{nodes} =~ $node}
    grep {not IS_JOB_PENDING($_)} @{$jobs->{job_array}};

  return $total;
}
