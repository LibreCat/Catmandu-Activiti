package Catmandu::Importer::Activiti::HistoricProcessInstance;
use Catmandu::Sane;
use Catmandu::Util qw(:is :check :array);
use Activiti::Rest;
use Moo;

with 'Catmandu::Importer';

has url => (
  is => 'ro',
  isa => sub { check_string($_[0]); },
  required => 1
);
has include_process_variables => (
  is => 'ro',
  isa => sub { array_includes([qw(true false)],$_[0]) or die("must be true of false"); },
  lazy => 1,
  default => sub { "false"; }
);
has _activiti => (
  is => 'ro',
  lazy => 1,
  builder => '_build_activiti'
);
sub _build_activiti {
  my $self = $_[0];
  Activiti::Rest->new(url => $self->url);
}

sub generator {
  my $self = $_[0];
  sub {

    state $start = 0;
    state $size = 100;
    state $total;
    state $results = [];

    unless(@$results){

      if(defined $total){
        return if $start >= $total;
      }

      my $res = $self->_activiti->historic_process_instances(
        start => $start,
        size => $size,
        includeProcessVariables => $self->include_process_variables()
      )->parsed_content;

      $total = $res->{total};
      return unless @{ $res->{data} };

      $results = $res->{data};
      
      $start += $size;
    }

    shift @$results;
  };
}

=head1 NAME

Catmandu::Importer::Activiti::HistoricProcessInstance - Package that imports historic process instances from Activiti

=head1 SYNOPSIS

    use Catmandu::Importer::Activiti::HistoricProcessInstance;

    my $importer = Catmandu::Importer::Activiti::HistoricProcessInstance->new(
      url => 'http://user:password@localhost:8080/activiti-rest/service'
    );

    my $n = $importer->each(sub {
        my $hashref = $_[0];
        # ...
    });

=head1 METHODS

=head2 new()

Create a new importer

Arguments:

  include_process_variables   "true"|"false"  (default: "false")

=head2 each(&callback)

=head2 ...

Every Catmandu::Importer is a Catmandu::Iterable all its methods are inherited. The
Catmandu::Importer::Activiti::HistoricProcessInstance methods are not idempotent: Activiti feeds can only be read once.

=head1 SEE ALSO

L<Catmandu::Iterable>

=head1 AUTHOR

Nicolas Franck C<< Nicolas Franck at UGent be >>

=cut

1;
