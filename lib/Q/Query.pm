package Q::Query;

use strict;
use warnings;

use base 'Q::Accessor';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh formatter ) );

use Q::Exceptions qw( param_error virtual_method );
use Q::Validate
    qw( validate
        OBJECT
        DBI_TYPE );

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

    $self->_rebless('Q::Query::Select');

    return $self->select(@_);
}

sub _rebless
{
    my $self  = shift;
    my $class = shift;

    my $new = $class->new( dbh => $self->dbh() );

    %$self = %$new;

    bless $self, ref $new;
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

sub _where_clause
{
    return unless $_[0]->{where};

    return join ' ',
        map { $_->as_sql( $_[0]->formatter() ) } @{ $_[0]->{where} };
}

sub _group_by_clause
{
    return ();
}

sub _order_by_clause
{
    return ();
}

sub _limit_clause
{
    return ();
}


1;

__END__
