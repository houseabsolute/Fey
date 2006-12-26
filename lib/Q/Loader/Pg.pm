package Q::Loader::Pg;

use strict;
use warnings;

use base 'Q::Loader::DBI';

use Q::Literal;

use Scalar::Util qw( looks_like_number );


sub _schema_name { 'public' }

sub _column_params
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    my %col = $self->SUPER::_column_params( $table, $col_info );

    if ( defined $col{length} && $col{length} =~ /(\d+),(\d+)/ )
    {
        $col{length}    = $2;
        $col{precision} = $1;
    }

    delete $col{length}
        unless $col{precision} || $col{type} =~ /char/i;


    return %col
}

sub _is_auto_increment
{
    my $self     = shift;
    my $table    = shift;
    my $col_info = shift;

    return
        (    $col_info->{COLUMN_DEF}
          && $col_info->{COLUMN_DEF} =~ /^nextval\(/ ? 1 : 0
        );
}

sub _default
{
    my $self     = shift;
    my $default  = shift;
    my $col_info = shift;

    return if $default =~ /^nextval\(/;

    if ( $default =~ /^NULL$/i )
    {
        return Q::Literal->null();
    }
    elsif ( looks_like_number($default) )
    {
        return $default;
    }
    # string defaults come back like 'Foo'::character varying
    elsif ( $default =~ s/^\'(.+)\'::[^:]+$/$1/ )
    {
        return Q::Literal->new_from_scalar($default);
    }
    elsif ( $default =~ /\(.*\)/ )
    {
        return Q::Literal->term($default);
    }
}


1;
