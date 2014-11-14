package DotNotation;
use 5.008008;
use strict;
use warnings FATAL => 'all';
use Filter::Simple;

our $DEBUG = 0;


# The order of the 'FILTER { ... };' declarations is important. Do NOT change it.
# I think the order in which the FILTERs are "applied" is reverse of their declaration.


# Getters.
# Make "$foo.x" become "$foo->{'x'}{'get'}()"

sub dot_notation_to_arrow_notation_getters { my ($dot_notation_expr) = @_;
    my @parts = split '\.', $dot_notation_expr;
    return join '', $parts[0], '->',
        map { join '', q|{'|, $parts[$_], q|'}{'get'}()| } 1 .. $#parts
        ;
}

FILTER {
    s/
        ( \$ \w+ \. [.\w]+ )
    /dot_notation_to_arrow_notation_getters($1)/emsgx;

    warn $_ if $DEBUG;
    $_;
};


# Setters.

# Make "$foo.x = <expr>;" become "$foo->{'x'}{'set'}(<expr>);"
# There is at least one bug here, i.e assignment to a string that contains ';'
# $foo.bar = 'baz;'; will be changed into $foo->{'bar'}{'set'}('baz);';

sub dot_notation_to_arrow_notation_setters { my ($dot_notation_expr) = @_;
    my ($lhs, $rhs) = split ' = ', $dot_notation_expr;
    my @parts = split '\.', $lhs;
    return join '', $parts[0], '->',
        (map { join '', q|{'|, $parts[$_], q|'}{'get'}()| } 1 .. $#parts - 1),
        q|{'|, $parts[-1], q|'}|, q|{'set'}|,
        '(', $rhs, ')',
        ;
}

FILTER {
    s/
        (
            \$ \w+ \. [.\w]+

            \s* = \s*

            [^;]+
        )
    /dot_notation_to_arrow_notation_setters($1)/emsgx;

    warn $_ if $DEBUG;
    $_;
};

# Allow $foo.x += <expr>;
# Valid operators '-', '+', '*' and '/'

sub dot_notation_to_arrow_notation_setters_ops { my ($dot_notation_expr) = @_;
    my ($lhs, $rhs) = split '=', $dot_notation_expr, 2;
    # say $lhs;
    # say $rhs;

    my $op;
    ($lhs, $op) = split ' ', $lhs;
    # say $lhs;
    # say $op;

    my $dnt_getters_lhs = dot_notation_to_arrow_notation_getters($lhs);
    # say dot_notation_to_arrow_notation_getters($lhs);

    my $dnt_setter_lhs = do {
        my @parts = split '\.', $lhs;
        join '', $parts[0], '->',
            (map { join '', q|{'|, $parts[$_], q|'}{'get'}()| } 1 .. $#parts - 1),
            q|{'|, $parts[-1], q|'}|, q|{'set'}|,
    };
    # say $dnt_setter_lhs;

    return join '',
        $dnt_setter_lhs, '(', $dnt_getters_lhs, ' ', $op, $rhs, ')',
        ;
}

FILTER {
    s/
     (
        \$ \w+ \. [.\w]+

        \s* [-+*\/%]= \s*

        [^;]+
    )
    /dot_notation_to_arrow_notation_setters_ops($1)/emsgx;

    warn $_ if $DEBUG;
    $_;
};


# Method calls.
# Make "$foo.bar(" become "$foo->{'bar'}("

sub dot_notation_to_arrow_notation_method { my ($dot_notation_expr) = @_;
    my @parts = split '\.', $dot_notation_expr;
    return join '', $parts[0], '->',
        (map { join '', q|{'|, $parts[$_], q|'}{'get'}()| } 1 .. $#parts - 1),
        q|{'|, substr($parts[-1], 0, -1), q|'}|, '('
        ;
}

FILTER {
    s/
        ( \$ \w+ \. [.\w]+ \( )
    /dot_notation_to_arrow_notation_method($1)/emsgx;

    warn $_ if $DEBUG;
    $_;
};



1;