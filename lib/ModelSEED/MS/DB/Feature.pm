########################################################################
# ModelSEED::MS::DB::Feature - This is the moose object corresponding to the Feature object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Feature;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::FeatureRole;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Annotation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has locked => (is => 'rw', isa => 'Int', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has cksum => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has genome_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has start => (is => 'rw', isa => 'Int', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has stop => (is => 'rw', isa => 'Int', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has contig => (is => 'rw', isa => 'Str', printOrder => '5', type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has sequence => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '7', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has featureroles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FeatureRole)', metaclass => 'Typed', reader => '_featureroles', printOrder => '-1');


# LINKS:
has genome => (is => 'rw', isa => 'ModelSEED::MS::Genome', type => 'link(Annotation,genomes,genome_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_genome', weak_ref => 1);


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_genome {
  my ($self) = @_;
  return $self->getLinkedObject('Annotation','genomes',$self->genome_uuid());
}


# CONSTANTS:
sub _type { return 'Feature'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'modDate',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'locked',
            'default' => '0',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 1,
            'printOrder' => 1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'cksum',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'genome_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'start',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'stop',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'contig',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'direction',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'sequence',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, modDate => 1, locked => 2, id => 3, cksum => 4, genome_uuid => 5, start => 6, stop => 7, contig => 8, direction => 9, sequence => 10, type => 11};
sub _attributes {
  my ($self, $key) = @_;
  if (defined($key)) {
    my $ind = $attribute_map->{$key};
    if (defined($ind)) {
      return $attributes->[$ind];
    } else {
      return undef;
    }
  } else {
    return $attributes;
  }
}

my $subobjects = [
          {
            'printOrder' => -1,
            'name' => 'featureroles',
            'type' => 'encompassed',
            'class' => 'FeatureRole'
          }
        ];

my $subobject_map = {featureroles => 0};
sub _subobjects {
  my ($self, $key) = @_;
  if (defined($key)) {
    my $ind = $subobject_map->{$key};
    if (defined($ind)) {
      return $subobjects->[$ind];
    } else {
      return undef;
    }
  } else {
    return $subobjects;
  }
}


# SUBOBJECT READERS:
around 'featureroles' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('featureroles');
};


__PACKAGE__->meta->make_immutable;
1;
