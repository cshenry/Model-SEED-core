# -*- perl -*-
########################################################################
# Model SEED Command API
# Initiating author: Christopher Henry
# Initiating author email: chrisshenry@gmail.com
# Initiating author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 12/3/2011
########################################################################
use strict;
use ModelSEED::globals;
package ModelSEED::ServerBackends::ModelSEEDCommandAPI;

=head3 new
Definition:
	ModelSEEDCommandAPI = ModelSEED::ServerBackends::ModelSEEDCommandAPI->new();
Description:
	Returns a ModelSEEDCommandAPI object
=cut
sub new { 
	my $self = {};
	ModelSEED::globals::CREATEFIGMODEL();
    return bless $self;
}

=head3 methods
Definition:
	[string] = ModelSEED::ServerBackends::ModelSEEDCommandAPI->new();
Description:
	Returns a list of public methods available in the ModelSEEDCommandAPI object
=cut
sub methods {
    my ($self) = @_;
	return [
		"mscreateuser",
		"msdeleteuser",
		"mslogin",
		"sqblastgenomes",
		"fbasimulatekomedialist",
		"fbacheckgrowth"
	];
}
=head
=NAME
mscreateuser
=CATEGORY
Workspace Operations
=DEFINITION
Output = mscreateuser({
	login => string:Login name of the new user account,
	password => string:Password for the new user account, which will be stored in encryted form,
	firstname => string:First name of the new proposed user,
	lastname => string:Last name of the new proposed user,
	email => string:Email of the new proposed user
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1
}
=SHORT DESCRIPTION
creating a new local account for a model SEED installation
=DESCRIPTION
Sometimes rather than importing an account from the SEED (which you would do using the ''mslogin'' command), you want to create a stand-alone account in the local Model SEED database only. To do this, use the ''createlocaluser'' binary. Once the local account exists, you can use the ''login'' binary to log into your local Model SEED account. This allows you to access, create, and manipulate private data in your local database. HOWEVER, because this is a local account only, you will not be able to use the account to access any private data in the SEED system. For this reason, we recommend importing a SEED account using the ''login'' binary rather than making local accounts with no SEED equivalent. If you require a SEED account, please go to the registration page: [http://pubseed.theseed.org/seedviewer.cgi?page=Register SEED account registration].
=cut
sub mscreateuser {
    my ($self,$args) = @_;
	try {
		$args = ModelSEED::utilities::ARGS($args,["login","password","firstname","lastname","email"],{});
		if (ModelSEED::globals::GETFIGMODEL()->config("PPO_tbl_user")->{name}->[0] ne "ModelDB") {
			return {SUCCESS => 0,ERROR => "Cannot use this function to add user to any database except ModelDB"};
		}
		my $usr = ModelSEED::globals::GETFIGMODEL()->database()->get_object("user",{login => $args->{login}});
		if (defined($usr)) {
			return {SUCCESS => 0,ERROR => "User with login ".$args->{login}." already exists!"};	
		}
		$usr = ModelSEED::globals::GETFIGMODEL()->database()->create_object("user",{
			login => $args->{login},
			password => "NONE",
			firstname => $args->{"firstname"},
			lastname => $args->{"lastname"},
			email => $args->{email}
		});
		$usr->set_password($args->{password});
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
    return {SUCCESS => 1,MESSAGE => "Successfully created user account ".$args->{login}};
}
=head
=NAME
msdeleteuser
=CATEGORY
Workspace Operations
=DEFINITION
Output = msdeleteuser({
	login => string:Login of the useraccount to be deleted,
	password => string:Password of the useraccount to be deleted
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1
}
=SHORT DESCRIPTION
deleting the local instantiation of the specified user account
=DESCRIPTION
This function deletes the local copy of the specified user account from the local Model SEED distribution. This function WILL NOT delete accounts from the centralized SEED database.
=cut
sub msdeleteuser {
    my ($self,$args) = @_;
	try {
		$args = ModelSEED::utilities::ARGS($args,["login","password"],{});
		if (ModelSEED::globals::GETFIGMODEL()->config("PPO_tbl_user")->{name}->[0] ne "ModelDB") {
			return {SUCCESS => 0,ERROR => "This function cannot be used in the centralized SEED database!"};
		}
		ModelSEED::globals::GETFIGMODEL()->authenticate($args);
		if (!defined(ModelSEED::globals::GETFIGMODEL()->userObj()) || ModelSEED::globals::GETFIGMODEL()->userObj()->login() ne $args->{username}) {
			return {SUCCESS => 0,ERROR => "No account found that matches the input credentials!"};
		}
		ModelSEED::globals::GETFIGMODEL()->userObj()->delete();
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {SUCCESS => 1,MESSAGE => "Account successfully deleted!"};
}
=head
=NAME
mslogin
=CATEGORY
Workspace Operations
=DEFINITION
Output = mslogin({
	login => string:username of user account you wish to log into or import from the SEED,
	password => string:password of user account you wish to log into or import from the SEED,
	noimport => 0/1:username of user account you wish to log into,
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1
}
=SHORT DESCRIPTION
login as new user and import user account from SEED
=DESCRIPTION
This command is used to login as a user in the Model SEED environment. If you have a SEED account already, use those credentials to log in here. Your account information will automatically be imported and used locally. You will remain logged in until you use either the '''mslogin''' or '''mslogout''' command. Once you login, you will automatically switch to the current workspace for the account you log into.
=cut
sub mslogin {
    my ($self,$args) = @_;
	try {
		$args = ModelSEED::utilities::ARGS($args,["login","password"],{
			noimport => 0
		});
		#Turning off import if you're already using the central SEED
		if (ModelSEED::globals::GETFIGMODEL()->config("PPO_tbl_user")->{name}->[0] eq "ModelDB") {
			$args->{noimport} = 0;	
		}
		#Checking for existing account in local database
		my $usrObj = ModelSEED::globals::GETFIGMODEL()->database()->get_object("user",{login => $args->{username}});
		if (!defined($usrObj) && ModelSEED::globals::GETFIGMODEL()->config("PPO_tbl_user")->{name}->[0] ne "ModelDB") {
			return {SUCCESS => 0,ERROR => "Could not find specified user account. Try new \"username\" or register an account on the SEED website!"};
		}
		#If local account was not found, attempting to import account from the SEED
		my $message = "";
		if (!defined($usrObj) && $args->{noimport} == 0) {
	        $message .= "Unable to find account locally, trying to obtain login info from theseed.org...\n";
			$usrObj = ModelSEED::globals::GETFIGMODEL()->import_seed_account({
				username => $args->{username},
				password => $args->{password}
			});
			if (!defined($usrObj)) {
				return {SUCCESS => 0,ERROR => "Could not find specified user account in the local or SEED environment.".
	                "Try new \"username\", run \"createlocaluser\", or register an account on the SEED website."};
			}
	        $message .= "Success! Downloaded user credentials from theseed.org!\n";
		}
		#Authenticating
		ModelSEED::globals::GETFIGMODEL()->authenticate($args);
		if (!defined(ModelSEED::globals::GETFIGMODEL()->userObj()) || ModelSEED::globals::GETFIGMODEL()->userObj()->login() ne $args->{username}) {
			return {SUCCESS => 0,ERROR => "Authentication failed! Try new password!"};
		} 
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => "Authentication Successful!"
	};
}
=head
=NAME
sqblastgenomes
=CATEGORY
Sequence Analysis Operations
=DEFINITION
Output = sqblastgenomes({
	sequences => [string]:list of nucelotide sequences that should be blasted against the specified genome sequences,
	genomes => [string]:list of the genome IDs that the input sequence should be blasted against,
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
blast sequences against genomes
=DESCRIPTION
This function will blast one or more specified sequences against one or more specified genomes. Results will be printed in a file in the current workspace.
=cut
sub sqblastgenomes {
	my ($self,$args) = @_;
	my $results;
	try {
		$args = ModelSEED::utilities::ARGS($args,["sequences","genomes"],{});
		my $svr = ModelSEED::globals::GETFIGMODEL()->server("MSSeedSupportClient");
		$results = $svr->blast_sequence({
	    	sequences => $args->{sequences},
	    	genomes => $args->{genomes}
	    });
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => "Sequence analysis successful!",
		RESULTS => $results
	};
}
=head
=NAME
fbasimulatekomedialist
=CATEGORY
Flux Balance Analysis Operations
=DEFINITION
Output = fbasimulatekomedialist({
	model => string:Full ID of the model to be analyzed,
	media => [string]:Name of the media conditions in the Model SEED database in which the analysis should be performed,
	rxnKO => [[string]]:delimited list of reactions to be knocked out during the analysis
	geneKO => [string]:delimited list of genes to be knocked out during the analysis
	drainRxn => [string]:list of reactions whose reactants will be added as drain fluxes in the model during the analysis
	uptakeLim => string:Specifies limits on uptake of various atoms. For example 'C:1;S:5'
	options => string:list of optional keywords that toggle the use of various additional constrains during the analysis
	fbajobdir => string:Set directory in which FBA problem output files will be stored
	savelp => string:User can choose to save the linear problem associated with the FBA run
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
checks model growth with a variety of specified knockouts and media conditions
=DESCRIPTION
This function is used simulate model growth for every combination of a specified set of media conditions and knockouts
=cut
sub fbasimulatekomedialist {
	my ($self,$args) = @_;
	my $results;
	my $output;
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			media => ["Complete"],
			ko => [["None"]],
			rxnKO => undef,
			geneKO => undef,
			drainRxn => undef,
			uptakeLim => undef,
			options => undef,
			fbajobdir => undef,
			savelp => 0
		});
		my $medias = $args->{media};
		my $kos = $args->{ko};
		my $labels = $args->{kolabel};
		if (!defined($labels)) {
			for (my $i=0; $i < @{$kos}; $i++) {
				$labels->[$i] = join(",",@{$kos->[$i]});
			}
		}
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($mdl)) {
			return {SUCCESS => 0,ERROR => "Model not valid ".$args->{model}};
		}
		my $input;
		for (my $i=0; $i < @{$kos}; $i++) {
			for (my $j=0; $j < @{$medias}; $j++) {
				push(@{$input->{labels}},$labels->[$i]."_".$medias->[$j]);
				push(@{$input->{mediaList}},$medias->[$j]);
				push(@{$input->{koList}},$kos->[$i]);
			}
		}
		$input->{fbaStartParameters} = {};
		$input->{findTightBounds} = 0;
		$input->{deleteNoncontributingRxn} = 0;
		$input->{identifyCriticalBiomassCpd} = 0;
		my $growthRates;
		my $result = $mdl->fbaMultiplePhenotypeStudy($input);
		foreach my $label (keys(%{$result})) {
			my $array = [split(/_/,$label)];
			$output->{$array->[0]}->{growth}->{$result->{$label}->{media}} = [$result->{$label}->{growth},$result->{$label}->{fraction}];
			$output->{$array->[0]}->{growth}->{$result->{$label}->{media}} = [$result->{$label}->{growth},$result->{$label}->{fraction}];
			$output->{$array->[0]}->{geneKO} = $result->{$label}->{geneKO};
			$output->{$array->[0]}->{rxnKO} = $result->{$label}->{rxnKO};
		}
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => "Sequence analysis successful!",
		RESULTS => $output
	};
}
=head
=NAME
fbacheckgrowth
=CATEGORY
Flux Balance Analysis Operations
=DEFINITION
Output = fbacheckgrowth({
	model => string:Full ID of the model to be analyzed,
	media => [string]:Name of the media condition in the Model SEED database in which the analysis should be performed. May also provide the name of a [[Media File]] in the workspace where media has been defined. This file MUST have a '.media' extension,
	rxnKO => [string]:delimited list of reactions to be knocked out during the analysis
	geneKO => [string]:delimited list of genes to be knocked out during the analysis
	drainRxn => [string]:list of reactions whose reactants will be added as drain fluxes in the model during the analysis
	uptakeLim => string:Specifies limits on uptake of various atoms. For example 'C:1;S:5'
	options => string:list of optional keywords that toggle the use of various additional constrains during the analysis
	fbajobdir => string:Set directory in which FBA problem output files will be stored
	savelp => string:User can choose to save the linear problem associated with the FBA run
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
tests if a model is growing under a specific media
=DESCRIPTION
This function is used to test if a model grows under a specific media, Complete media is used as default. Users can set the specific media to test model growth and set parameters for the FBA run. The FBA problem can be managed via optional parameters to set the problem directory and save the linear problem associated with the FBA run.
=cut
sub fbacheckgrowth {
    my ($self,$args) = @_;
	my $results;
	my $message = "";
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			media => "Complete",
			rxnKO => undef,
			geneKO => undef,
			drainRxn => undef,
			uptakeLim => undef,
			options => undef,
			fbajobdir => undef,
			savelp => 0
		});
		my $fbaStartParameters = ModelSEED::globals::GETFIGMODEL()->fba()->FBAStartParametersFromArguments({arguments => $args});
    	my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
    	if (!defined($mdl)) {
			return {SUCCESS => 0,ERROR => "Model ".$args->{model}." not found in database!"};
    	}
		my $results = $mdl->fbaCalculateGrowth({
        	fbaStartParameters => $fbaStartParameters,
        	problemDirectory => $fbaStartParameters->{filename},
        	saveLPfile => $args->{"save lp file"}
    	});
		if (!defined($results->{growth})) {
			return {SUCCESS => 0,ERROR => "FBA growth test of ".$args->{model}." failed!"};

		}
		if ($results->{growth} > 0.000001) {
			if (-e $results->{fbaObj}->directory()."/MFAOutput/SolutionReactionData.txt") {
				$results->{reactionFluxFile} = ModelSEED::utilities::LOADFILE($results->{fbaObj}->directory()."/MFAOutput/SolutionReactionData.txt");
				$results->{compoundFluxFile} = ModelSEED::utilities::LOADFILE($results->{fbaObj}->directory()."/MFAOutput/SolutionCompoundData.txt");
			}
			$message .= $args->{model}." grew in ".$args->{media}." media with rate:".$results->{growth}." gm biomass/gm CDW hr.\n"
		} else {
			$message .= $args->{model}." failed to grow in ".$args->{media}." media.\n";
			if (defined($results->{noGrowthCompounds}->[0])) {
				$message .= "Biomass compounds ".join(",",@{$results->{noGrowthCompounds}})." could not be generated!\n";
			}
		}
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};	
}
=head
=NAME
fbasingleko
=CATEGORY
Flux Balance Analysis Operations
=DEFINITION
Output = fbacheckgrowth({
	model => string:Full ID of the model to be analyzed,
	media => string:Name of the media condition in the Model SEED database in which the analysis should be performed,
	rxnKO => [string]:list of reactions to be knocked out during the analysis,
	geneKO => [string]:list of genes to be knocked out during the analysis,
	drainRxn => [string]:list of reactions whose reactants will be added as drain fluxes in the model during the analysis,
	uptakeLim => string:Specifies limits on uptake of various atoms. For example 'C:1;S:5',
	options => string:list of optional keywords that toggle the use of various additional constrains during the analysis,
	maxDeletions => string:A number specifying the maximum number of simultaneous knockouts to be simulated. We donot recommend specifying more than 2,
	savetodb => string:A FLAG that indicates that results should be saved to the database if set to '1'
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
simulate knockout of all combinations of one or more genes
=DESCRIPTION
This function is used to simulate the knockout of all combinations of one or more genes in a SEED metabolic model.
=cut
sub fbasingleko {
    my ($self,$args) = @_;
	my $results;
	my $message = "";
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			media => "Complete",
			rxnKO => undef,
			geneKO => undef,
			drainRxn => undef,
			uptakeLim => undef,
			options => "forcedGrowth",
			maxDeletions => 1,
			savetodb => 1
		});
		my $fbaStartParameters = ModelSEED::globals::GETFIGMODEL()->fba()->FBAStartParametersFromArguments({arguments => $args});
    	my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
    	if (!defined($mdl)) {
			return {SUCCESS => 0,ERROR => "Model ".$args->{model}." not found in database!"};
    	}
		$results = $mdl->fbaComboDeletions({
		   	maxDeletions => $args->{maxDeletions},
		   	fbaStartParameters => $fbaStartParameters,
			saveKOResults=>$args->{savetodb},
		});
		if (!defined($results) || !defined($results->{essentialGenes})) {
			return {SUCCESS => 0,ERROR => "Single gene knockout failed for ".$args->{model}." in ".$args->{media}." media."};
		}
		$message = "Successfully completed flux variability analysis of ".$args->{model}." in ".$args->{media};
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
fbaminimalmedia
=CATEGORY
Flux Balance Analysis Operations
=DEFINITION
Output = fbaminimalmedia({
	model => string:Full ID of the model to be analyzed,
	numsolutions => string:Indicates the number of alternative minimal media formulations that should be calculated,
	rxnKO => [string]:list of reactions to be knocked out during the analysis,
	geneKO => [string]:list of genes to be knocked out during the analysis,
	drainRxn => [string]:list of reactions whose reactants will be added as drain fluxes in the model during the analysis,
	uptakeLim => string:Specifies limits on uptake of various atoms. For example 'C:1;S:5',
	options => string:list of optional keywords that toggle the use of various additional constrains during the analysis,
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
calculates the minimal media for the specified model
=DESCRIPTION
This function utilizes flux balance analysis to calculate a minimal media for the specified model.
=cut
sub fbaminimalmedia {
	my ($self,$args) = @_;
	my $results;
	my $message = "";
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			numsolutions => 2,
			rxnKO => undef,
			geneKO => undef,
			drainRxn => undef,
			uptakeLim => undef,
			options => undef
		});
		my $fbaStartParameters = ModelSEED::globals::GETFIGMODEL()->fba()->FBAStartParametersFromArguments({arguments => $args});
	    my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
	    if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Model ".$args->{model}." not found in database!");
	    }
	    $results = $mdl->fbaCalculateMinimalMedia({
	    	fbaStartParameters => $fbaStartParameters,
	    	numsolutions => $args->{numsolutions}
	    });
	    if (defined($results->{essentialNutrients}) && defined($results->{optionalNutrientSets}->[0])) {
			$message .= "Minimal media formulation succesffully identified.\n";
			my $count = @{$results->{essentialNutrients}};
			my $output;
			my $line = "Essential nutrients (".$count."):";
			for (my $j=0; $j < @{$results->{essentialNutrients}}; $j++) {
				if ($j > 0) {
					$line .= ";";
				}
				my $cpd = $self->figmodel()->database()->get_object("compound",{id => $results->{essentialNutrients}->[$j]});
				$line .= $results->{essentialNutrients}->[$j]."(".$cpd->name().")";
			}
			push(@{$output},$line);
			for (my $i=0; $i < @{$results->{optionalNutrientSets}}; $i++) {
				my $count = @{$results->{optionalNutrientSets}->[$i]};
				$line = "Optional nutrients ".($i+1)." (".$count."):";
				for (my $j=0; $j < @{$results->{optionalNutrientSets}->[$i]}; $j++) {
					if ($j > 0) {
						$line .= ";";	
					}
					my $cpd = $self->figmodel()->database()->get_object("compound",{id => $results->{optionalNutrientSets}->[$i]->[$j]});
					$line .= $results->{optionalNutrientSets}->[$i]->[$j]."(".$cpd->name().")";
				}
				push(@{$output},$line);
			}
			$message .= join("\n",@{$output});
			$results->{minimalMediaResultsFile} = $output;
		}
	    if (defined($results->{minimalMedia})) {
	    	$results->{minimalMediaFile} = $results->{minimalMedia}->print();
	    }
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
fbafva
=CATEGORY
Flux Balance Analysis Operations
=DEFINITION
Output = fbafva({
	model => string:Full ID of the model to be analyzed,
	media => string(Complete):Name of the media condition in the Model SEED database in which the analysis should be performed. May also provide the name of a [[Media File]] in the workspace where media has been defined. This file MUST have a '.media' extension,
	rxnKO => [string](undef):A ',' delimited list of reactions to be knocked out during the analysis. May also provide the name of a [[Reaction List File]] in the workspace where reactions to be knocked out are listed. This file MUST have a '.lst' extension,
	geneKO => [string](undef):A ',' delimited list of genes to be knocked out during the analysis. May also provide the name of a [[Gene Knockout File]] in the workspace where genes to be knocked out are listed. This file MUST have a '.lst' extension,
	drainRxn => [string](undef):A ',' delimited list of reactions whose reactants will be added as drain fluxes in the model during the analysis. May also provide the name of a [[Reaction List File]] in the workspace where drain reactions are listed. This file MUST have a '.lst' extension,
	uptakeLim => string(undef):Specifies limits on uptake of various atoms. For example 'C:1;S:5',
	options => string(forcedGrowth):A ';' delimited list of optional keywords that toggle the use of various additional constrains during the analysis. See [[Flux Balance Analysis Options Documentation]]. There are three options specifically relevant to the FBAFVA function: (i) the 'forcegrowth' option indicates that biomass must be greater than 10% of the optimal value in all flux distributions explored, (ii) 'nogrowth' means biomass is constrained to zero, and (iii) 'freegrowth' means biomass is left unconstrained,
	variables => string(FLUX;UPTAKE):A ';' delimited list of the variables that should be explored during the flux variability analysis. See [[List and Description of Variables Types used in Model SEED Flux Balance Analysis]],
	savetodb => 0/1(0):If set to '1', this flag indicates that the results of the fva should be preserved in the Model SEED database associated with the indicated metabolic model. Database storage of results is necessary for results to appear in the Model SEED web interface,
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
performs FVA (Flux Variability Analysis) studies
=DESCRIPTION
This function performs FVA analysis, calculating minimal and maximal flux through the reactions (range of fluxes) consistent with maximal theoretical growth rate
=cut

sub fbafva {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			media => "Complete",
			rxnKO => undef,
			geneKO => undef,
			drainRxn => undef,
			uptakeLim => undef,
			options => "forcedGrowth",
			variables => "FLUX;UPTAKE",
			savetodb => 0,
		});
		my $fbaStartParameters = ModelSEED::globals::GETFIGMODEL()->fba()->FBAStartParametersFromArguments({arguments => $args});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
	    if (!defined($mdl)) {
	      ModelSEED::utilities::ERROR("Model ".$args->{model}." not found in database!");
	    }
		if (!defined($fbaStartParameters->{options}->{forceGrowth})
	   		&& !defined($fbaStartParameters->{options}->{nogrowth}) 
	   		&& !defined($fbaStartParameters->{options}->{freeGrowth})) {
	   		$fbaStartParameters->{options}->{forceGrowth} = 1;
	   	}
	    $args->{variables} = [split(/\;/,$args->{variables})];
	    my $results = $mdl->fbaFVA({
		   	variables => $args->{variables},
		   	fbaStartParameters => $fbaStartParameters,
			saveFVAResults=>$args->{savetodb},
		});
		if (!defined($results) || defined($results->{error})) {
			ModelSEED::utilities::ERROR("Flux variability analysis failed for ".$args->{model}." in ".$args->{media}.".");
		}
		my $rxntbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["Reaction","Compartment"],undef,["Reaction"],";","|");
		my $cpdtbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["Compound","Compartment"],$self->ws()->directory()."Compounds-".$args->{filename}.".txt",["Compound"],";","|");
		my $varAssoc = {
			FLUX => "reaction",
			DELTAG => "reaction",
			SDELTAG => "reaction",
			UPTAKE => "compound",
			SDELTAGF => "compound",
			POTENTIAL => "compound",
			CONC => "compound"
		};
		my $varHeading = {
			FLUX => "",
			DELTAG => " DELTAG",
			SDELTAG => " SDELTAG",
			UPTAKE => "",
			SDELTAGF => " SDELTAGF",
			POTENTIAL => " POTENTIAL",
			CONC => " CONC"
		};
		for (my $i=0; $i < @{$args->{variables}}; $i++) {
			if (defined($varAssoc->{$args->{variables}->[$i]})) {
				if ($varAssoc->{$args->{variables}->[$i]} eq "compound") {
					$cpdtbl->add_headings(("Min ".$args->{variables}->[$i],"Max ".$args->{variables}->[$i]));
					if ($args->{variables}->[$i] eq "UPTAKE") {
						$cpdtbl->add_headings(("Class"));
					}
				} elsif ($varAssoc->{$args->{variables}->[$i]} eq "reaction") {
					$rxntbl->add_headings(("Min ".$args->{variables}->[$i],"Max ".$args->{variables}->[$i]));
					if ($args->{variables}->[$i] eq "FLUX") {
						$rxntbl->add_headings(("Class"));
					}
				}
			}
		}
		foreach my $obj (keys(%{$results->{tb}})) {
			my $newRow;
			if ($obj =~ m/([rb][xi][no]\d+)(\[[[a-z]+\])*/) {
				$newRow->{"Reaction"} = [$1];
				my $compartment = $2;
				if (!defined($compartment) || $compartment eq "") {
					$compartment = "c";
				}
				$newRow->{"Compartment"} = [$compartment];
				#$newRow->{"Direction"} = [$rxnObj->directionality()];
				#$newRow->{"Associated peg"} = [split(/\|/,$rxnObj->pegs())];
				for (my $i=0; $i < @{$args->{variables}}; $i++) {
					if ($varAssoc->{$args->{variables}->[$i]} eq "reaction") {
						if (defined($results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}})) {
							$newRow->{"Min ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}};
							$newRow->{"Max ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"max".$varHeading->{$args->{variables}->[$i]}};
							if ($args->{variables}->[$i] eq "FLUX") {
								$newRow->{Class}->[0] = $results->{tb}->{$obj}->{class};
							}
						}
					}
				}
				#print Data::Dumper->Dump([$newRow]);
				$rxntbl->add_row($newRow);
			} elsif ($obj =~ m/(cpd\d+)(\[[[a-z]+\])*/) {
				$newRow->{"Compound"} = [$1];
				my $compartment = $2;
				if (!defined($compartment) || $compartment eq "") {
					$compartment = "c";
				}
				$newRow->{"Compartment"} = [$compartment];
				for (my $i=0; $i < @{$args->{variables}}; $i++) {
					if ($varAssoc->{$args->{variables}->[$i]} eq "compound") {
						if (defined($results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}})) {
							$newRow->{"Min ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}};
							$newRow->{"Max ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"max".$varHeading->{$args->{variables}->[$i]}};
							if ($args->{variables}->[$i] eq "FLUX") {
								$newRow->{Class}->[0] = $results->{tb}->{$obj}->{class};
							}
						}
					}
				}
				$cpdtbl->add_row($newRow);
			}
		}
    	$results->{compoundTable} = $cpdtbl;
    	$results->{reactionTable} = $rxntbl;
		push(@{$message},"Successfully completed flux variability analysis of ".$args->{biomass}." in ".$args->{media}.".");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
fbafvabiomass
=CATEGORY
Flux Balance Analysis Operations
=DEFINITION
Output = fbafvabiomass({
	biomass => string:ID of biomass reaction to be analyzed,
	media => string(Complete):Name of the media condition in the Model SEED database in which the analysis should be performed. May also provide the name of a [[Media File]] in the workspace where media has been defined. This file MUST have a '.media' extension,
	rxnKO => [string](undef):A ',' delimited list of reactions to be knocked out during the analysis. May also provide the name of a [[Reaction List File]] in the workspace where reactions to be knocked out are listed. This file MUST have a '.lst' extension,
	geneKO => [string](undef):A ',' delimited list of genes to be knocked out during the analysis. May also provide the name of a [[Gene Knockout File]] in the workspace where genes to be knocked out are listed. This file MUST have a '.lst' extension,
	drainRxn => [string](undef):A ',' delimited list of reactions whose reactants will be added as drain fluxes in the model during the analysis. May also provide the name of a [[Reaction List File]] in the workspace where drain reactions are listed. This file MUST have a '.lst' extension,
	uptakeLim => string(undef):Specifies limits on uptake of various atoms. For example 'C:1;S:5',
	options => string(forcedGrowth):A ';' delimited list of optional keywords that toggle the use of various additional constrains during the analysis. See [[Flux Balance Analysis Options Documentation]]. There are three options specifically relevant to the FBAFVA function: (i) the 'forcegrowth' option indicates that biomass must be greater than 10% of the optimal value in all flux distributions explored, (ii) 'nogrowth' means biomass is constrained to zero, and (iii) 'freegrowth' means biomass is left unconstrained,
	variables => string(FLUX;UPTAKE):A ';' delimited list of the variables that should be explored during the flux variability analysis. See [[List and Description of Variables Types used in Model SEED Flux Balance Analysis]],
	savetodb => 0/1(0):If set to '1', this flag indicates that the results of the fva should be preserved in the Model SEED database associated with the indicated metabolic model. Database storage of results is necessary for results to appear in the Model SEED web interface,
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
performs FVA (Flux Variability Analysis) study of entire database
=DESCRIPTION
This function performs FVA analysis, calculating minimal and maximal flux through all reactions in the database subject to the specified biomass reaction
=cut
sub fbafvabiomass {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["biomass"],{
			media => "Complete",
			rxnKO => undef,
			geneKO => undef,
			drainRxn => undef,
			uptakeLim => undef,
			options => "forcedGrowth",
			variables => "FLUX;UPTAKE",
			savetodb => 0,
		});
		my $fbaStartParameters = ModelSEED::globals::GETFIGMODEL()->fba()->FBAStartParametersFromArguments({arguments => $args});
		my $rxn = ModelSEED::globals::GETFIGMODEL()->get_reaction($args->{biomass});
	    if (!defined($rxn)) {
	      ModelSEED::utilities::ERROR("Reaction ".$args->{biomass}." not found in database!");
	    }
	    $fbaStartParameters->{options}->{forceGrowth} = 1;
	    $args->{variables} = [split(/\;/,$args->{variables})];
	    my $results = $rxn->determine_coupled_reactions({
	    	variables => $args->{variables},
			fbaStartParameters => $fbaStartParameters,
		   	saveFVAResults => $args->{savetodb}
		});
		if (!defined($results->{tb})) {
			ModelSEED::utilities::ERROR("Flux variability analysis failed for ".$args->{biomass}." in ".$args->{media}.".");
		}
		my $rxntbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["Reaction","Compartment"],$self->ws()->directory()."Reactions-".$args->{filename}.".txt",["Reaction"],";","|");
		my $cpdtbl = ModelSEED::FIGMODEL::FIGMODELTable->new(["Compound","Compartment"],$self->ws()->directory()."Compounds-".$args->{filename}.".txt",["Compound"],";","|");
		my $varAssoc = {
			FLUX => "reaction",
			DELTAG => "reaction",
			SDELTAG => "reaction",
			UPTAKE => "compound",
			SDELTAGF => "compound",
			POTENTIAL => "compound",
			CONC => "compound"
		};
		my $varHeading = {
			FLUX => "",
			DELTAG => " DELTAG",
			SDELTAG => " SDELTAG",
			UPTAKE => "",
			SDELTAGF => " SDELTAGF",
			POTENTIAL => " POTENTIAL",
			CONC => " CONC"
		};
		for (my $i=0; $i < @{$args->{variables}}; $i++) {
			if (defined($varAssoc->{$args->{variables}->[$i]})) {
				if ($varAssoc->{$args->{variables}->[$i]} eq "compound") {
					$cpdtbl->add_headings(("Min ".$args->{variables}->[$i],"Max ".$args->{variables}->[$i]));
					if ($args->{variables}->[$i] eq "UPTAKE") {
						$cpdtbl->add_headings(("Class"));
					}
				} elsif ($varAssoc->{$args->{variables}->[$i]} eq "reaction") {
					$rxntbl->add_headings(("Min ".$args->{variables}->[$i],"Max ".$args->{variables}->[$i]));
					if ($args->{variables}->[$i] eq "FLUX") {
						$rxntbl->add_headings(("Class"));
					}
				}
			}
		}
		foreach my $obj (keys(%{$results->{tb}})) {
			my $newRow;
			if ($obj =~ m/([rb][xi][no]\d+)(\[[[a-z]+\])*/) {
				$newRow->{"Reaction"} = [$1];
				my $compartment = $2;
				if (!defined($compartment) || $compartment eq "") {
					$compartment = "c";
				}
				$newRow->{"Compartment"} = [$compartment];
				#$newRow->{"Direction"} = [$rxnObj->directionality()];
				#$newRow->{"Associated peg"} = [split(/\|/,$rxnObj->pegs())];
				for (my $i=0; $i < @{$args->{variables}}; $i++) {
					if ($varAssoc->{$args->{variables}->[$i]} eq "reaction") {
						if (defined($results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}})) {
							$newRow->{"Min ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}};
							$newRow->{"Max ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"max".$varHeading->{$args->{variables}->[$i]}};
							if ($args->{variables}->[$i] eq "FLUX") {
								$newRow->{Class}->[0] = $results->{tb}->{$obj}->{class};
							}
						}
					}
				}
				#print Data::Dumper->Dump([$newRow]);
				$rxntbl->add_row($newRow);
			} elsif ($obj =~ m/(cpd\d+)(\[[[a-z]+\])*/) {
				$newRow->{"Compound"} = [$1];
				my $compartment = $2;
				if (!defined($compartment) || $compartment eq "") {
					$compartment = "c";
				}
				$newRow->{"Compartment"} = [$compartment];
				for (my $i=0; $i < @{$args->{variables}}; $i++) {
					if ($varAssoc->{$args->{variables}->[$i]} eq "compound") {
						if (defined($results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}})) {
							$newRow->{"Min ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"min".$varHeading->{$args->{variables}->[$i]}};
							$newRow->{"Max ".$args->{variables}->[$i]}->[0] = $results->{tb}->{$obj}->{"max".$varHeading->{$args->{variables}->[$i]}};
							if ($args->{variables}->[$i] eq "FLUX") {
								$newRow->{Class}->[0] = $results->{tb}->{$obj}->{class};
							}
						}
					}
				}
				$cpdtbl->add_row($newRow);
			}
		}
    	$results->{compoundTable} = $cpdtbl;
    	$results->{reactionTable} = $rxntbl;
		push(@{$message},"Successfully completed flux variability analysis of ".$args->{biomass}." in ".$args->{media}.".");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
bcprintmedia
=CATEGORY
Biochemistry Operations
=DEFINITION
Output = bcprintmediatable({
	medias => [string]:list of media formulations to be compared
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
print table of media formulations for comparison
=DESCRIPTION
This function is used to print a table of the compounds across multiple media conditions
=cut
sub bcprintmediatable {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["medias"],{});
    	my $mediaHash = ModelSEED::globals::GETFIGMODEL()->database()->get_object_hash({
			type => "mediacpd",
			attribute => "MEDIA",
			parameters => {}
		});
		for (my $i=0; $i < @{$args->{medias}}; $i++) {
			if (defined($mediaHash->{$args->{medias}->[$i]})) {
				for (my $j=0; $j < @{$mediaHash->{$args->{medias}->[$i]}}; $j++) {
					if ($mediaHash->{$args->{medias}->[$i]}->[$j]->maxFlux() > 0 && $mediaHash->{$args->{medias}->[$i]}->[$j]->type() eq "COMPOUND") {
						$results->{mediaCompoundTable}->{$mediaHash->{$args->{medias}->[$i]}->[$j]->entity()}->{$args->{medias}->[$i]} = $mediaHash->{$args->{medias}->[$i]}->[$j]->maxFlux();
					}
				}
			}
		}
		push(@{$message},"Media data successfully loaded into table");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
bcprintmedia
=CATEGORY
Biochemistry Operations
=DEFINITION
Output = bcprintmedia({
	media => string:Name of the media formulation to be printed,
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
print Model SEED media formulation
=DESCRIPTION
This function is used to print a media formulation to the current workspace.
=cut
sub bcprintmedia {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["media"],{});
    	my $media = ModelSEED::globals::GETFIGMODEL()->database()->get_moose_object("media",{id => $args->{media}});
		if (!defined($media)) {
			ModelSEED::utilities::ERROR("Media not valid ".$args->{media});
		}
		$results->{mediaFile} = $media->print();
		push(@{$message},"Successfully retrieved media '".$args->{media}."' from database!!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
bcloadmedia
=CATEGORY
Biochemistry Operations
=DEFINITION
Output = bcloadmedia({
	media => string:The name of the media formulation being created or altered,
	mediaFile => [string]:File with media specifications
	public => 0/1(0):Set directory in which FBA problem output files will be stored,
	owner => string(logged user):Login of the user account who will own this media condition,
	overwrite => 0/1(0):If you set this parameter to '1', any existing media with the same input name will be overwritten
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
Creates (or alters) a media condition in the Model SEED database
=DESCRIPTION
This function is used to create or alter a media condition in the Model SEED database given either a list of compounds in the media or a file specifying the media compounds and minimum and maximum uptake rates.
=cut
sub bcloadmedia {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["media","mediaFile"],{
			public => 0,
			owner => ModelSEED::globals::GETFIGMODEL()->user(),
			overwrite => 0
		});
    	my $media = ModelSEED::globals::GETFIGMODEL()->database()->create_moose_object("media",{db => ModelSEED::globals::GETFIGMODEL()->database(),filedata => $args->{mediaFile}});
		$media->syncWithPPODB({overwrite => $args->{overwrite}});
		$results->{mediaID} = $media->id();
		push(@{$message},"Successfully loaded media ".$args->{media}." to database as ".$media->id());
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlreconstruction
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlautocomplete({
	model => string:ID of the model to be gapfilled
	media => string(Complete):The media condition the model will be gapfilled in
	removegapfilling => 0/1(1):All existing gapfilled reactions in the model will be deleted prior to the new gapfilling if this flag is set to '1'
	inactivecoef => 0/1(0):The coefficient on the inactive reactions in the gapfilling objective function
	adddrains => 0/1(0):Drain fluxes will be added for all intracellular metabolites and minimized if this flag is set to '1'
	iterative => 0/1(0):All inactive reactions in the model will be identified, and they will be iteratively gapfilled one at a time if this flag is set to '1'
	testsolution => 0/1(0):Set this FLAG to '1' in order to test the gapfilling solution to assess the reason for addition of each gapfilled solution
	printdbmessage => 0/1(0):Set this FLAG to '1' in order to print a message about gapfilling results to the database
	coefficientfile => string(undef):Name of a flat file specifying coefficients for gapfilled reactions in objective function
	rungapfilling => 0/1(1):The gapfilling will not be run unless you set this flag to '1'
	problemdirectory => string(undef):The name of the job directory where the intermediate gapfilling output will be stored
	startfresh => 0/1(1):Any files from previous gapfilling runs in the same output directory will be deleted if this flag is set to '1'
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
adds reactions to the model to eliminate inactive reactions
=DESCRIPTION
This function is used to add a minimal number of reactions to a model from the biochemistry database such that one or more inactive reactions is eliminated.
=cut
sub mdlautocomplete {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			media => "Complete",
			removegapfilling => 1,
			inactivecoef => 0,
			adddrains => 0,
			iterative => 0,
			testsolution => 0,
			printdbmessage => 0,
			coefficientfile => undef,
			rungapfilling => 1,
			problemdirectory => undef,
			startfresh => 1
		});
		my $mdl =  ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
	    if (!defined($mdl)) {
	    	ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
	    }
	    $results = $mdl->completeGapfilling({
			startFresh => $args->{startfresh},
			problemDirectory => $args->{problemdirectory},
			rungapfilling=> $args->{rungapfilling},
			removeGapfillingFromModel => $args->{removegapfilling},
			gapfillCoefficientsFile => $args->{coefficientfile},
			inactiveReactionBonus => $args->{inactivecoef},
			fbaStartParameters => {
				media => $args->{"media"}
			},
			iterative => $args->{iterative},
			adddrains => $args->{adddrains},
			testsolution => $args->{testsolution},
			globalmessage => $args->{printdbmessage}
		});
		push(@{$message},"Successfully gapfilled model ".$args->{model}." in ".$args->{media}." media!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlreconstruction
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlreconstruction({
	model => string:name of the model to be reconstructed
	autocompletion => 0/1(0):flag indicating if autocompletion should be run
	checkpoint => 0/1(0):flag indicating if model should be checked in prior to the reconstruction process so the current model will be preserved
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
run model reconstruction from genome annotations
=DESCRIPTION
This command uses the Model SEED pipeline to reconstruct an existing SEED model from scratch based on SEED genome annotations.
=cut
sub mdlreconstruction {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			autocompletion => 0,
			checkpoint => 0
		});
		my $mdl =  ModelSEED::globals::GETFIGMODEL()->get_model($args->{"model"});
	    if (!defined($mdl)) {
	    	ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
	    }
		$mdl->reconstruction({
	    	checkpoint => $args->{"checkpoint"},
			autocompletion => $args->{"autocompletion"},
		});
		push(@{$message},"Successfully generated model ".$args->{model}." from genome annotations");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlmakedbmodel
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlmakedbmodel({
	model => string:The name of the model that will contain all the database reactions.
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
construct a model with all database reactions
=DESCRIPTION
This function creates a model that includes all reactions in the current database. Such a model is useful to determine the capabilities of the current biochemistry database.
=cut
sub mdlmakedbmodel {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{});
		my $mdl =  ModelSEED::globals::GETFIGMODEL()->get_model($args->{"model"});
	    if (!defined($mdl)) {
	    	ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
	    }
		$mdl->generate_fulldb_model();
		push(@{$message},"Set model reaction list to entire biochemistry database");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdladdright
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdladdright({
	model => string:ID of the model for which rights should be added
	user => string:Login of the user account for which rights should be added
	right => string(view):Type of right that should be added. Possibilities include 'view' and 'admin'
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
add rights to a model to another user
=DESCRIPTION
This function is used to provide rights to view or edit a model to another Model SEED user. Use this function to share a model.
=cut
sub mdladdright {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model","user"],{
			right => "view"
		});
		my $mdl =  ModelSEED::globals::GETFIGMODEL()->get_model($args->{"model"});
	    if (!defined($mdl)) {
	    	ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
	    }
		$mdl->changeRight({
	    	permission => $args->{right},
			username => $args->{user},
			force => 1
	    });
		push(@{$message},"Successfully added ".$args->{right}." rights for user ".$args->{user}." to model ".$args->{model}."!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlcreatemodel
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlcreatemodel({
	genome => string:genome for which model will be created
	id => string(undef):ID that the new model should have in the Model SEED database
	biomass => string(undef):ID of the biomass reaction the new model should have in the Model SEED database
	owner => string(Logged in user):The login of the user account that should own the new model
	biochemSource => string(undef):Name of model with biochemistry that should be utilized for new model
	reconstruction => string(1):Set this FLAG to '1' to autoatically run the reconstruction algorithm on the new model as soon as it is created
	autocompletion => string(0):Set this FLAG to '1' to autoatically run the autocompletion algorithm on the new model as soon as it is created
	overwrite => string(0):Set this FLAG to '1' to overwrite any model that has the same specified ID in the database
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
create new Model SEED models
=DESCRIPTION
This function is used to create new models in the Model SEED database.
=cut
sub mdlcreatemodel {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["genome"],{
			id => undef,
			biomass => undef,
			owner => ModelSEED::globals::GETFIGMODEL()->user(),
			biochemSource => undef,
			reconstruction => 1,
			autocompletion => 0,
			overwrite => 0
		});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->create_model({
			genome => $args->{genome},
			id => $args->{id},
			owner => $args->{owner},
			biochemSource => $args->{"biochemSource"},
			biomassReaction => $args->{"biomass"},
			reconstruction => $args->{"reconstruction"},
			autocompletion => $args->{"autocompletion"},
			overwrite => $args->{"overwrite"}
		});
		if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Failed to create model ".$args->{id}."!");	
		}
		push(@{$message},"Successfully created model ".$mdl->id()."!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlinspectstate
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlinspectstate({
	model => string:ID of model to be inspected
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
inspect that model consistency with biochemistry database
=DESCRIPTION
Inspects that the specified model(s) are consistent with their associated biochemistry databases", and modifies the database if not.
=cut
sub mdlinspectstate {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
		}
		$results = $mdl->InspectModelState({});
		push(@{$message},"Successfully inspected model ".$args->{model}."!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlprintsbml
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlprintsbml({
	model => string:Model for which SBML files should be printed
	media => string(Complete):ID of a media condition or media file for which SBML should be printed
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
prints model(s) in SBML format
=DESCRIPTION
Prints the specified model(s) in SBML format.
=cut
sub mdlprintsbml {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			media => "Complete"
		});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
		}
		if (ref($args->{media}) eq "HASH") {
			$args->{media} = ModelSEED::MooseDB::media->new({
				filedata => $args->{media}->{filedata}
			});
		}
		$args->{sbmlfile} = $mdl->PrintSBMLFile({
		 	media => $args->{media}
		});
		push(@{$message},"Successfully printed model SBML in ".$args->{media}." media!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlprintmodel
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlprintmodel({
	model => string:The full Model SEED ID of the model to be printed
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
prints a model to flatfile for alteration and reloading
=DESCRIPTION
This is a useful function for printing model data to simple flatfiles that may be easily altered to facilitate hand-curation of a model. The function accepts a model ID as input, and it creates two flat files for the specified model: 
* a reaction table file that lists the id, directionality,
* a biomass reaction file that lists the equation of the biomass reaction
By default, the flatfiles are printed in the "Model-SEED-core/data/MSModelFiles/" directory, but you can specify where the files will be printed using the "filename" and "biomassFilename" input arguments.
NOTE: currently this function is the only mechanism for moving models from the Central Model SEED database into a local Model SEED database. This will soon change.
=cut
sub mdlprintmodel {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
		}
		$results->{modelfile} = $mdl->printModelFileForMFAToolkit({
			filename => "ARRAY"
		});
		$results->{biomassID} = $mdl->biomassReaction();
		if( defined($results->{biomassID}) && $results->{biomassID} ne "NONE"){
			my $biomass = ModelSEED::globals::GETFIGMODEL()->get_reaction($results->{biomassID});
			if (defined($biomass)) {
				$results->{biomassEquation} = $biomass->ppo()->equation();
			}
		} else {
			delete $results->{biomassID};
		}
		push(@{$message},"Successfully retreived data for model ".$args->{model}."!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlprintcytoseed
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlprintcytoseed({
	model => string:The full Model SEED ID of the model to be printed
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
prints a model to format expected by CytoSEED
=DESCRIPTION
This is a useful function for printing model data to the flatfiles that are used by CytoSEED. The function accepts a model ID as input, and it creates a directory using the model id that contains model data in the format expected by CytoSEED.
By default, the model is printed in the "Model-SEED-core/data/MSModelFiles/" directory, but you can specify where the model will be printed using the "directory" input argument. You should print or copy the model data to the CytoSEED/Models folder (see "Set Location of CytoSEED Folder" menu item under "Plugins->SEED" in Cytoscape).
=cut
sub mdlprintcytoseed {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
		}
		my $fbaObj = ModelSEED::ServerBackends::FBAMODEL->new();
		my $md = $fbaObj->get_model_data({ "id" => [$args->{model}] });
		$results->{modeldata} = $md->{$args->{model}};
		$results->{biomassdata} = $fbaObj->get_biomass_reaction_data({ model => [$args->{model}] });
		my $cids = $fbaObj->get_compound_id_list({ "id" => [$args->{model}] });
		$results->{compounddata} = $fbaObj->get_compound_data({ id => $cids->{$args->{model}} });
		my @abcids = map { exists $cids->{$_}->{"ABSTRACT COMPOUND"} ? $cids->{$_}->{"ABSTRACT COMPOUND"}->[0] : undef } keys %$cids;
		$results->{abstractcompounddata} = $fbaObj->get_compound_data({ "id" => \@abcids });
		my $rids = $fbaObj->get_reaction_id_list({ "id" => [$args->{model}] });
		$results->{reactiondata} = $fbaObj->get_reaction_data({ "id" => $rids->{$args->{model}}, "model" => [$args->{model}] });
		my @abrids = map { exists $rids->{$_}->{"ABSTRACT REACTION"} ? $rids->{$_}->{"ABSTRACT REACTION"}->[0] : undef } keys %$rids;
		$results->{abstractreactiondata} = $fbaObj->get_reaction_data({ "id" => \@abrids, "model" => [$args->{model}] });
		$results->{reactionclassifications} = $fbaObj->get_model_reaction_classification_table({ "model" => [$args->{model}] });
		push(@{$message},"Successfully retreived data for model ".$args->{model}."!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlprintmodelgenes
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlprintmodelgenes({
	model => string:ID of the model for which genes will be printed
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
print all genes in model
=DESCRIPTION
This function prints a list of all genes included in the specified model to a file in the workspace.
=cut
sub mdlprintmodelgenes {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{});
		my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($mdl)) {
			ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
		}
		my $ftrHash = $mdl->featureHash();
		$results->{geneList} = [keys(%{$ftrHash})];
		push(@{$message},"Successfully retreived gene list for ".$args->{model}."!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlloadmodel
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlloadmodel({
	model => string:ID of the model to be loaded (DO append your user index!)
	modelfiledata => string(undef):Array containing the lines of the model reaction table
	genome => string(NONE):The SEED genome ID associated with the model to be loaded
	biomassid => string(NONE):ID of the biomass reaction to be loaded into the model
	biomassEquation => string(NONE):Stoichiometric equation for the biomass reaction to be loaded into the model
	owner => string(Your login):The login name of the user that should own the loaded model
	biochemSource => string(undef):Name of the model whose biochem database should be copied with this new model. If not provided, the Model SEED will generate a new provenance database from scratch using current system data.
	overwrite => string(0):If you are attempting to load a model that already exists in the database, you MUST set this argument to '1'.
	public => string(0):If you want the loaded model to be publicly viewable to all Model SEED users, you MUST set this argument to '1'.
	autoCompleteMedia => string(Complete):Name of the media used for auto-completing this model.
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
reload a model from a flatfile
=DESCRIPTION
This function is used to load a model reaction table and biomass reaction back into a Model SEED database. At least the model base ID and genome ID must be provided. If no filenames are provided, the system assumes the files are located in the following locations:
* Model reaction table: Model-SEED-core/data/MSModelFiles/''Model ID''.tbl [[Example model file]]
* Biomass reaction file: Model-SEED-core/data/MSModelFiles/''Model Biomass reaction ID''.txt [[Example biomass file]]
This function is designed to be used in conjunction with ''printmodelfiles'' to print model data to flatfiles, allow hand-curation of these flatfiles, and then load model data back into the Model SEED from these flatfiles.
=cut
sub mdlloadmodel {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model","modelfiledata"],{
			genome => "NONE",
			biomassid => undef,
			biomassEquation => undef,
			owner => ModelSEED::globals::GETFIGMODEL()->user(),
			biochemSource => undef,
			overwrite => 0,
			public => 0,
			autoCompleteMedia => "Complete"
		});
		my $modelObj = ModelSEED::globals::GETFIGMODEL()->import_model_file({
			id => $args->{"model"},
			genome => $args->{"genome"},
			modelfiledata => $args->{"modelfiledata"},
			biomassID => $args->{"biomassid"},
			biomassEquation => $args->{"biomassEquation"},
			owner => $args->{"owner"},
			public => $args->{"public"},
			overwrite => $args->{"overwrite"},
			biochemSource => $args->{"biochemSource"},
			autoCompleteMedia => $args->{"autoCompleteMedia"}
		});
		if (defined($modelObj)) {
			push(@{$message},"Successfully imported ".$args->{model}." into Model SEED as ".$modelObj->id()."!");
		}
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlchangedrains
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlchangedrains({
	model => string:ID of the model the drains are to be added to
	drains => string(undef):; delimited list of compounds for which drains should be added
	inputs => string(undef):; delimited list of compounds for which inputs should be added
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
change drain fluxes associated with model
=DESCRIPTION
This function changes the drain fluxes associated with a model.
=cut
sub mdlchangedrains {	
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["model"],{
			drains => undef,
			inputs => undef
		});
		my $model = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
		if (!defined($model)) {
			ModelSEED::utilities::ERROR("Model not valid ".$args->{model});
		}
		if (defined($args->{drains})) {
			$args->{drains} = ModelSEED::globals::PROCESSIDLIST({
				input => $args->{drains},
				validation => "^cpd\\d+\\[*\\w*\\]*\$"
			});
		}
		if (defined($args->{inputs})) {
			$args->{inputs} = ModelSEED::globals::PROCESSIDLIST({
				input => $args->{inputs},
				validation => "^cpd\\d+\\[*\\w*\\]*\$"
			});
		}
		my $string = $model->changeDrains({
			drains => $args->{drains},
			inputs => $args->{inputs},
		});
		push(@{$message},"Successfully adjusted the drain fluxes associated with model ".$args->{model}." to ".$string);
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlloadbiomass
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlloadbiomass({
	biomassid => string:ID of the biomass reaction to be loaded
	equation => string(undef):stoichiometric equation for biomass reaction
	model => string(undef):ID of the model to which the biomass reaction will be associated
	overwrite => 0/1(0):If you are attempting to alter and existing biomass reaction, you MUST set this argument to '1'
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
Loads a model biomass reaction into the database from a flatfile
=DESCRIPTION
This function creates (or alters) a biomass reaction in the Model SEED database given an input file or biomass ID that points to an input file.
=cut
sub mdlloadbiomass {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["biomassid"],{
			equation => undef,
			model => undef,
			overwrite => 0
		});
		my $bio = ModelSEED::globals::GETFIGMODEL()->database()->get_object("bof",{id => $args->{biomassid}});
		if (!defined($bio) && !defined($args->{equation})) {
			ModelSEED::utilities::ERROR("Biomass ".$args->{biomassid}." not found, and no equation was supplied. Nothing could be done.");
		}
		if (defined($bio)) {
			if ($args->{overwrite} == 0) {
				push(@{$message},"Biomass reaction ".$args->{biomassid}." exists, and overwrite parameter not set. The biomass equation not modified.");
			} else {
				if ($bio->equation() ne $args->{equation}) {
					push(@{$message},"Equation for biomass reaction ".$args->{biomassid}." modified!");
					my $bofobj = ModelSEED::globals::GETFIGMODEL()->get_reaction()->add_biomass_reaction_from_equation({
						equation => $args->{equation},
						biomassID => $args->{biomassid}
					});
				}
			}
		} else {
			my $bofobj = ModelSEED::globals::GETFIGMODEL()->get_reaction()->add_biomass_reaction_from_equation({
				equation => $args->{equation},
				biomassID => $args->{biomassid}
			});
			push(@{$message},"New biomass reaction ".$args->{biomassid}." created!");
		}
		if (defined($args->{model})) {
			my $mdl = ModelSEED::globals::GETFIGMODEL()->get_model($args->{model});
			ModelSEED::utilities::ERROR("Model ".$args->{model}." not found in database!") if (!defined($mdl));
			$mdl->biomassReaction($args->{biomassid});
			push(@{$message},"Successfully changed biomass reaction in model ".$args->{model}.".");
		}
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlparsesbml
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlparsesbml({
	filedata => [string]:array containing the lines of the SBML file to be parsed
});
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
parsing SBML file into compound and reaction tables
=DESCRIPTION
This function parses the input SBML file into compound and reaction tables needed for import into the Model SEED
=cut
sub mdlparsesbml {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["filedata"],{});
		$results = ModelSEED::globals::GETFIGMODEL()->parseSBMLToTable({filedata => $args->{filedata}});
		if (defined($results->{SUCCESS})) {
			delete $results->{SUCCESS};
			push(@{$message},"SBML file successfully parsed into table!");
		}
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
mdlimportmodel
=CATEGORY
Metabolic Model Operations
=DEFINITION
Output = mdlimportmodel({
	name => string:The ID in the Model SEED that the imported model should have, or the ID of the model to be overwritten by the imported model,
	compoundTable => FIGMODELTable:table of compounds in the imported model
	reactionTable => FIGMODELTable:table of reactions in the imported model
	genome => string:SEED ID of the genome the imported model should be associated with,
	owner => string:Name of the user account that will own the imported model,
	overwrite => 0/1:Set this FLAG to '1' to overwrite an existing model with the same name,
	biochemsource => string:The path to the directory where the biochemistry database that the model should be imported into is located,
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
import a model into the Model SEED environment
=DESCRIPTION
Imports a models from other databases into the Model SEED environment.
=cut
sub mdlimportmodel {
    my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["name","compoundTable","reactionTable"],{
			genome => "NONE",
			owner => ModelSEED::globals::GETFIGMODEL()->user(),
			overwrite => 0,
			biochemsource => undef,
		});
		if (defined($args->{biochemsource})) {
			ModelSEED::globals::VALIDATEINPUT({
				input => $args->{biochemsource},
				type => "model",
				name => "biochemsource",
			});
		}
		my $public = 0;
		if ($args->{"owner"} eq "master") {
			$public = 1;
		}
		$results = ModelSEED::globals::GETFIGMODEL()->import_model({
			baseid => $args->{"name"},
			genome => $args->{"genome"},
			owner => $args->{"owner"},
			compoundTable => $args->{compoundTable},
			reactionTable => $args->{reactionTable},
			public => $public,
			overwrite => $args->{"overwrite"},
			biochemSource => $args->{"biochemsource"}
		});
		if (defined($results->{SUCCESS})) {
			push(@{$message},"The model has been successfully imported as \"".$results->{"model ID"}."\"");
		}
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	};
}
=head
=NAME
utilmatrixdist
=CATEGORY
Utility Functions
=DEFINITION
Output = utilmatrixdist({
	matrix => [string]:numerical data you want to calculate the distribution of. Unless a full path is specified, file is assumed to be located in the current workspace,
	binsize => integer:Size of bins into which data should be distributed,
	startcol => integer:Column of the input data table where the numerical data begins,
	endcol => integer:Column of the input data table where the numerical data ends,
	startrow => integer:Row of the input data table where the numerical data begins,
	endrow => integer:Row of the input data table where the numerical data ends,
	delimiter => string:Delimiter used in the input data table,
})
Output: {
	ERROR => string,
	MESSAGE => string,
	SUCCESS => 1,
	RESULST => {}
}
=SHORT DESCRIPTION
binning numerical matrix data into a histogram
=DESCRIPTION
This function loads a table of numerical data from your workspace and determines how the data values are distributed into bins.
=cut
sub utilmatrixdist {
	my ($self,$args) = @_;
	my $results;
	my $message = [];
	try {
		$args = ModelSEED::utilities::ARGS($args,["matrix"],{
			binsize => 1,
			startcol => 1,
			endcol => undef,
			startrow => 1,
			endrow => undef,
			delimiter => "\\t"
		});
	    my $distribData;
	    my $data = $args->{matrix};
	    if (!defined($args->{endrow})) {
	    	$args->{endrow} = @{$data};
	    }
	    print "Calculating...\n";
	    #Calculating the distribution for each row as well as the overall distribution
	    my $moreRowData;
	    for (my $i=$args->{startrow}; $i < $args->{endrow}; $i++) {
	    	my $rowData = [split($args->{delimiter},$data->[$i])];
	    	$moreRowData->{$rowData->[0]} = {
	    		zeros => 0,
	    		average => 0,
	    		stddev => 0,
	    		instances => 0,
	    		maximum => 0
	    	};
	    	print "Processing row ".$i.":".$rowData->[0]."\n";
	    	if (!defined($args->{endcol})) {
		    	$args->{endcol} = @{$rowData};
		    }
	    	for (my $j=$args->{startcol}; $j < $args->{endcol}; $j++) {
	    		if ($rowData->[$j] =~ m/^\d+\.*\d*$/) {
	    			if ($rowData->[$j] > $moreRowData->{$rowData->[0]}->{maximum}) {
	    				$moreRowData->{$rowData->[0]}->{maximum} = $rowData->[$j];
	    			}
	    			if ($rowData->[$j] == 0) {
	    				$moreRowData->{$rowData->[0]}->{zeros}++;
	    			}
	    			$moreRowData->{$rowData->[0]}->{average} += $rowData->[$j];
	    			$moreRowData->{$rowData->[0]}->{instances}++;
	    			my $bin = ModelSEED::FIGMODEL::floor($rowData->[$j]/$args->{binsize});
	    			if (!defined($distribData->{$rowData->[0]}->[$bin])) {
	    				$distribData->{$rowData->[0]}->[$bin] = 0;
	    			}
	    			$distribData->{$rowData->[0]}->[$bin]++;
	    			if (!defined($distribData->{"total"}->[$bin])) {
	    				$distribData->{"total"}->[$bin] = 0;
	    			}
	    			$distribData->{"total"}->[$bin]++;
	    		}
	    	}
	    	if ($moreRowData->{$rowData->[0]}->{instances} != 0) {
	    		$moreRowData->{$rowData->[0]}->{average} = $moreRowData->{$rowData->[0]}->{average}/$moreRowData->{$rowData->[0]}->{instances};
	    	}
	    	for (my $j=$args->{startcol}; $j < $args->{endcol}; $j++) {
	    		if ($rowData->[$j] =~ m/^\d+\.*\d*$/) {
	    			$moreRowData->{$rowData->[0]}->{stddev} += ($rowData->[$j]-$moreRowData->{$rowData->[0]}->{average})*($rowData->[$j]-$moreRowData->{$rowData->[0]}->{average});		
	    		}
	    	}
	    	if ($moreRowData->{$rowData->[0]}->{instances} != 0) {
	    		$moreRowData->{$rowData->[0]}->{stddev} = sqrt($moreRowData->{$rowData->[0]}->{stddev}/$moreRowData->{$rowData->[0]}->{instances});
	    	}
	    	delete $data->[$i];
	    }
	    #Normalizing distrubtions
	    my $largestBin = 0;
	    my $normDistribData;
	    print "Normalizing\n";
	    foreach my $label (keys(%{$distribData})) {
	    	if (@{$distribData->{$label}} > $largestBin) {
	    		$largestBin = @{$distribData->{$label}};
	    	}
	    	my $total = 0;
	    	for (my $j=0; $j < @{$distribData->{$label}}; $j++) {
	    		if (defined($distribData->{$label}->[$j])) {
	    			$total += $distribData->{$label}->[$j];
	    		}
	    	}
	    	for (my $j=0; $j < @{$distribData->{$label}}; $j++) {
	    		if (defined($distribData->{$label}->[$j])) {
	    			$normDistribData->{$label}->[$j] = $distribData->{$label}->[$j]/$total;
	    		}
	    	}
	    }
	    #Printing distributions
	    print "Printing...\n";
	    my $bins = [];
	    for (my $i=0; $i < $largestBin; $i++) {
	    	$bins->[$i] = $i*$args->{binsize}."-".($i+1)*$args->{binsize};
	    }
	    my $fileData = {
	    	"Distributions.txt" => ["Label\tZeros\tAverage\tStdDev\tInstances\tMaximum\t".join("\t",@{$bins})],
	    	"NormDistributions.txt" => ["Label\tZeros\tAverage\tStdDev\tInstances\tMaximum\t".join("\t",@{$bins})]
	    };
	    foreach my $label (keys(%{$distribData})) {
			my $line = $label."\t".$moreRowData->{$label}->{zeros}."\t".$moreRowData->{$label}->{average}."\t".$moreRowData->{$label}->{stddev}."\t".$moreRowData->{$label}->{instances}."\t".$moreRowData->{$label}->{maximum};
			my $normline = $label."\t".$moreRowData->{$label}->{zeros}."\t".$moreRowData->{$label}->{average}."\t".$moreRowData->{$label}->{stddev}."\t".$moreRowData->{$label}->{instances}."\t".$moreRowData->{$label}->{maximum};
			for (my $j=0; $j < $largestBin; $j++) {
	    		if (defined($distribData->{$label}->[$j])) {
	    			$line .= "\t".$distribData->{$label}->[$j];
	    			$normline .= "\t".$normDistribData->{$label}->[$j];
	    		} else {
	    			$line .= "\t0";
	    			$normline .= "\t0";
	    		}
	    	}
			push(@{$fileData->{"Distributions.txt"}},$line);
			push(@{$fileData->{"NormDistributions.txt"}},$normline);
		}
		$results->{distfiledata} = $fileData;
		push(@{$message},"Successfully analyzed distribution!");
	} catch {
		my $errorMessage = shift @_;
	    if($errorMessage =~ /^\"\"(.*)\"\"/) {
	        $errorMessage = $1;
	    }
    	return {SUCCESS => 0,ERROR => $errorMessage};
	}
	return {
		SUCCESS => 1,
		MESSAGE => $message,
		RESULTS => $results
	}; 
}

1;
