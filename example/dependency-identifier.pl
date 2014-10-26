use strict;
use warnings FATAL => 'all';
use v5.14;
use lib '../';
use Emc2 qw|module main|;

module 'Foo', [
    'app.utils.bar($bar)',
    'baz.qux($qux)',
],
sub {
    my ($bar, $qux) = @_;
    say $bar->[0];
    say $qux;
};

module 'Baz', [
    'Foo($Foo)' => { '$bar' => \'app.utils.betterbar' },
],
sub {
    my ($Foo) = @_;
    say '';
};

module 'A', [], sub { 'A' };
module 'B', [], sub { 'B' };
module 'C', [ 'A($A)' ], sub { my ($A) = @_; "C and $A"; };
module 'D', [ 'C($C)' ], sub { my ($C) = @_; say "D and $C"; };
module 'E', [ 'C($C)' => { '$A' => 'B' } ],  sub { my ($C) = @_; say "E and $C"; };

main [
    'Foo($Foo)',
    'Baz($Baz)',
    'D($D)',
    'E($E)',
],
sub {
    my (
        $Foo,
        $Baz,
        $D,
        $E,
    ) = @_;
};



