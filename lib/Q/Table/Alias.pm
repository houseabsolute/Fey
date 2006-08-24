package Q::Table::Alias;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( alias_name table ) );

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate validate_pos
        SCALAR_TYPE
        TABLE_TYPE );

use Q::Table;

{
    for my $meth ( qw( schema name primary_key ) )
    {
        eval <<"EOF";
sub $meth
{
    shift->table()->$meth(\@_);
}
EOF
    }
}

{
    my %Numbers;
    my $spec = { table      => TABLE_TYPE,
                 alias_name => SCALAR_TYPE( optional => 1 ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        unless ( $p{alias_name} )
        {
            my $name = $p{table}->name();
            $Numbers{$name} ||= 1;

            $p{alias_name} = $name . $Numbers{$name}++;
        }

        return bless \%p, $class;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub column
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return $self->{columns}{$name}
            if $self->{columns}{$name};

        my $col = $self->table()->column($name)
            or return;

        my $clone = $col->clone();
        $clone->_set_table($self);

        return $self->{columns}{$name} = $clone;
    }
}

sub columns
{
    my $self = shift;

    return map { $self->column( $_->name() ) } $self->table()->columns();
}

sub is_alias { 1 }

sub id { $_[0]->alias_name() }

sub isa
{
    my $self  = shift;
    my $class = shift;

    return 1 if $class eq 'Q::Table';

    return $self->SUPER::isa($class);
}


1;

__END__
