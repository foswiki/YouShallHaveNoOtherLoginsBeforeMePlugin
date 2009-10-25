# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# Author: Oliver Krueger, (wiki-one.net)
# Copyright 2009, Oliver Krueger

package Foswiki::Plugins::YouShallHaveNoOtherLoginsBeforeMePlugin;
use strict;

use Foswiki::Func ();       # The plugins API
use Foswiki::Plugins ();    # For the API version

our $VERSION = '$Rev: 5154 $';
our $RELEASE = '1.0.0';
our $SHORTDESCRIPTION = 'Invalidates existing sessions of the same authenticated user.';
our $NO_PREFS_IN_TOPIC = 1;

sub initPlugin {
    my ( $topic, $web, $user, $installWeb ) = @_;

    # check for Plugins.pm versions
    if ( $Foswiki::Plugins::VERSION < 2.0 ) {
        Foswiki::Func::writeWarning( 'Version mismatch between ',
            __PACKAGE__, ' and Plugins.pm' );
        return 0;
    }

    if ( Foswiki::Func::getWikiName() ne $Foswiki::cfg{DefaultUserWikiName} ) {

        my $current_sid  = Foswiki::Func::getSessionValue("_SESSION_ID") || "";
        my $current_user = Foswiki::Func::getSessionValue("AUTHUSER")    || "";

        # get a list of all session ids by reading out the directory
        # SMELL: this breaks, if the impl of CGI::Session::Driver changes
        # of if a different Driver is used (not File)
        # This should probably be done with CGI::Session::Driver->traverse()
        my $workingDir = "$Foswiki::cfg{WorkingDir}/tmp";
        my @list = (); 
        if ( opendir( DIR, "$workingDir" ) ) { 
            my @files =
            grep { /^cgisess_.*$/ } readdir(DIR);
            closedir DIR; 
            @list = map { s/^cgisess_(.*)$/$1/; $_ } @files;
        }

        # peek into every session excl the current
        # invalidate the session if it has the same AUTHUSER
        foreach my $sid ( @list ) {
            next if ( $sid eq $current_sid );
            my $session = CGI::Session->new( undef, $sid, 
              { Directory => $workingDir } );
            if ( $session->param("AUTHUSER") eq $current_user ) {
                $session->delete();
            }
        }
    } 

    # Plugin correctly initialized
    return 1;
}

1;
