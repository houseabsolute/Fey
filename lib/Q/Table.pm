package Q::Table;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name is_view ) );

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate validate_pos
        SCALAR_TYPE BOOLEAN_TYPE
        COLUMN_TYPE );
use Scalar::Util qw( blessed );

use Q::Column;


{
    my $spec = { name    => SCALAR_TYPE,
                 is_view => BOOLEAN_TYPE( default => 0 ),
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $self =
            bless { %p,
                    columns => {},
                  }, $class;

        return $self;
    }
}

{
    my @spec = (COLUMN_TYPE);
    sub add_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, @spec );

        my $name = $col->name();
        param_error "The table already has a column named $name."
            if $self->column($name);

        $self->{columns}{$name} = $col;

        return $self;
    }
}

{
    my $spec = (SCALAR_TYPE);
    sub column
    {
        my $self = shift;
        my ($name) = validate_pos( @_, $spec );

        return unless $self->{columns}{$name};
        return $self->{columns}{$name};
    }
}

sub columns
{
    my $self = shift;

    return values %{ $self->{columns} };
}

{
    my $spec = (COLUMN_TYPE);
    sub remove_column
    {
        my $self = shift;
        my ($col) = validate_pos( @_, $spec );

        my $name = $col->name();

        delete $self->{columns}{$name};

        return $self;
    }
}

{
    my $spec =
        { callbacks =>
          { 'scalar or column' =>
            sub {
                return ( ( blessed( $_[0] ) && $_[0]->isa('Q::Column') )
                         || ! ref $_[0]
                       ) },
          },
        };
    sub set_primary_key
    {
        my $self = shift;
        my @names =
            ( map { ref $_ ? $_->name() : $_ }
              validate_pos( @_, ($spec) x @_ )
            );

        for my $name (@names)
        {
            param_error "The column $name is not part of the " . $self->name() . ' table.'
                unless $self->column($name);
        }

        $self->{pk} = [ map { $self->column($_) } @names ];

        return $self;
    }
}

sub primary_key { @{ $_[0]->{pk} } }


1;

__END__
