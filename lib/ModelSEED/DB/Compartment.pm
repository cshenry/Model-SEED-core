package ModelSEED::DB::Compartment;

use strict;

use base qw(ModelSEED::DB::DB::Object::AutoBase2);

__PACKAGE__->meta->setup(
    table   => 'compartments',

    columns => [
        uuid    => { type => 'character', length => 36, not_null => 1 },
        modDate => { type => 'datetime' },
        locked  => { type => 'integer' },
        id      => { type => 'varchar', length => 2, not_null => 1 },
        name    => { type => 'varchar', default => '\'\'', length => 255 },
    ],

    primary_key_columns => [ 'uuid' ],

    relationships => [
        mappings => {
            map_class => 'ModelSEED::DB::MappingCompartment',
            map_from  => 'compartment',
            map_to    => 'mapping',
            type      => 'many to many',
        },

        models => {
            map_class => 'ModelSEED::DB::ModelCompartment',
            map_from  => 'compartment',
            map_to    => 'model',
            type      => 'many to many',
        },

        reaction_rule_transports => {
            class      => 'ModelSEED::DB::ReactionRuleTransport',
            column_map => { uuid => 'compartment_uuid' },
            type       => 'one to many',
        },

        reaction_rules => {
            class      => 'ModelSEED::DB::ReactionRule',
            column_map => { uuid => 'compartment_uuid' },
            type       => 'one to many',
        },

        reactions => {
            class      => 'ModelSEED::DB::Reaction',
            column_map => { uuid => 'compartment_uuid' },
            type       => 'one to many',
        },
    ],
);

1;

