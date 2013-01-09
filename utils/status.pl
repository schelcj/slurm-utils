#!/usr/bin/env perl

use Modern::Perl;
use Readonly;
use Slurm;

Readonly::Scalar my $INT     => 2**31;
Readonly::Scalar my $ROW     => q{-} x 85;
Readonly::Scalar my $ROW_FMT => qq{%-10s %-10s %-10s %-15s %-10s %-10s %-10s\n};
Readonly::Array  my @HEADERS => (qw(Node AllocCPU TotalCPU PercentUsedCPU AllocMem TotalMem PercentUsedMem));

my $slurm = Slurm::new();
my $nodes = $slurm->load_node();
my $jobs  = $slurm->load_jobs();

my $total_allocated_cores = 0;
my $total_allocated_mem   = 0;
my $total_cores           = 0;
my $total_mem             = 0;

say $ROW;
printf $ROW_FMT, @HEADERS;
say $ROW;

for my $node (@{$nodes->{node_array}}) {
  my @line = ();
  my $allocated_memory = _get_allocated_memory_for_node($node->{name});

  $total_allocated_cores += $node->{alloc_cpus};
  $total_allocated_mem   += $allocated_memory;
  $total_cores           += $node->{cpus};
  $total_mem             += $node->{real_memory};

  push @line, $node->{name};
  push @line, $node->{alloc_cpus};
  push @line, $node->{cpus};
  push @line, _get_percentage($node->{alloc_cpus}, $node->{cpus});
  push @line, $allocated_memory;
  push @line, $node->{real_memory};
  push @line, _get_percentage($allocated_memory, $node->{real_memory});

  printf $ROW_FMT, @line;
}

say $ROW;
say 'Totals:';
say $ROW;
printf $ROW_FMT,
  scalar @{$nodes->{node_array}},
  $total_allocated_cores,
  $total_cores,
  _get_percentage($total_allocated_cores, $total_cores),
  $total_allocated_mem,
  $total_mem,
  _get_percentage($total_allocated_mem, $total_mem);

sub _get_percentage {
  my ($used, $total) = @_;
  return sprintf '%.2f', (($used / $total) * 100); ## no critic (ProhibitMagicNumbers)
}

sub _get_allocated_memory_for_node {
  my ($node) = @_;
  my $total  = 0;

  map  {$total += $_}
  map  {($_->{pn_min_memory} > $INT) ? $_->{pn_min_memory} - $INT : $_->{pn_min_memory}}
  grep {$_->{nodes} =~ $node}
  grep {not IS_JOB_PENDING($_)} @{$jobs->{job_array}};

  return $total;
}
