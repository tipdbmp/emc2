use strict;
use warnings FATAL => 'all';
use v5.14;
use lib '../';
use Emc2;

sub Point { my ($args) = @_;
    $args //= {};
    my ($x, $y) = @$args{qw|x y|};
    $x //= 0;
    $y //= 0;

    my $distance = sub { sqrt $x ** 2 + $y ** 2; };

    mkattrs('Point');
}

my $p = Point();
say $p->{x}{'get'}();
$p->{x}{'set'}(1);
$p->{y}{'set'}(1);
say $p->{distance}(); # 1.4142135623731