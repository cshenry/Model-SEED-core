########################################################################
# ModelSEED::MS::ReactionRuleTransport - This is the moose object corresponding to the ReactionRuleTransport object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-19T08:21:34
########################################################################
use strict;
use Moose;
use namespace::autoclean;
use ModelSEED::MS::DB::ReactionRuleTransport;
package ModelSEED::MS::ReactionRuleTransport;
extends ModelSEED::MS::DB::ReactionRuleTransport;
# CONSTANTS:
#TODO
# FUNCTIONS:
#TODO


__PACKAGE__->meta->make_immutable;
1;
