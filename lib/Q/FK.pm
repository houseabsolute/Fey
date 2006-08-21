package Q::FK;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( id ) );

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate validate_pos
        OBJECT ARRAYREF
        COLUMN_TYPE
        TABLE_OR_NAME_TYPE );

use List::Util qw( first );
use List::MoreUtils qw(uniq);
use Scalar::Util qw(blessed);


{
    my $col_array_spec =
        { type => OBJECT|ARRAYREF,
          callbacks =>
          { 'all elements are columns' =>
            sub { ( ! grep { ! $_->isa('Q::Column') }
                    blessed $_[0] ? $_[0] : @{ $_[0] } ) }
          },
        };
    my $spec = { source => $col_array_spec,
                 target => $col_array_spec,
               };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my @source = blessed $p{source} ? $p{source} : @{ $p{source} };
        my @target = blessed $p{target} ? $p{target} : @{ $p{target} };

        if ( @source != @target )
        {
            param_error
                ( "The source and target arrays passed to add_foreign_key()"
                  . " must contain the same number of columns." );
        }

        if ( grep { ! $_->table() } @source, @target )
        {
            param_error "All columns passed to add_foreign_key() must have a table.";
        }

        for my $p ( [ source => \@source ], [ target => \@target ]  )
        {
            my ( $name, $array ) = @$p;
            if ( uniq( map { $_->table() } @$array ) > 1 )
            {
                param_error
                    ( "Each column in the $name argument to add_foreign_key()"
                      . " must come from the same table." );
            }
        }

        my $id = join "\0",
                 sort
                 map { $_->table()->name() . '.' . $_->name() }
                 @source, @target;

        return bless { source => \@source,
                       target => \@target,
                       id     => $id,
                     }, $class;
    }
}

sub source_table { $_[0]->{source}[0]->table() }
sub target_table { $_[0]->{target}[0]->table() }

{
    my $spec = (TABLE_OR_NAME_TYPE);
    sub has_tables
    {
        my $self = shift;
        my ( $table1, $table2 ) = validate_pos( @_, $spec, $spec );

        my $name1 = blessed $table1 ? $table1->name() : $table1;
        my $name2 = blessed $table2 ? $table2->name() : $table2;

        my @looking_for = sort $name1, $name2;
        my @have =
            sort map { $_->name() } $self->source_table(), $self->target_table();

        return 1
            if (    $looking_for[0] eq $have[0]
                 && $looking_for[1] eq $have[1] );
   }
}

{
    my $spec = (COLUMN_TYPE);
    sub has_column
    {
        my $self  = shift;
        my ($col) = validate_pos( @_, $spec );

        my $table_name = $col->table()->name();

        my @cols;
        for my $part ( qw( source target ) )
        {
            my $table_meth = $part . '_table';
            if ( $self->$table_meth()->name() eq $table_name )
            {
                my $col_meth = $part . '_columns';
                @cols = $self->$col_meth();
            }
        }

        return 0 unless @cols;

        my $col_name = $col->name();

        return 1 if grep { $_->name() eq $col_name } @cols;

        return 0;
    }
}

sub source_columns { @{ $_[0]->{source} } }
sub target_columns { @{ $_[0]->{target} } }



1;

__END__
