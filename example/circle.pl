use strict;
use warnings FATAL => 'all';
use v5.14;
use lib '../';
use Emc2 qw|module main|;

module 'pi', [], sub { 3.14159; };

module 'Circle', [
    'pi($pi)',
],
sub {
    my ($pi) = @_;

    return sub { my ($args) = @_;
    my ($x, $y, $r) = @$args{qw|x y r|};
    $x //= 0; $y //= 0;
    $r //= 1;

    my $area = sub { $pi * $r ** 2 };

    return {
        x => { get => sub { $x }, set => sub { $x = $_[0] } },
        y => { get => sub { $y }, set => sub { $y = $_[0] } },
        r => { get => sub { $r }, set => sub { $r = $_[0] } },
        area => $area,
    };};
};


module 'UniverseA', [
    'Circle($Circle)',
],
sub {
    my ($Circle) = @_;
    my $c = $Circle->({ r => 1 });
    say "UniverseA: r = 1  =>  area = ", $c->{area}();
    $c->{r}{set}($c->{r}{get}() + 1);
    say "UniverseA: r = 2  =>  area = ", $c->{area}();
};

module 'UniverseB', [
    'Circle($Circle)' => { '$pi' => 4 },
],
sub {
    my ($Circle) = @_;
    my $c = $Circle->({ r => 1 });
    say "UniverseB: r = 1  =>  area = ", $c->{area}();
};

module 'UniverseC', [
    'Circle($Circle)' => { '$pi' => 3.14159265359 },
],
sub {
    my ($Circle) = @_;
    my $c = $Circle->({ r => 1 });
    say "UniverseC: r = 1  =>  area = ", $c->{area}();
};


main [
    'UniverseA($UniverseA)',
    'UniverseB($UniverseB)',
    'UniverseC($UniverseC)',
],
sub {

};