package Fey::Query;

use strict;
use warnings;

use base 'Fey::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh quoter ) );

use Fey::Exceptions qw( param_error virtual_method );
use Fey::Validate
    qw( validate
        validate_pos
        SCALAR
        OBJECT
        POS_INTEGER_TYPE
        POS_OR_ZERO_INTEGER_TYPE
        DBI_TYPE
      );

use Scalar::Util qw( blessed );

use Fey::Query::Delete;
use Fey::Query::Insert;
use Fey::Query::Select;
use Fey::Query::Update;

use Fey::Placeholder;

use Fey::Quoter;

use Fey::Query::Fragment::Where::Boolean;
use Fey::Query::Fragment::Where::Comparison;
use Fey::Query::Fragment::Where::SubgroupStart;
use Fey::Query::Fragment::Where::SubgroupEnd;

{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quoter = Fey::Quoter->new( dbh => $p{dbh} );

        return bless { %p,
                       quoter => $quoter,
                     }, $class;
    }
}

sub select
{
    my $self = shift;

    $self->_rebless_for( 'select', @_ );
}

sub insert
{
    my $self = shift;

    return $self->_rebless_for( 'insert', @_ );
}

sub update
{
    my $self = shift;

    $self->_rebless_for( 'update', @_ );
}

sub delete
{
    my $self = shift;

    $self->_rebless_for( 'delete', @_ );
}

sub _rebless_for
{
    my $self = shift;
    my $type = shift;

    my $class = (ref $self) . '::' . ucfirst $type;

    my $new = $class->new( dbh => $self->dbh() );

    %$self = %$new;

    bless $self, ref $new;

    return $self->$type(@_);
}

sub where
{
    my $self = shift;

    $self->_condition( 'where', @_ );

    return $self;
}

{
    my %dispatch = ( 'and' => '_and',
                     'or'  => '_or',
                     '('   => '_subgroup_start',
                     ')'   => '_subgroup_end',
                   );
    sub _condition
    {
        my $self = shift;
        my $key  = shift;

        if ( @_ == 1 )
        {
            if ( my $meth = $dispatch{ lc $_[0] } )
            {
                $self->$meth($key);
                return;
            }
        }

        if ( @{ $self->{$key} || [] }
             && ! (    $self->{$key}[-1]->isa('Fey::Query::Fragment::Where::Boolean')
                    || $self->{$key}[-1]
                            ->isa('Fey::Query::Fragment::Where::SubgroupStart')
                  )
           )
        {
            $self->_and($key);
        }

        push @{ $self->{$key} },
            Fey::Query::Fragment::Where::Comparison->new(@_);
    }
}

sub _and
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::Query::Fragment::Where::Boolean->new( 'AND' );

    return $self;
}

sub _or
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::Query::Fragment::Where::Boolean->new( 'OR' );

    return $self;
}

sub _subgroup_start
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::Query::Fragment::Where::SubgroupStart->new();

    return $self;
}

sub _subgroup_end
{
    my $self = shift;
    my $key  = shift;

    push @{ $self->{$key} },
        Fey::Query::Fragment::Where::SubgroupEnd->new();

    return $self;
}

sub placeholder { Fey::Placeholder->new() }

{
    my $spec = { type      => SCALAR|OBJECT,
                 callbacks =>
                 { 'is orderable or sort direction' =>
                   sub { return 1
                             if ! blessed $_[0] && $_[0] =~ /^(?:asc|desc)$/i;
                         return 1 if
                             (    blessed $_[0]
                               && $_[0]->can('is_orderable')
                               && $_[0]->is_orderable() ); },
                 },
               };

    sub order_by
    {
        my $self = shift;

        my $count = @_ ? @_ : 1;
        my (@by) = validate_pos( @_, ($spec) x $count );

        push @{ $self->{order_by} }, @by;
    }
}

{
    my @spec = ( POS_INTEGER_TYPE, POS_OR_ZERO_INTEGER_TYPE( optional => 1 ) );
    sub limit
    {
        my $self = shift;
        my @limit = validate_pos( @_, @spec );

        $self->{limit}{number} = $limit[0];
        $self->{limit}{offset} = $limit[1];
    }
}

sub _where_clause
{
    return unless $_[0]->{where};

    return ( 'WHERE '
             . ( join ' ',
                 map { $_->sql( $_[0]->quoter() ) }
                 @{ $_[0]->{where} }
               )
           )
}

sub _order_by_clause
{
    my $self = shift;

    return unless $self->{order_by};

    my $sql = 'ORDER BY ';

    for my $elt ( @{ $self->{order_by} } )
    {
        if ( ! blessed $elt )
        {
            $sql .= q{ } . uc $elt;
        }
        else
        {
            $sql .= ', ' if $elt != $self->{order_by}[0];
            $sql .= $elt->sql_or_alias( $self->quoter() );
        }
    }

    return $sql;
}

sub _limit_clause
{
    my $self = shift;

    return unless $self->{limit}{number};

    my $sql = 'LIMIT ' . $self->{limit}{number};
    $sql .= ' OFFSET ' . $self->{limit}{offset}
        if $self->{limit}{offset};

    return $sql;
}


1;

__END__
