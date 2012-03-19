########################################################################
# ModelSEED::MS::DB::ReactionRule - This is the moose object corresponding to the ReactionRule object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-19T08:21:34
########################################################################
use strict;
use Moose;
use namespace::autoclean;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::Mapping;
use ModelSEED::MS::ReactionRuleTransport;
use ModelSEED::MS::Reaction;
use ModelSEED::MS::Compartment;
package ModelSEED::MS::DB::ReactionRule;
extends ModelSEED::MS::BaseObject;


# PARENT:
has parent => (is => 'rw',isa => 'ModelSEED::MS::Mapping',weak_ref => 1);


# ATTRIBUTES:
has uuid => ( is => 'rw', isa => 'uuid', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_builduuid' );
has modDate => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_buildmodDate' );
has locked => ( is => 'rw', isa => 'Int', type => 'attribute', metaclass => 'Typed', default => '0' );
has reaction_uuid => ( is => 'rw', isa => 'uuid', type => 'attribute', metaclass => 'Typed', required => 1 );
has compartment_uuid => ( is => 'rw', isa => 'uuid', type => 'attribute', metaclass => 'Typed', required => 1 );
has direction => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', default => '=' );
has transprotonNature => ( is => 'rw', isa => 'varchar', type => 'attribute', metaclass => 'Typed', default => '' );


# ANCESTOR:
has ancestor_uuid => (is => 'rw',isa => 'uuid');


# SUBOBJECTS:
has ReactionRuleTransport => (is => 'rw',default => sub{return [];},isa => 'ArrayRef|ArrayRef[ModelSEED::MS::ReactionRuleTransport]', type => 'encompassed', metaclass => 'Typed');


# LINKS:
has reaction => (is => 'rw',lazy => 1,builder => '_buildreaction',isa => 'ModelSEED::MS::Reaction',weak_ref => 1);
has compartment => (is => 'rw',lazy => 1,builder => '_buildcompartment',isa => 'ModelSEED::MS::Compartment',weak_ref => 1);


# BUILDERS:
sub _buildUUID { return Data::UUID->new()->create_str(); }
sub _buildModDate { return DateTime->now()->datetime(); }
sub _buildreaction {
	my ($self) = ;
	return $self->getLinkedObject('Biochemistry','Reaction','uuid',$self->reaction_uuid());
}
sub _buildcompartment {
	my ($self) = ;
	return $self->getLinkedObject('Biochemistry','Compartment','uuid',$self->compartment_uuid());
}


# CONSTANTS:
sub _type { return 'ReactionRule'; }


__PACKAGE__->meta->make_immutable;
1;
