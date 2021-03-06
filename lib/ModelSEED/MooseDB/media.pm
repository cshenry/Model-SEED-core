########################################################################
# ModelSEED::MooseDB::media - This is the moose object corresponding to the media object in the database
# Author: Christopher Henry
# Author email: chenry@mcs.anl.gov
# Author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 11/6/2011
########################################################################
use strict;
use ModelSEED::globals;
use ModelSEED::MooseDB::object;
use ModelSEED::MooseDB::mediacpd;
package ModelSEED::MooseDB::media;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends 'ModelSEED::MooseDB::object';

#with Storage('format' => 'JSON', 'io' => 'File'); 
#Other formats include Storable and YAML
#Other io include AtomicFile and StorableFile

has 'id' => (is => 'ro', isa => 'Str', required => 1, index => 0, metaclass => 'Indexed');
has 'owner' => (is => 'ro', isa => 'Str', required => 1);#, metaclass => 'DoNotSerialize');
has 'modificationDate' => (is => 'ro', isa => 'Int', required => 1, default => 0);#, metaclass => 'DoNotSerialize');
has 'creationDate' => (is => 'ro', isa => 'Int', required => 1);#, metaclass => 'DoNotSerialize');
has 'aliases' => (is => 'ro', isa => 'Str', required => 1, default => "", index => 1, metaclass => 'Indexed');
has 'aerobic' => (is => 'ro', isa => 'Bool', required => 1, default => 1);#, metaclass => 'DoNotSerialize');
has 'public' => (is => 'ro', isa => 'Bool', required => 1);#, metaclass => 'DoNotSerialize');
has 'mediaCompounds' => (is => 'ro', isa => 'ArrayRef[ModelSEED::MooseDB::mediacpd]', lazy => 1, builder => '_build_mediaCompounds', index => 2, metaclass => 'Indexed');

sub BUILD {
    my ($self,$params) = @_;
	$params = ModelSEED::utilities::ARGS($params,[],{});
}

around 'BUILDARGS' => sub {
	my ($orig,$self,$args) = @_;
	$args = $self->$orig($args);
	$args->{_type} = "media";
	if (defined($args->{filedata})) {
		$args = $self->parse($args);
	}
	return $args;
};

sub _build_mediaCompounds {
    my ($self) = @_;
    return $self->db()->get_moose_objects("mediacpd",{MEDIA => $self->id()});
}

sub print {
	my ($self) = @_;
	my $data = [
		"id\t".$self->id(),
		"owner\t".$self->owner(),
		"modificationDate\t".$self->modificationDate(),
		"creationDate\t".$self->creationDate(),
		"aliases\t".$self->aliases(),
		"aerobic\t".$self->aerobic(),
		"public\t".$self->public(),
		"mediaCompounds{",
		"entity\ttype\tconcentration\tminFlux\tmaxFlux"
	];
	my $mediacpd = $self->mediaCompounds();
	for (my $i=0; $i < @{$mediacpd}; $i++) {
		push(@{$data},$mediacpd->[$i]->entity()."\t".$mediacpd->[$i]->type()."\t".$mediacpd->[$i]->concentration()."\t".$mediacpd->[$i]->minFlux()."\t".$mediacpd->[$i]->maxFlux());
	}
	push(@{$data},"}");
	return $data;
}

sub parse {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["filedata"],{});
	for (my $i=0; $i < @{$args->{filedata}}; $i++) {
		my $array = [split(/\t/,$args->{filedata}->[$i])];
		my $function = $array->[0];
		if (defined ($array->[1]) && ($function eq "id" || $function eq "owner" || $function eq "modificationDate" || $function eq "creationDate" || $function eq "aliases" || $function eq "aerobic" || $function eq "public")) {
			$args->{$function} = $array->[1];
		} elsif ($function eq "mediaCompounds{") {
			$i++;
			$array = [split(/\t/,$args->{filedata}->[$i])];
			$i++;
			while ($args->{filedata}->[$i] ne "}") {
				my $newarray = [split(/\t/,$args->{filedata}->[$i])];
				my $newData;
				for (my $j=0; $j < @{$array}; $j++) {
					push(@{$newData},$array->[$j]."\t".$newarray->[$j]);
				}
				my $mediacpd = ModelSEED::MooseDB::mediacpd->new({db => $args->{db},MEDIA => $args->{id},filedata => $newData});
				push(@{$args->{mediaCompounds}},$mediacpd);
				$i++;
			}
		}
	}
	return $args;
}

sub syncWithPPODB {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,[],{overwrite => 0});
	my $object = $self->db()->sudo_get_object($self->_type(),{id => $self->id()});
	if (defined($object)) {
		if ($args->{overwrite} == 0 || $object->owner() ne $self->owner()) {
			ModelSEED::utilities::ERROR("Media exists in database. Cannot update without ownership or specifying overwrite.");
		}
		$object->modificationDate($self->modificationDate());
		$object->creationDate($self->creationDate());
		$object->aliases($self->aliases());
		$object->aerobic($self->aerobic());
		$object->public($self->public());
		my $objects = $self->db()->sudo_get_objects("mediacpd",{MEDIA => $self->id()});
		for (my $i=0; $i < @{$objects};$i++) {
			$objects->[$i]->delete();
		}
	} else {
		$self->db()->create_object("media",{
			id => $self->id(),
			owner => $self->owner(),
			modificationDate => $self->modificationDate(),
			creationDate => $self->creationDate(),
			aliases => $self->aliases(),
			aerobic => $self->aerobic(),
			public => $self->public(),
		});
	}
	my $mediacpd = $self->mediaCompounds();
	for (my $i=0; $i < @{$mediacpd};$i++) {
		$self->db()->create_object("mediacpd",{
			MEDIA => $mediacpd->[$i]->MEDIA(),
			entity => $mediacpd->[$i]->entity(),
			type => $mediacpd->[$i]->type(),
			concentration => $mediacpd->[$i]->concentration(),
			maxFlux => $mediacpd->[$i]->maxFlux(),
			minFlux => $mediacpd->[$i]->minFlux(),
		});
	}
}

1;
