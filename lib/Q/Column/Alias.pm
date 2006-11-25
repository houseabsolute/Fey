package Q::Column::Alias;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( alias_name column ) );

use Class::Trait ( 'Q::Trait::Selectable' );

use Q::Exceptions qw( object_state_error );
use Q::Validate
    qw( validate
        SCALAR_TYPE
        COLUMN_TYPE );

use Q::Column;

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

sub sql_for_select
{
    my $sql =
        $_[1]->table_and_column( $_[0]->_table_name_or_alias(), $_[0]->name() );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
}

sub sql_for_function_arg { $_[0]->alias_name() }

sub _table_name_or_alias
{
    my $t = $_[0]->table();

    $t->is_alias() ? $t->alias_name() : $t->name();
}

sub isa
{
    my $self  = shift;
    my $class = shift;

    return 1 if $class eq 'Q::Column';

    return $self->SUPER::isa($class);
}


1;

__END__
