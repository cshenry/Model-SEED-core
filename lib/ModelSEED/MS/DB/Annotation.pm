########################################################################
# ModelSEED::MS::DB::Annotation - This is the moose object corresponding to the Annotation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use ModelSEED::MS::Genome;
use ModelSEED::MS::Feature;
use ModelSEED::MS::SubsystemState;
use ModelSEED::MS::IndexedObject;
package ModelSEED::MS::DB::Annotation;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::Store', type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_builduuid', printOrder => '0' );
has defaultNameSpace => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', default => 'SEED', printOrder => '3' );
has modDate => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_buildmodDate', printOrder => '-1' );
has locked => ( is => 'rw', isa => 'Int', type => 'attribute', metaclass => 'Typed', default => '0', printOrder => '-1' );
has name => ( is => 'rw', isa => 'ModelSEED::varchar', type => 'attribute', metaclass => 'Typed', default => '', printOrder => '0' );
has mapping_uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', printOrder => '0' );


# ANCESTOR:
has ancestor_uuid => (is => 'rw',isa => 'uuid', type => 'acestor', metaclass => 'Typed');


# SUBOBJECTS:
has genomes => (is => 'rw',default => sub{return [];},isa => 'ArrayRef|ArrayRef[ModelSEED::MS::Genome]', type => 'child(Genome)', metaclass => 'Typed');
has features => (is => 'rw',default => sub{return [];},isa => 'ArrayRef|ArrayRef[ModelSEED::MS::Feature]', type => 'child(Feature)', metaclass => 'Typed');
has subsystemStates => (is => 'rw',default => sub{return [];},isa => 'ArrayRef|ArrayRef[ModelSEED::MS::SubsystemState]', type => 'child(SubsystemState)', metaclass => 'Typed');


# LINKS:
has mapping => (is => 'rw',lazy => 1,builder => '_buildmapping',isa => 'ModelSEED::MS::Mapping', type => 'link(ModelSEED::Store,Mapping,uuid,mapping_uuid)', metaclass => 'Typed',weak_ref => 1);


# BUILDERS:
sub _builduuid { return Data::UUID->new()->create_str(); }
sub _buildmodDate { return DateTime->now()->datetime(); }
sub _buildmapping {
	my ($self) = @_;
	return $self->getLinkedObject('ModelSEED::Store','Mapping','uuid',$self->mapping_uuid());
}


# CONSTANTS:
sub _type { return 'Annotation'; }
sub _typeToFunction {
	return {
		Genome => 'genomes',
		SubsystemState => 'subsystemStates',
		Feature => 'features',
	};
}


__PACKAGE__->meta->make_immutable;
1;
