package Q::Literal::Function;

use strict;
use warnings;

use base 'Q::Literal';
__PACKAGE__->mk_ro_accessors
    ( qw( alias_name function ) );

use Class::Trait ( 'Q::Trait::Selectable' );
use Class::Trait ( 'Q::Trait::Comparable' );
use Class::Trait ( 'Q::Trait::Groupable' => { exclude => 'is_groupable' } );
use Class::Trait ( 'Q::Trait::Orderable' => { exclude => 'is_orderable' } );

use Q::Validate
    qw( validate_pos
        SCALAR_TYPE
        SCALAR
        OBJECT
      );

use Scalar::Util qw( blessed );


{
    my $func_spec = SCALAR_TYPE;
    my $arg_spec  = { type      => SCALAR|OBJECT,
                      callbacks =>
                      { 'is scalar, column (with table) or literal'
                        => sub {    ! blessed $_[0]
                                 || (    $_[0]->isa('Q::Column')
                                      && $_[0]->table() )
                                 || $_[0]->isa('Q::Literal') }
                      },
                    };
    sub new
    {
        my $class = shift;
        my ( $func, @args ) = validate_pos( @_, $func_spec, ($arg_spec) x (@_ - 1) );

        my $self = bless { function => $func };
        $self->{args} =
            [ map { blessed $_ ? $_ : Q::Literal->new_from_scalar($_) } @args ];

        return $self;
    }
}

sub args { @{ $_[0]->{args} } }

sub sql
{
    my $sql = $_[0]->function();
    $sql .= '(';

    $sql .=
        ( join ', ',
          map { $_->sql( $_[1] ) }
          $_[0]->args()
        );
    $sql .= ')';
}

sub sql_with_alias
{
    $_[0]->_make_alias()
        unless $_[0]->alias_name();

    my $sql = $_[0]->sql( $_[1] );

    $sql .= ' AS ';
    $sql .= $_[0]->alias_name();

    return $sql;
}

{
    my $Number = 0;
    sub _make_alias
    {
        $_[0]->{alias_name} = 'FUNCTION' . $Number++;
    }
}

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->alias_name() )
        if $_[0]->alias_name();

    return $_[0]->sql( $_[1] );
}

sub is_groupable { $_[0]->alias_name() ? 1 : 0 }

sub is_orderable { $_[0]->alias_name() ? 1 : 0 }


1;

__END__
