package Q::Column;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( name type generic_type length precision
          is_auto_increment is_nullable table ) );

use Scalar::Util qw( weaken );

use Q::Exceptions qw( object_state_error );
use Q::Validate
    qw( validate validate_pos
        UNDEF OBJECT
        SCALAR_TYPE BOOLEAN_TYPE
        POS_INTEGER_TYPE POS_OR_ZERO_INTEGER_TYPE
        TABLE_TYPE );

use Q::Column::Alias;


{
    my $gen_type_re =
        qr/text|blob|integer|float|date|datetime|time|boolean|other/;

    my $spec =
        { name              => SCALAR_TYPE,
          generic_type      => SCALAR_TYPE( regex    => $gen_type_re,
                                            optional => 1,
                                          ),
          type              => SCALAR_TYPE,
          length            => POS_INTEGER_TYPE( optional => 1 ),
          precision         => POS_OR_ZERO_INTEGER_TYPE( optional => 1,
                                                         depends => [ 'length' ] ),
          is_auto_increment => BOOLEAN_TYPE( default => 0 ),
          is_nullable       => BOOLEAN_TYPE( default => 0 ),
          table             => TABLE_TYPE( optional => 1 ),
        };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        $p{generic_type}
            ||= $class->_guess_generic_type( $p{type} );

        my $self = bless \%p, $class;

        return $self;
    }
}

{
    my @TypesRe =
        ( [ text     => qr/(?:text|char(?:acter)?)\b/i ],
          [ blob     => qr/blob\b|bytea\b/i ],
          # The year type comes from MySQL
          [ integer  => qr/(?:int(?:eger)?\d*|year)\b/i ],
          [ float    => qr/(?:float\d*|decimal|real|double|money|numeric)\b/i ],
          # MySQL's timestamp is not always a datetime, it depends on
          # the length of the column, but this is the best _guess_.
          [ datetime => qr/datetime\b|^timestamp/i ],
          [ date     => qr/date\b/i ],
          [ time     => qr/^time|time\b/i ],
          [ boolean  => qr/\bbool/i ],
        );

    sub _guess_generic_type
    {
        my $type = $_[1];

        for my $p (@TypesRe)
        {
            return $p->[0] if $type =~ /$p->[1]/;
        }

        return 'other';
    }
}

{
    # This method is private but intended to be called by Q::Table and
    # Q::Table::Alias but not by anything else.
    my $spec = ( { type => UNDEF | OBJECT,
                   callbacks =>
                   { 'undef or table' =>
                     sub { ! defined $_[0]
                           || $_[0]->isa('Q::Table') },
                   },
                 } );
    sub _set_table
    {
        my $self    = shift;
        my ($table) = validate_pos( @_, $spec );

        $self->{table} = $table;
        weaken $self->{table}
            if $self->{table};

        return $self
    }
}

sub id
{
    my $self = shift;

    my $table = $self->table();

    object_state_error
        'The id() method cannot be called on a column object which has no table.'
            unless $table;

    return $table->id() . '.' . $self->name();
}

sub clone
{
    my $self = shift;

    my %clone = %$self;

    return bless \%clone, ref $self;
}

sub is_alias { 0 }

sub alias
{
    my $self = shift;

    return Q::Column::Alias->new( column => $self, @_ );
}


1;

__END__
