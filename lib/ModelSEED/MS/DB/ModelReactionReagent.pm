########################################################################
# ModelSEED::MS::DB::ModelReactionReagent - This is the moose object corresponding to the ModelReactionReagent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use ModelSEED::MS::BaseObject;
package ModelSEED::MS::DB::ModelReactionReagent;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw',isa => 'ModelSEED::MS::ModelReaction', type => 'parent', metaclass => 'Typed',weak_ref => 1);


# ATTRIBUTES:
has modelcompound_uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', required => 1 );
has coefficient => ( is => 'rw', isa => 'Num', type => 'attribute', metaclass => 'Typed', required => 1 );




# LINKS:
has modelcompound => (is => 'rw',lazy => 1,builder => '_buildmodelcompound',isa => 'ModelSEED::MS::ModelCompound', type => 'link(Model,ModelCompound,uuid,modelcompound_uuid)', metaclass => 'Typed',weak_ref => 1);


# BUILDERS:
sub _buildmodelcompound {
	my ($self) = @_;
	return $self->getLinkedObject('Model','ModelCompound','uuid',$self->modelcompound_uuid());
}


# CONSTANTS:
sub _type { return 'ModelReactionReagent'; }


__PACKAGE__->meta->make_immutable;
1;
