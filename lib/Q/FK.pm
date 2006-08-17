package Q::FK;

use strict;
use warnings;

use Q::Exceptions qw(param_error);
use Q::Validate
    qw( validate OBJECT ARRAYREF );

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

        return bless { source => \@source,
                       target => \@target,
                     }, $class;
    }
}

sub source_table { $_[0]->{source}[0]->table() }
sub target_table { $_[0]->{target}[0]->table() }

sub source_columns { @{ $_[0]->{source} } }
sub target_columns { @{ $_[0]->{target} } }


1;

__END__
