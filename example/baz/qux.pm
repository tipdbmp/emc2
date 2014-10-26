use strict;
use warnings FATAL => 'all';
use v5.14;
use lib '../../';
use Emc2;

module 'baz.qux', [],
sub {
    return 'qux';
};