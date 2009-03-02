package Fey::Literal::Aliasable;

use MooseX::Role::Parameterized;

parameter generated_alias_prefix =>
    ( isa     => 'Str',
      default => 'LITERAL',
    );

requires 'sql';

role
{
    my $p = shift;

    my $Num = 0;

    has 'alias_name' =>
        ( is     => 'rw',
          isa    => 'Str',
          writer => 'set_alias_name',
        );

    method '_make_alias' => sub
    {
        my $self = shift;
        $self->set_alias_name( $p->generated_alias_prefix . $Num++ );
    };

    method 'sql_with_alias' => sub
    {
        $_[0]->_make_alias()
            unless $_[0]->alias_name();

        my $sql = $_[0]->sql( $_[1] );

        $sql .= ' AS ';
        $sql .= $_[1]->quote_identifier( $_[0]->alias_name() );

        return $sql;
    };

    method 'sql_or_alias' => sub 
    {
        return $_[1]->quote_identifier( $_[0]->alias_name() )
            if $_[0]->alias_name();

        return $_[0]->sql( $_[1] );
    };

};

no MooseX::Role::Parameterized;

1;
