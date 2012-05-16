########################################################################
# ModelSEED::MS::DB::Feature - This is the moose object corresponding to the Feature object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use ModelSEED::MS::FeatureRole;
use ModelSEED::MS::BaseObject;
package ModelSEED::MS::DB::Feature;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw',isa => 'ModelSEED::MS::Annotation', type => 'parent', metaclass => 'Typed',weak_ref => 1);


# ATTRIBUTES:
has uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_builduuid', printOrder => '0' );
has modDate => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_buildmodDate', printOrder => '-1' );
has locked => ( is => 'rw', isa => 'Int', type => 'attribute', metaclass => 'Typed', default => '0', printOrder => '-1' );
has id => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', required => 1, printOrder => '0' );
has cksum => ( is => 'rw', isa => 'ModelSEED::varchar', type => 'attribute', metaclass => 'Typed', default => '', printOrder => '0' );
has genome_uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', required => 1, printOrder => '0' );
has start => ( is => 'rw', isa => 'Int', type => 'attribute', metaclass => 'Typed', printOrder => '0' );
has stop => ( is => 'rw', isa => 'Int', type => 'attribute', metaclass => 'Typed', printOrder => '0' );
has contig => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', printOrder => '0' );
has direction => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', printOrder => '0' );
has sequence => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', printOrder => '0' );
has type => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', printOrder => '0' );


# ANCESTOR:
has ancestor_uuid => (is => 'rw',isa => 'uuid', type => 'acestor', metaclass => 'Typed');


# SUBOBJECTS:
has featureroles => (is => 'rw',default => sub{return [];},isa => 'ArrayRef|ArrayRef[ModelSEED::MS::FeatureRole]', type => 'encompassed(FeatureRole)', metaclass => 'Typed');


# LINKS:
has genome => (is => 'rw',lazy => 1,builder => '_buildgenome',isa => 'ModelSEED::MS::Genome', type => 'link(Annotation,Genome,uuid,genome_uuid)', metaclass => 'Typed',weak_ref => 1);


# BUILDERS:
sub _builduuid { return Data::UUID->new()->create_str(); }
sub _buildmodDate { return DateTime->now()->datetime(); }
sub _buildgenome {
	my ($self) = @_;
	return $self->getLinkedObject('Annotation','Genome','uuid',$self->genome_uuid());
}


# CONSTANTS:
sub _type { return 'Feature'; }
sub _typeToFunction {
	return {
		FeatureRole => 'featureroles',
	};
}


__PACKAGE__->meta->make_immutable;
1;
