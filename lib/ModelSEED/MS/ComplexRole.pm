########################################################################
# ModelSEED::MS::ComplexRole - This is the moose object corresponding to the ComplexRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-19T08:21:34
########################################################################
use strict;
use Moose;
use namespace::autoclean;
use ModelSEED::MS::DB::ComplexRole;
package ModelSEED::MS::ComplexRole;
extends ModelSEED::MS::DB::ComplexRole;
# CONSTANTS:
#TODO
# FUNCTIONS:
#TODO


__PACKAGE__->meta->make_immutable;
1;
