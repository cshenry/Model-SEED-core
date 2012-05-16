#
# Subtypes for ModelSEED::MS::User
#
package ModelSEED::MS::Types::User;
use Moose::Util::TypeConstraints;
use ModelSEED::MS::DB::User;

coerce 'ModelSEED::MS::DB::User',
    from 'HashRef',
    via { ModelSEED::MS::DB::User->new($_) };
subtype 'ModelSEED::MS::ArrayRefOfUser',
    as 'ArrayRef[ModelSEED::MS::DB::User]';
coerce 'ModelSEED::MS::ArrayRefOfUser',
    from 'ArrayRef',
    via { [ map { ModelSEED::MS::DB::User->new( $_ ) } @{$_} ] };

1;
