### NAME
Emc2 - a module "system" inspired by [AngularJS](https://angularjs.org/) for Perl.

### SYNOPSIS
```perl
use Emc2 qw|module main|;

module 'pi', [], sub { 3.14159; };

module 'Circle', [
    'pi($pi)',
],
sub {
    my ($pi) = @_;

    return sub { my ($args) = @_;
    my ($r) = @$args{qw|r|};
    $r ||= 1;

    my $area = sub { $pi * $r ** 2 };

    return {
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
    print "UniverseA: r = 1  =>  area = ", $c->{area}(), "\n";
};

module 'UniverseB', [
    'Circle($Circle)' => { '$pi' => 4 },
],
sub {
    my ($Circle) = @_;
    my $c = $Circle->({ r => 1 });
    print "UniverseB: r = 1  =>  area = ", $c->{area}(), "\n";
};


main ['UniverseA($UniverseA)', 'UniverseB($UniverseB)' ], sub { };
```

### DESCRIPTION
By default only the ```module``` function is exported. The other function that could be exported is ```main``` (Which is just a module with the "special" name "\_\_MAIN__").

The module function is used to declare modules:
```perl
module '<module-name>', [
    # <list-of-dependencies>
],
sub {
    my (@list_of_dependencies) = @_;
};
```

The syntax for a dependency is:
```perl
'path.to.module($identifier)'

or

'path.to.module($identifier)' => { '$other_identifier' => \'path.to.other.module' } # note the SCALAR ref

or

'path.to.module($identifier)' => { '$other_identifier' => 'some expr' }
```

I.e a module can simply declare it's dependencies but it could also overwrite
the dependencies of it's dependencies.

### CAVEATS
* The error reporting is bad.
