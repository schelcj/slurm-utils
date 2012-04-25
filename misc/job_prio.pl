#!/usr/bin/perl

use Modern::Perl;
use System::Command;
use Data::Dumper;

my $priority_weight_age       = 10000;
my $priority_weight_fairshare = 100000;
my $priority_weight_job_size  = 1000;
my $priority_weight_partition = 1000;
my $priority_weight_qos       = 2000;
my @fields                    = (qw(job_id priority age fairshare job_size partition qos user));

my $cmd    = System::Command->new(q{sprio -h -o "%i %y %a %f %j %p %q %u"});
my $stdout = $cmd->stdout();

say "JOBID\tUSER\tPRIORITY";
while (<$stdout>) {
  chomp;
  my %entry = ();
  @entry{@fields} = split(/ /);


  say $entry{job_id} . "\t" . $entry{user} . "\t" . calculate_job_priority(\%entry);
}

$cmd->close();

sub calculate_job_priority {
  my ($entry_ref) = @_;

  #Job_priority =
  #    (PriorityWeightAge) * (age_factor) +
  #  + (PriorityWeightFairshare) * (fair-share_factor) +
  #  + (PriorityWeightJobSize) *   (job_size_factor) +
  #  + (PriorityWeightPartition) * (partition_factor) +
  #  + (PriorityWeightQOS) *       (QOS_factor) +
  my $priority =
      $priority_weight_age * $entry_ref->{age} 
    + $priority_weight_fairshare * $entry_ref->{fairshare}
    + $priority_weight_job_size * $entry_ref->{job_size}
    + $priority_weight_partition * $entry_ref->{partition}
    + $priority_weight_qos * $entry_ref->{qos};

  return $priority;
}
