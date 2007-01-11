package Fey::Column::Alias;

use strict;
use warnings;

use base 'Fey::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( alias_name column ) );

use Class::Trait ( 'Fey::Trait::ColumnLike' );

use Fey::Exceptions qw( object_state_error );
use Fey::Validate
    qw( validate
        SCALAR_TYPE
        COLUMN_TYPE );

use Fey::Column;

{
    for my $meth ( qw( name type generic_type length precision
                       is_auto_increment is_nullable table ) )
    {
        eval <<"EOF";
sub $meth
{
    shift->column()->$meth(\@_);
}
EOF
    }
}

{
    my %Numbers;
    my $spec = { column     => COLUMN_TYPE,
                 alias_name => SCALAR_TYPE( optional => 1 ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        unless ( $p{alias_name} )
        {
            my $name = $p{column}->name();
            $Numbers{$name} ||= 1;

            $p{alias_name} = $name . $Numbers{$name}++;
        }

        return bless \%p, $class;
    }
}

sub id
{
    my $self = shift;

    my $table = $self->table();

    object_state_error
        'The id() method cannot be called on a column alias object which has no table.'
            unless $table;

    return $table->id() . '.' . $self->alias_name();
}

sub is_alias { 1 }

sub sql { $_[1]->quote_identifier( $_[0]->alias_name() ) }

sub sql_with_alias
{
    my $sql =
        $_[1]->join_table_and_column
            ( $_[1]->quote_identifier( $_[0]->_containing_table_name_or_alias() ),
              $_[1]->quote_identifier( $_[0]->name() )
            );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
}

sub sql_or_alias { goto &sql }

sub isa
{
    my $self  = shift;
    my $class = shift;

    return 1 if $class eq 'Fey::Column';

    return $self->SUPER::isa($class);
}


1;

__END__
