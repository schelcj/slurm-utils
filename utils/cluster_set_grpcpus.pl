#!/usr/bin/env perl

use Modern::Perl;
use Slurm;
use Getopt::Compact;

my $opts        = Getopt::Compact->new(struct => [[[qw(p percentage)], q{Percentage of total cores}, q{=i}]])->opts();

die "Percentage required" if not $opts->{percentage};

my $qos         = 'biostat';
my $slurm       = Slurm::new();
my $nodes       = $slurm->load_node();
my $total_cores = 0;

map {$total_cores += $_->{cpus}} @{$nodes->{node_array}};

my $grpcpus = sprintf '%0.f', $total_cores * (0.01 * $opts->{percentage});

say "sacctmgr update qos name=$qos set grpcpus=$grpcpus";
