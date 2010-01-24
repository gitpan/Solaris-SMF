package Solaris::SMF::Service;
BEGIN {
    eval {
            require Data::Dumper;
                }
                };

use warnings;
use strict;
use Params::Validate qw( validate validate_pos :types );
use Carp;

my $debug = $ENV{RELEASE_TESTING} ? $ENV{RELEASE_TESTING} : 0;

=head1 NAME

Solaris::SMF::Service - Encapsulate Solaris 10 services in Perl

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

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

=head1 METHODS

=cut

sub _svcs {
    my $self = shift;
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    open my $svc_list, '-|', " svcs -aH '$self->{FMRI}' 2>/dev/null"
      or croak 'Unable to query SMF services';
    while ( my $svc_line = <$svc_list> ) {
        my ( $state, $date, $FMRI ) = (
            $svc_line =~ m/ 
                ^ 
                ([^\s]+)        # Current state
                [\s]+
                ([^\s]+)        # Date this state was set
                [\s]+
                ( (?: svc: | lrc: ) [^\s]+ ) # FMRI
                \n?
                $ 
        /xms
        );
        if ($FMRI) {
            close $svc_list;
            return ( $state, $date );
        }
    }
    croak "Unable to determine status of $self->{FMRI}";
}

sub _svcprop {
    $debug && warn( '_svcprop ' . join( ',', @_ ) );
    my $self = shift;
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    open my $svcprop_list, '-|', " svcprop '$self->{FMRI}' 2>/dev/null"
      or croak 'Unable to query SMF service properties';
    my %properties;
    while ( my $svcprop_line = <$svcprop_list> ) {
        my ( $name, $type, $value ) = (
            $svcprop_line =~ m/
                ^
                ([^\s]+)        # Property name
                [\s]+
                ([^\s]+)        # Type of property
                [\s]+
                ([^\s]*[^\n]*)        # Value of property
                $
        /xms
        );
        if ($name) {
            $properties{$name}{type}  = $type;
            $properties{$name}{value} = $value;
        }
    $debug && print STDERR Data::Dumper->Dump( [$name, $type, $value], [qw($name $type $value)] );
    }
    $debug && print STDERR Data::Dumper->Dump( [\%properties], [qw(%properties)] );
    return \%properties;
}

sub _svcadm {
    $debug && warn( '_svcadm ' . join( ',', @_ ) );
    my $self = shift;
    my $svcadm_action = shift;
    local $ENV{PATH} = '/bin:/usr/bin:/sbin:/usr/sbin';
    open my $svc_adm, '-|', " svcadm $svcadm_action '$self->{FMRI}' 2>&1"
      or croak 'Unable to administer SMF services';
    close $svc_adm;
}

=head2 new

Create a new Service object. The parameter must be a valid, unique FMRI.

=cut

sub new {
    $debug && warn( 'new ' . join( ',', @_ ) );
    my $class   = shift;
    my $FMRI    = shift;
    my $service = bless {}, __PACKAGE__;
    $service->{FMRI} = $FMRI;
    return $service;
}

=head2 status

Get the current status of this service. Returns a string, 'disabled', 'enabled', 'offline'.

=cut

sub status {
    $debug && warn( 'status ' . join( ',', @_ ) );
    my $self = shift;
    my ( $status, $date ) = $self->_svcs();
    $debug
      && warn( Data::Dumper->Dump( [ $status, $date ], [qw($status $date)] ) );
    return $status;
}

=head2 FMRI

Returns the Fault Managed Resource Identifier for this service. 

=cut

sub FMRI {
    $debug && warn( 'FMRI ' . join( ',', @_ ) );
    my $self = shift;
    return $self->{FMRI};
}

=head2 properties

Returns all or some properties for this service.

=cut

sub properties {
    $debug && warn( 'properties ' . join( ',', @_ ) );
    my $self       = shift;
    my $properties = $self->_svcprop();
    return %{$properties};
}

=head2 property

Returns the value of a single property of this service.

=cut

sub property {
    $debug && warn( 'property ' . join( ',', @_ ) );
    my $self = shift;
    my $p = validate_pos( @_, { type => SCALAR } );
    my ($property_name) = @{$p};

    my $properties = $self->_svcprop();
    $debug && warn( Data::Dumper->Dump( [$properties], [qw($properties)] ) );
    if ( defined $properties->{$property_name} ) {
        return $properties->{$property_name}{value};
    }
    else {
        carp "Unable to find property '$property_name' for " . $self->{FMRI};
        return undef;
    }
}

=head2 property_type

Returns the type of a single property of this service.

=cut

sub property_type {
    $debug && warn( 'property_type ' . join( ',', @_ ) );
    my $self = shift;
    my $p = validate_pos( @_, { type => SCALAR } );
    my ($property_name) = @{$p};

    my $properties = $self->_svcprop();
    $debug && warn( Data::Dumper->Dump([$properties], [qw($properties)]) );
    if ( defined $properties->{$property_name} ) {
        return $properties->{$property_name}{type};
    }
    else {
        carp "Unable to find property '$property_name' for " . $self->{FMRI};
        return undef;
    }
}

=head2 disable

This instructs SMF to disable the service permanently. To disable temporarily,
that is until the next time the server is rebooted, use the 'stop' method.

=cut
sub disable {
    $debug && warn( 'disable ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('disable');
}

=head2 stop

This instructs SMF to stop the service. It uses the -t flag to svcadm, so that
using this call will not prevent the service from starting the next time the
server reboots.

=cut
sub stop {
    $debug && warn( 'stop ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('disable -t');
}

=head2 enable

This instructs SMF to enable the service permanently. To enable temporarily,
that is until the next time the server is rebooted, see the 'start' method.

=cut
sub enable {
    $debug && warn( 'enable ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('enable');
}

=head2 start

This instructs SMF to start the service. This change is not made persistent
unless you use the 'enable' method.

=cut
sub start {
    $debug && warn( 'start ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('enable -t');
}

=head2 refresh

This instructs SMF to refresh the service. Needed whenever alterations are
made to a service's properties. It acts as the analogue of a SQL 'commit'.

=cut
sub refresh {
    $debug && warn( 'refresh ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('refresh');
}

=head2 clear

This instructs SMF to clear the service's state, that is, to remove the
'failed' marker from it. This is needed prior to starting a failed service.

=cut
sub clear {
    $debug && warn( 'clear ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('clear');
}

=head2 mark

This instructs SMF to mark the service as failed.

=cut
sub mark {
    $debug && warn( 'mark ' . join( ',', @_ ) );
    my $self = shift;
    return $self->_svcadm('mark');
}

=head1 AUTHOR

Brad Macpherson, C<< <brad at teched-creations.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-solaris-smf at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Solaris-SMF>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Solaris::SMF::Service


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

1;    # End of Solaris::SMF::Service
