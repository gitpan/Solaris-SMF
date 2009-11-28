#!perl -T

use Test::More tests => 3;

BEGIN {
    use_ok( 'Solaris::SMF' );
}

diag( "Testing Solaris::SMF $Solaris::SMF::VERSION, Perl $], $^X" );

# There's no point trying to install onto anything but Solaris 10 or above.
$ENV{PATH}='/bin:/usr/bin:/sbin:/usr/sbin';
my ($OS, $release) = split(/ /, `uname -sr`);
ok($OS eq 'SunOS', 'No point installing on non-Solaris operating system.');
ok($release gt '9', 'Solaris 10 or above is required.');
