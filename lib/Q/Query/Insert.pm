package Q::Query::Insert;

use strict;
use warnings;

use base 'Q::Query';

use Q::Validate
    qw( validate
        validate_pos
        SCALAR
        UNDEF
        OBJECT
      );

use Scalar::Util qw( blessed );


sub insert { return $_[0] }

{
    my $spec = { type => OBJECT,
                 callbacks =>
                 { 'is a (non-alias) column with a table' =>
                   sub {    $_[0]->isa('Q::Column')
                         && $_[0]->table()
                         && ! $_[0]->is_alias()
                         && ! $_[0]->table()->is_alias() }
                 },
               };

    my $nullable_col_value_type = { type      => SCALAR|UNDEF|OBJECT,
                                    callbacks =>
                                    { 'literal, placeholder, scalar, or undef' =>
                                      sub {    ! blessed $_[0]
                                            || $_[0]->isa('Q::Literal')
                                            || $_[0]->isa('Q::Placeholder') }
                                    },
                                  };

    my $non_nullable_col_value_type = { type      => SCALAR|OBJECT,
                                        callbacks =>
                                        { 'literal, placeholder, or scalar' =>
                                          sub {    ! blessed $_[0]
                                                || $_[0]->isa('Q::Literal')
                                                || $_[0]->isa('Q::Placeholder') }
                                        },
                                      };
    sub into
    {
        my $self = shift;

        my $count = @_ ? scalar @_ : 1;
        my @cols = validate_pos( @_, ($spec) x $count );

        $self->{columns} = \@cols;

        for my $col ( @{ $self->{columns} } )
        {
            $self->{values_spec}{ $col->name() } =
                $col->is_nullable()
                ? $nullable_col_value_type
                : $non_nullable_col_value_type;
        }

        return $self;
    }
}

{
    sub values
    {
        my $self = shift;

        my %vals = validate( @_, $self->{values_spec} );

        for ( values %vals )
        {
            $_ = Q::Literal->new_from_scalar($_)
                unless blessed $_;
        }

        push @{ $self->{values} }, \%vals;

        return $self;
    }
}

sub sql
{
    my $self = shift;

    return ( join ' ',
             $self->_insert_clause(),
             $self->_into_clause(),
             $self->_values_clause(),
           );
}

sub _insert_clause
{
    return
        ( 'INSERT INTO '
          . $_[0]->formatter()->quote_identifier( $_[0]->{columns}[0]->table()->name() )
        );
}

sub _into_clause
{
    return
        ( '('
          . ( join ', ',
              map { $_[0]->formatter()->quote_identifier( $_->name() ) }
              @{ $_[0]->{columns} }
            )
          . ')'
        );
}

sub _values_clause
{
    my $self = shift;

    my @v;
    for my $vals ( @{ $self->{values} } )
    {
        my $v = '(';

        $v .=
            ( join ', ',
              map { $vals->{ $_->name() }->sql( $self->formatter() ) }
              @{ $self->{columns} }
           );

        $v .= ')';

        push @v, $v;
    }

    return 'VALUES ' . join ',', @v;
}



1;

__END__
