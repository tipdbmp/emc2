use strict;
use warnings FATAL => 'all';
use v5.14;
use lib '../../../';
use Emc2;

module 'app.utils.bar', [],
sub {
    return ['bar'];
};