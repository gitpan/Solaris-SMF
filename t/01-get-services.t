#!perl -Tw

use Test::More qw( no_plan );
use Solaris::SMF;

# Check we can get all and no services
ok (defined get_services(), 'get_services *');
my @nonexistent_services = get_services(wildcard => 'Nonexistent');
ok (scalar @nonexistent_services == 0, 'get_services Nonexistent');

# Check that a well-known service milestone is found
my @multi_user_milestone = get_services(wildcard => 'multi-user-server');
ok (scalar @multi_user_milestone == 1, 'get_services multi-user-server returned ' . scalar @multi_user_milestone);

# Check attributes of this service
my ($multi_user_milestone) = @multi_user_milestone;
ok ($multi_user_milestone->FMRI eq 'svc:/milestone/multi-user-server:default', 'svc:/milestone/multi-user-server:default has been renamed ' . $multi_user_milestone->FMRI);
ok ($multi_user_milestone->status eq 'online', 'svc:/milestone/multi-user-server:default ' . $multi_user_milestone->status . ', not online!');

# Get the properties of this service
ok (scalar $multi_user_milestone->properties == 1, 'multi-user-server properties returned ' . scalar $multi_user_milestone->properties);
ok ($multi_user_milestone->property('general/enabled') eq 'true', 'svc:/milestone/multi-user-server:default enabled property is ' .  $multi_user_milestone->property('general/enabled') . ', not true!');
ok ($multi_user_milestone->property_type('general/enabled') eq 'boolean', 'svc:/milestone/multi-user-server:default enabled property type is ' .  $multi_user_milestone->property_type('general/enabled') . ', not boolean!');
