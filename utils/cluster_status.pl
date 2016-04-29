#!/usr/bin/env perl

use 5.010_000;
use strict;
use warnings;
use feature qw(say);

use Getopt::Long qw(HelpMessage);
use Slurm qw(:constant);
use Slurm::Hostlist;

GetOptions(
  'partition=s' => \my $partition,
  'state=s'     => \my $state,
  'help'        => sub { HelpMessage(0) },
) or HelpMessage(1);

my $INT             = 2**31;
my $HR              = q{-} x 117;
my $ROW_FMT         = qq{%-20s %-10s %-10s %-15s %-10s %-10s %-10s %-15s %-10s\n};
my @HEADERS         = (qw(Node AllocCPU TotalCPU PercentUsedCPU CPULoad AllocMem TotalMem PercentUsedMem NodeState));
my $slurm           = Slurm::new();
my $nodes           = $slurm->load_node();
my $jobs            = $slurm->load_jobs({flags => PART_FLAG_HIDDEN_CLR});
my @partition_nodes = ();
my @rows            = ();

my $total_nodes           = 0;
my $total_allocated_cores = 0;
my $total_allocated_mem   = 0;
my $total_cores           = 0;
my $total_mem             = 0;

if ($partition) {
  my $partitions = $slurm->load_partitions();

  for my $part (@{$partitions->{partition_array}}) {
    next unless $part->{name} eq $partition;

    my $hosts = Slurm::Hostlist::create($part->{nodes});

    while (my $host = $hosts->shift()) {
      push @partition_nodes, $host;
    }
  }
}

for my $node (@{$nodes->{node_array}}) {
  next unless $node;

  if ($partition) {
    next unless grep {/^$node->{name}$/} @partition_nodes;
  }

  my $node_state = $slurm->node_state_string($node->{node_state});
  next if $state and $node_state !~ /$state/i;

  my $allocated_memory = _get_allocated_memory_for_node($node->{name});

  $total_nodes++;
  $total_allocated_cores += $node->{alloc_cpus};
  $total_allocated_mem   += $allocated_memory;
  $total_cores           += $node->{cpus};
  $total_mem             += $node->{real_memory};

  push @rows, sprintf $ROW_FMT,
    $node->{name},
    $node->{alloc_cpus},
    $node->{cpus},
    _get_percentage($node->{alloc_cpus}, $node->{cpus}),
    ($node_state ne 'DOWN') ? $node->{cpu_load} / 100 : 0,
    $allocated_memory,
    $node->{real_memory},
    _get_percentage($allocated_memory, $node->{real_memory}),
    $node_state;
}

if (@rows) {
  say $HR;
  printf $ROW_FMT, @HEADERS;
  say $HR;

  print $_ for @rows;

  say $HR;
  say 'Totals:';
  printf $ROW_FMT, @HEADERS;
  say $HR;

  printf $ROW_FMT,
    $total_nodes,
    $total_allocated_cores,
    $total_cores,
    _get_percentage($total_allocated_cores, $total_cores) // 0,
    q{},
    $total_allocated_mem,
    $total_mem,
    _get_percentage($total_allocated_mem, $total_mem) // 0,
    q{};
}

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

__END__

=head1 NAME

sstate - Print state of Slurm cluster nodes

=head1 SYNOPSIS

  -p, --partition=name Limit nodes to a specific partition
  -s, --state=state    Limit nodes to a specific state (ie; DOWN, DRAINED)
  -h, --help           Print this help

=head1 VERSION

0.9

=cut
