package Fey::Literal::Aliasable;

use MooseX::Role::Parameterized;

parameter generated_alias_prefix =>
    ( isa     => 'Str',
      default => 'LITERAL',
    );

has 'alias_name' =>
    ( is     => 'rw',
      isa    => 'Str',
      writer => 'set_alias_name',
    );

requires 'sql';

sub sql_with_alias
{
    $_[0]->_make_alias()
        unless $_[0]->alias_name();

    my $sql = $_[0]->sql( $_[1] );

    $sql .= ' AS ';
    $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

    return $sql;
};

sub sql_or_alias
{
    return $_[1]->quote_identifier( $_[0]->alias_name() )
        if $_[0]->alias_name();

    return $_[0]->sql( $_[1] );
};


role
{
    my $p = shift;

    my $Num = 0;

    my $prefix = $p->generated_alias_prefix;

    method '_make_alias' => sub
    {
        my $self = shift;
        $self->set_alias_name( $prefix . $Num++ );
    };

};

no MooseX::Role::Parameterized;

1;
