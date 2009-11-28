package Solaris::SMF;

use warnings;
use strict;
require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw( get_services );
use Readonly;
use Params::Validate qw ( validate :types );
use Solaris::SMF::Service;

my $debug = $ENV{RELEASE_TESTING}?$ENV{RELEASE_TESTING}:0;

=head1 NAME

Solaris::SMF - Manipulate Solaris 10 services from Perl

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Interface to Sun's Service Management Facility in Solaris 10. This module provides
a wrapper around 'svcs', 'svcadm' and 'svccfg'.

The SMF in Solaris is a replacement for inetd as well as the runlevel-based stopping 
and starting of daemons. Service definitions are stored in an XML database.

The biggest advantages in using SMF are the resiliency support, consistent interface and 
inter-service dependencies it offers. Services that die for any reason can be automatically 
restarted by the operating system; all services can be enabled or disabled using the same
commands; and services can be started as soon as all the services they depend upon have
been started, rather than at a fixed point in the boot process.


=head1 EXPORT



=head1 FUNCTIONS

=head2 get_services

Get a list of SMF services, using an optional wildcard as a filter. The default is to return all services.

Returns a list of Solaris::SMF::Service objects.

=cut


sub get_services {
    $debug && carp('get_services ' . join(',', @_));
    my %p
        = validate( @_, { wildcard => { type => SCALAR, default => '*' } } );
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    Readonly my $svcs => '/usr/bin/svcs';
    my @service_list;
    open my $svc_list, '-|', " $svcs -aH '$p{wildcard}' 2>/dev/null"
        or die 'Unable to query SMF services';
    while ( my $svc_line = <$svc_list> ) {
        $debug && carp(Data::Dumper->Dump([$svc_line], [qw($svc_line)]));
        my ( $state, $date, $FMRI ) = (
            $svc_line =~ m/ 
		^ 
		([^\s]+)	# Current state
		[\s]+
		([^\s]+)	# Date this state was set
		[\s]+
		( (?:svc:|lrc:) [^\s]+)	# FMRI
		\n?
		$ 
	/xms
        );
        $debug && carp(Data::Dumper->Dump([$state, $date, $FMRI], [qw($state $date $FMRI)]));
        if ($FMRI) {
            push( @service_list, Solaris::SMF::Service->new($FMRI) );
        }
    }
    close $svc_list;
    return @service_list;
}

=head1 AUTHOR

Brad Macpherson, C<< <brad at teched-creations.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-solaris-smf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Solaris-SMF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Solaris::SMF


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Solaris-SMF>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Solaris-SMF>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Solaris-SMF>

=item * Search CPAN

L<http://search.cpan.org/dist/Solaris-SMF/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENCE

Copyright 2009 Brad Macpherson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public Licence as published
by the Free Software Foundation; or the Artistic Licence.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Solaris::SMF
