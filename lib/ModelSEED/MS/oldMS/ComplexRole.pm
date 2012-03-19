########################################################################
# ModelSEED::MS::ComplexRole - This is the moose object corresponding to the Role object in the database
# Author: Christopher Henry
# Author email: chenry@mcs.anl.gov
# Author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 3/4/2012
########################################################################
use strict;
use ModelSEED::utilities;
use ModelSEED::MS::Role;
use ModelSEED::MS::Mapping;
package ModelSEED::MS::ComplexRole;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use Digest::MD5 qw(md5_hex);

#Parent object link
has mapping => (is => 'rw',isa => 'ModelSEED::MS::Mapping',weak_ref => 1);

#Attributes
has 'complex_uuid'     => (is => 'rw', isa => 'Str', default  => "");
has 'role_uuid'  => (is => 'rw', isa => 'Str', default  => "");
has 'optional'       => (is => 'rw', isa => 'Str', default  => "");
has 'type'   => (is => 'rw', isa => 'Str', default  => "");

#Subobjects
has 'role' => (is => 'rw', isa => 'ModelSEED::MS::Role',lazy => 1,builder => '_buildRole');

#Constants
has 'dbAttributes' => ( is => 'ro', isa => 'ArrayRef[Str]', 
    builder => '_buildDbAttributes' );
has '_type' => (is => 'ro', isa => 'Str',default => "Complex");

#Internally maintained variables
has 'changed' => (is => 'rw', isa => 'Bool',default => 0);

sub BUILDARGS {
    my ($self,$params) = @_;
    my $attr = $params->{attributes};
    my $rels = $params->{relationships};
    $params->{_type} = $params->{type};
    delete $params->{type};
    if(defined($attr)) {
        map { $params->{$_} = $attr->{$_} } grep { defined($attr->{$_}) } keys %$attr;
        delete $params->{attributes};
    }
	return $params;
}

sub serializeToDB {
    my ($self) = @_;
	my $data = { type => $self->_type };
	my $attributes = $self->dbAttributes();
	for (my $i=0; $i < @{$attributes}; $i++) {
		my $function = $attributes->[$i];
		$data->{attributes}->{$function} = $self->$function();
	}
	return $data;
}

sub _buildRole {
    my ($self) = @_;
	if (defined($self->mapping())) {
        my $role = $self->mapping()->getRole({uuid => $self->role_uuid()});
        if (!defined($role)) {
        	ModelSEED::utilities::ERROR("Role ".$self->role_uuid." not found in mapping!");
        }
        return $role;
    } else {
        ModelSEED::utilities::ERROR("Cannot retrieve role without mapping!");
    }
}

sub _buildDbAttributes {
    return [qw( complex_uuid role_uuid  optional type )];
}
sub _buildUUID { return Data::UUID->new()->create_str(); }
sub _buildModDate { return DateTime->now(); }

__PACKAGE__->meta->make_immutable;
1;
