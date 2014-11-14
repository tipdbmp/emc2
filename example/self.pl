use strict;
use warnings FATAL => 'all';
use v5.14;
use lib '../';
use Emc2;
use DotNotation;

sub Point { my ($args) = @_;
    $args //= {};
    my ($x, $y) = @$args{qw|x y|};
    $x //= 0;
    $y //= 0;

    my $distance = sub { sqrt $x ** 2 + $y ** 2; };

    # self('Point');
    self;
}

my $p = Point();
say $p.x;
$p.x = 1;
$p.y = 1;
say $p.distance(); # 1.4142135623731