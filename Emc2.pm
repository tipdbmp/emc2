package Emc2;
use strict;
use warnings FATAL => 'all';
use v5.10;
use Carp qw|croak|;
# use Data::Dump;


# Too lazy to write:
#     package my::ModuleName;
#     module 'my.ModuleName', [ ... ], sub { ... };
#
# i.e write the module name 2 times (in different notations) for every module!
#
# But if we omit the 'package my::ModuleName;' declaration and simply write:
#     do $dirfilename;
#
# Every module will be in the 'Emc2' namespace and will have access
# to Emc2's functions as well as any functions exported by any other 'use Module;'.
#
# So we need "automatic package declarations" =).
#
# _do is here (at the top of the file) because eval STRING "sees lexicals in the enclosing scope".
use File::Slurp ();
sub _do { # my ($dirfilename, $module_name) = @_;
    eval join '', 'package ', _module_name_to_package_name($_[1]), ';',
        scalar File::Slurp::slurp($_[0]),
        ;
}


use Exporter 'import';
our @EXPORT    = qw|module|;
our @EXPORT_OK = qw|main|;


my %module_func_from_name;
my %dependencies_for;
my %module_func_result_cache;

sub module {
    return _module_declaration(@_) if @_ == 3;
    croak 'invalid module declaration';
}

sub _module_declaration { my ($module_name, $dependencies, $module_func) = @_;
    $module_func_from_name{$module_name} = $module_func;

    $dependencies_for{$module_name} = [];
    for (my $i = 0; $i < @$dependencies; $i++) {
        my ($dep) = $dependencies->[$i];

        # my.dependency.name($depenency_identifier)
        my ($dep_name, $dep_ident) = split '\(', $dep;
        chop $dep_ident;
        # dd $dep_name, $dep_ident;

        push @{ $dependencies_for{$module_name} }, {
            name => $dep_name,
            ident => $dep_ident,
            # The dependency name must be a valid path.
            # i.e my.dependency.name is loaded from my/dependency/name.pm
            # path => $dep_name,
        };

        # When a module (i.e module 'D' in this case) declares a dependency ('$C'):
        # module 'A', [], sub { ... };
        # module 'B', [], sub { ... };
        # module 'C', [ 'A($A)' ], sub { ... };
        # module 'D', [ 'C($C)' => { '$A' => 'B' } ], sub { ... };
        # it can overwrite it's dependencies (instead of '$C' using '$A', it will use 'B')
        if ($i + 1 <= $#$dependencies && ref $dependencies->[$i + 1] eq 'HASH') {
            $dependencies_for{$module_name}[-1]{'overwrites'} = $dependencies->[$i + 1];
            $i++;
        }
    }
    # dd $dependencies_for{$module_name};

    return _module_func_inject_dependencies($module_name) if defined wantarray;
}

# Recursively resolve the dependencies for the module with name $module_name
# and then call the module's $module_func with the resolved dependencies.
#
sub _module_func_inject_dependencies { my ($module_name, $overwrites) = @_;
    # say "module $module_name (", 0+@{ $dependencies_for{$module_name} }, ')';

    return $module_func_result_cache{$module_name}
        if exists $module_func_result_cache{$module_name} && !$overwrites;

    my $module_func = $module_func_from_name{$module_name};


    # TODO: the control flow is confusing, rewrite?
    my $dependencies = [ map {
        # say ' ' x 4, $dep->{'name'};

        my $dep = $_;
        my $res;
        my $done_resolving;
        if ($overwrites) {
            if (defined $overwrites->{ $dep->{'ident'} }) {
                $dep = { %$dep }; # copy
                $dep->{'name'} = $overwrites->{ $dep->{'ident'} };

                # SCALAR references denote the name of the new module that overwrites
                # the dependency.
                # module 'foo', [
                #     'bar($bar)' => { '$baz' => \'qux' },
                # sub { ... };
                # ]
                # module 'foo' uses $bar as a dependency, but $bar has a dependency
                # called $baz, which foo overwrites with module qux
                #
                # module 'WobblyCircle', [
                #     'math($math)' => { '$pi' => 4 }
                # ],
                # sub { ... };
                # WobblyCircle uses $math with incorrect value of $pi
                #
                if (ref $dep->{'name'} eq 'SCALAR') {
                    $dep->{'name'} = ${ $dep->{'name'} };
                }
                else {
                    $res = $dep->{'name'};
                    $done_resolving = 1;
                }
            }
        }

        if (!$done_resolving) {
            _require_module($dep->{'name'});

            # recursively inject the dependencies for the dependencies
            if (!$dep->{'overwrites'}) {
                _require_module($dep->{'name'});
                $res = _module_func_inject_dependencies($dep->{'name'});
            }
            else {
                $res = _module_func_inject_dependencies($dep->{'name'}, $dep->{'overwrites'});
            }
        }

        $res;
    } @{ $dependencies_for{$module_name} } ];


    $module_func_result_cache{$module_name} = $module_func->(@$dependencies, @_);
    return $module_func_result_cache{$module_name};
}

sub _require_module { my ($module_name) = @_;
    my $module_func = $module_func_from_name{$module_name};
    if (!$module_func) {
        _require($module_name);
        $module_func = $module_func_from_name{$module_name};
        if (!$module_func) {
            croak "Can't locate module $module_name";
        }
    }
}

sub main {
    # _module_declaration('__MAIN__', @_);
    # my @forced_list_context = _module_declaration('__MAIN__', @_);
    scalar _module_declaration('__MAIN__', @_);
}

sub _require { my ($module_name) = @_;
    # say "_require: $module_name";
    my $filename = _module_name_to_filename($module_name);

    for my $inc_dir ('.', @INC) {
        my $dirfilename = "$inc_dir/$filename";
        # say "<$dirfilename>";
        # next if ! -e $dirfilename || -d _ || -b _;
        if ((-e $dirfilename . '.pm') && !-d _ && !-b _) {
            $dirfilename .= '.pm';
        }
        elsif ((-e $dirfilename . '.pl') && !-d _ && !-b _) {
            $dirfilename .= '.pl';
        }
        else {
            next;
        }

        # my $res = do $dirfilename;
        # if (!defined $res) {
        #      croak $@ ? "$@Compilation failed in _require"
        #               : "Can't locate $filename: $! \n";
        # }
        ## if (!$res) {
        ##     croak "$filename did not return true value";
        ## }

        _do($dirfilename, $module_name);
        croak "$@Compilation failed in _require" if $@;

        return;
    }

    croak "Can't locate $filename in \@INC (you may need to install the $module_name module) (\@INC contains: @INC)";
}

sub _module_name_to_filename { my ($module_name) = @_;
    # foo.Bar => foo/Bar
    my $filename = $module_name;
    $filename =~ s|\.|/|g;
    $filename;
}

sub _module_name_to_package_name { my ($module_name) = @_;
    # foo.Bar => foo::Bar
    my $package_name = $module_name;
    $package_name =~ s|\.|::|g;
    $package_name;
}


2;