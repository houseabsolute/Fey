package Q::Query;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh formatter ) );

use Q::Exceptions qw( param_error virtual_method );
use Q::Validate
    qw( validate
        validate_pos
        SCALAR
        OBJECT
        POS_INTEGER_TYPE
        POS_OR_ZERO_INTEGER_TYPE
        DBI_TYPE
      );

use Scalar::Util qw( blessed );

use Q::Query::Delete;
use Q::Query::Insert;
use Q::Query::Select;
use Q::Query::Update;

use Q::Placeholder;

use Q::Query::Formatter;

use Q::Query::Fragment::Where::Boolean;
use Q::Query::Fragment::Where::Comparison;
use Q::Query::Fragment::Where::SubgroupStart;
use Q::Query::Fragment::Where::SubgroupEnd;

{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $formatter = Q::Query::Formatter->new( dbh => $p{dbh} );

        return bless { %p,
                       formatter => $formatter,
                     }, $class;
    }
}

sub select
{
    my $self = shift;

    my $class = (ref $self) . '::Select';
    $self->_rebless($class);

    return $self->select(@_);
}

sub insert
{
    my $self = shift;

    my $class = (ref $self) . '::Insert';
    $self->_rebless($class);

    return $self->insert(@_);
}

sub _rebless
{
    my $self  = shift;
    my $class = shift;

    my $new = $class->new( dbh => $self->dbh() );

    %$self = %$new;

    bless $self, ref $new;

    return $self;
}

sub where
{
    my $self = shift;

    if ( @{ $self->{where} || [] }
         && ! (    $self->{where}[-1]->isa('Q::Query::Fragment::Where::Boolean')
                || $self->{where}[-1]
                       ->isa('Q::Query::Fragment::Where::SubgroupStart')
              )
       )
    {
        $self->and();
    }

    push @{ $self->{where} },
        Q::Query::Fragment::Where::Comparison->new(@_);

    return $self;
}

sub subgroup_start
{
    my $self = shift;

    push @{ $self->{where} },
        Q::Query::Fragment::Where::SubgroupStart->new();

    return $self;
}

sub subgroup_end
{
    my $self = shift;

    push @{ $self->{where} },
        Q::Query::Fragment::Where::SubgroupEnd->new();

    return $self;
}

sub and
{
    my $self = shift;

    push @{ $self->{where} },
        Q::Query::Fragment::Where::Boolean->new( 'AND' );

    return $self;
}

sub or
{
    my $self = shift;

    push @{ $self->{where} },
        Q::Query::Fragment::Where::Boolean->new( 'OR' );

    return $self;
}

sub placeholder { Q::Placeholder->new() }

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
                 map { $_->sql( $_[0]->formatter() ) }
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
            $sql .= $elt->sql_or_alias( $self->formatter() );
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
