 
# FIXME need way to find the basic libraries and such.


BEGIN {
    $main::VERSION = "2.1";
    my $webwork_directory = $ENV{WEBWORK_ROOT};
	
	eval "use lib '$webwork_directory/lib'"; die $@ if $@;
	eval "use WeBWorK::CourseEnvironment"; die $@ if $@;
 	my $ce = new WeBWorK::CourseEnvironment({ webwork_dir => $webwork_directory });
 	my $webwork_url = $ce->{webwork_url};
 	my $pg_dir = $ce->{pg_dir};
#  	my $webwork_htdocs_url = $ce->{webwork_htdocs_url};
#  	my $webwork_htdocs_dir = $ce->{webwork_htdocs_dir};
#  	my $webwork_courses_url = $ce->{webwork_courses_url};
#  	my $webwork_courses_dir = $ce->{webwork_courses_dir};
 	eval "use lib '$pg_dir/lib'"; die $@ if $@;
    
	$WebworkWebservice::WW_DIRECTORY = $webwork_directory;
	$WebworkWebservice::PG_DIRECTORY = $pg_dir;
	$WebworkWebservice::SeedCE       = $ce;
	$WebworkWebservice::HOST_NAME     = Apache->server->server_hostname;
	$WebworkWebservice::HOST_PORT     = Apache->server->port;
	$WebworkWebservice::PASSWORD      = 'geometry';
	$WebworkWebservice::COURSENAME    = 'daemon2_course'; # default course

}
use Apache;
use WeBWorK::PG::Local;
    
#use lib '/home/gage/webwork/webwork-modperl/lib';
#use lib '/home/gage/webwork/pg/lib';


#$Webservice::HOST_PATH = "http://$Webservice::HOST_NAME";
#$Webservice::HOST_PATH .= ":$Webservice::HOST_PORT" 
#                 unless ($Webservice::HOST_PORT == 80 );

# warn "webwork_directory = $WebworkWebservice::WW_DIRECTORY\n\t";
# warn "pg_directory = $WebworkWebservice::PG_DIRECTORY\n\t";
# warn "seedCE  = $WebworkWebservice::SeedCE\n\t";
# warn "host name  = $WebworkWebservice::HOST_NAME\n\t";

#FIXME  port is not being set!
# warn "host port  = $Webservice::HOST_PORT\n\t";  

# #warn "host path  = $Webservice::HOST_PATH\n\t";
# warn " password  $WebworkWebservice::PASSWORD\n\t";

use strict;
###############################################################################

package WebworkWebservice;

sub pretty_print_rh { 
    shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
	my $rh = shift;
	my $indent = shift || 0;
	my $out = "";
	my $type = ref($rh);

	if (defined($type) and $type) {
		$out .= " type = $type; ";
	} elsif ($rh == undef) {
		$out .= " type = scalar; ";
	}
	if ( ref($rh) =~/HASH/ or "$rh" =~/HASH/ ) {
	    $out .= "{\n";
	    $indent++;
 		foreach my $key (sort keys %{$rh})  {
 			$out .= "  "x$indent."$key => " . pretty_print_rh( $rh->{$key}, $indent ) . "\n";
 		}
 		$indent--;
 		$out .= "\n"."  "x$indent."}\n";

 	} elsif (ref($rh)  =~  /ARRAY/ or "$rh" =~/ARRAY/) {
 	    $out .= " ( ";
 		foreach my $elem ( @{$rh} )  {
 		 	$out .= pretty_print_rh($elem, $indent);
 		
 		}
 		$out .=  " ) \n";
	} elsif ( ref($rh) =~ /SCALAR/ ) {
		$out .= "scalar reference ". ${$rh};
	} elsif ( ref($rh) =~/Base64/ ) {
		$out .= "base64 reference " .$$rh;
	} else {
		$out .=  $rh;
	}
	
	return $out." ";
}


use WebworkWebservice::RenderProblem;
use WebworkWebservice::LibraryActions;
use WebworkWebservice::MathTranslators;

###############################################################################
package WebworkXMLRPC;
use WebworkWebservice;
use base qw(WebworkWebservice); 



#  respond to xmlrpc requests
sub listLib {
    my $self = shift;
    my $in = shift;
  	return( WebworkWebservice::LibraryActions::listLib($in) );
}
sub listLibraries {
    my $self = shift;
    my $in = shift;
  	return( WebworkWebservice::LibraryActions::listLibraries($in) );
}
sub renderProblem {
    my $self = shift;
    my $in = shift;
  	return( WebworkWebservice::RenderProblem::renderProblem($in) );
}
sub readFile {
    my $self = shift;
    my $in   = shift;
  	return( WebworkWebservice::LibraryActions::readFile($in) );
}
sub tex2pdf {
    my $self = shift;
    my $in   = shift;
  	return( WebworkWebservice::MathTranslators::tex2pdf($in) );
}

# -- SOAP::Lite -- guide.soaplite.com -- Copyright (C) 2001 Paul Kulchenko --
# test responses

sub hi {   shift if UNIVERSAL::isa($_[0] => __PACKAGE__); # grabs class reference                 
  return "hello, world";     
}
sub hello2 { shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
	#print "Receiving request for hello world\n";
	return "Hello world2";
}
sub bye {shift if UNIVERSAL::isa($_[0] => __PACKAGE__);  
	return "goodbye, sad cruel world";
}

sub languages {shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
	return ["Perl", "C", "sh"];   
}                               

sub echo_self {
	my $self = shift;
}

sub echo { 
    return join("|",("begin ", WebworkWebservice::pretty_print_rh(\@_), " end") );
}

sub pretty_print_rh {
	WebworkWebservice::pretty_print_rh(@_);
}


sub tth {shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
	my $in = shift;
	my $tthpath = "/usr/local/bin/tth";
    # $tthpath -L -f5 -r 2>/dev/null " . $inputString;
    return $in;

}




package WWd;

#use lib '/home/gage/webwork/xmlrpc/daemon';
#use WebworkXMLRPC;




############utilities

sub echo { 
    return "WWd package ".join("|",("begin ", WebworkWebservice::pretty_print_rh(\@_), " end") );
}

sub listLib {
    shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my $in = shift;
  	return( Webwork::listLib($in) );
}
sub renderProblem {
    shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my $in = shift;
  	return( Filter::filterObject( Webwork::renderProblem($in) ) );
}
sub readFile {
    shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
    my $in = shift;
  	return( Webwork::readFile($in) );
}
# sub hello {
# 	shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
# 	print "Receiving request for hello world\n";
# 	return "Hello world?";
# }


# sub tth {
# 	shift if UNIVERSAL::isa($_[0] => __PACKAGE__);
# 	my $in = shift;
# 	my $tthpath = "/usr/local/bin/tth";
#     my $out;
#     $inputString    = "<<END_OF_TTH_INPUT_STRING;\n\n\n" . $in . "\nEND_OF_TTH_INPUT_STRING\necho \"\" >/dev/null"; 
#     #it's not clear why another command is needed.
# 
#     if (-x $tthpath ) {
#     	my $tthcmd      = "$tthpath -L -f5 -r 2>/dev/null " . $inputString;
#     	if (open(TTH, "$tthcmd   |")) {  
#     	    local($/);
# 			$/ = undef;
# 			$out = <TTH>;
# 			$/ = "\n";
# 			close(TTH);
# 	    }else {
# 	        $out = "<BR>there has been an error in executing $tthcmd<BR>";
# 	    }
# 	} else {
# 		$out = "<BR> Can't execute the program tth at |$tthpath|<BR>";
#     }
# 
#     #return "<!-- \r\n" . $in . "\r\n-->\r\n\r\n" . $out . "\r\n\r\n";
#     return $out;
# 
# }

package Filter;


sub is_hash_ref {
	my $in =shift;
	my $save_SIG_die_trap = $SIG{__DIE__};
    $SIG{__DIE__} = sub {CORE::die(@_) };
	my $out = eval{  %{   $in  }  };
	$out = ($@ eq '') ? 1 : 0;
	$@='';
	$SIG{__DIE__} = $save_SIG_die_trap;
	$out;
}
sub is_array_ref {
	my $in =shift;
	my $save_SIG_die_trap = $SIG{__DIE__};
    $SIG{__DIE__} = sub {CORE::die(@_) };
	my $out = eval{  @{   $in  }  };
	$out = ($@ eq '') ? 1 : 0;
	$@='';
	$SIG{__DIE__} = $save_SIG_die_trap;
	$out;
}
sub filterObject {

    my $is_hash = 0;
    my $is_array =0;
	my $obj = shift;
	#print "Enter filterObject ", ref($obj), "\n";
	my $type = ref($obj);
	unless ($type) {
		#print "leave filterObject with nothing\n";
		return($obj);
	}


	if ( is_hash_ref($obj)  ) {
	    #print "enter hash ", %{$obj},"\n";
	    my %obj_container= %{$obj};
		foreach my $key (keys %obj_container) {
			$obj_container{$key} = filterObject( $obj_container{$key} );
			#print $key, "  ",  ref($obj_container{$key}),"   ", $obj_container{$key}, "\n";
		}
		#print "leave filterObject with HASH\n";
		return( bless(\%obj_container,'HASH'));
	};



	if ( is_array_ref($obj)  ) {
		#print "enter array ( ", @{$obj}," )\n";
		my @obj_container= @{$obj};
		foreach my $i (0..$#obj_container) {
			$obj_container[$i] = filterObject( $obj_container[$i] );
			#print "\[$i\]  ",  ref($obj_container[$i]),"   ", $obj_container[$i], "\n";
		}
		#print "leave filterObject with ARRAY\n";
		return( bless(\@obj_container,'ARRAY'));
	};
    
}


1;
