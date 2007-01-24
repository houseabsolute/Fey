package Fey::Quoter;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_ro_accessors
    ( qw( dbh ) );

use Fey::Validate
    qw( validate
        DBI_TYPE );

{
    my $spec = { dbh => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $quote = $p{dbh}->get_info(29);
        $quote = q{"} unless defined $quote;

        # Not sure if this needs to be changed per-DBMS, and if so,
        # can it be discovered from the database handle (portably)?
        my $sep = q{.};

        return bless { %p,
                       quote => $quote,
                       sep   => $sep,
                     }, $class;
    }
}

sub quote_identifier
{
    return $_[0]->{quote} . $_[1] . $_[0]->{quote};
}

sub unquote_identifier
{
    my $self  = shift;
    my $ident = shift;

    $ident =~ s/^\Q$self->{quote}\E|\Q$self->{quote}\E$//g;

    return $ident;
}

sub quote_string
{
    return $_[0]->dbh()->quote( $_[1] );
}

sub join_table_and_column
{
    return $_[1] . $_[0]->{sep} . $_[2];
}


1;

__END__

=head1 NAME

Fey::Quoter - Provides quoting and other related string manipulations

=head1 SYNOPSIS

  my $quoter = Fey::Quoter->new( dbh => $dbh )

  print $quoter->quote_identifier( $column->name() );
  print $quoter->unquote_identifier( $quoted_name );
  print $quoter->join_table_and_column( $table->name(), $column->name() );

=head1 DESCRIPTION

This class provides methods for quoting and related string
manipulations needed to generate valid SQL.

=head1 METHODS

This class provides the following methods:

=head2 Fey::Quoter->new( dbh => $dbh )

This method creates a new C<Fey::Quoter> object. It requires a C<DBI>
handle for the "dbh" parameter.

=head2 $quoter->dbh()

Returns the C<DBI> handle passed to the constructor.

=head2 $quoter->quote_identifier($identifier)

This does the proper quoting for an identifier, like a column or table
name.

It tries to determines how to do this by asking the C<DBI> handle
passed to the constructor, using the C<< $dbh->get_info() >>
method. It falls back to using double-quotes (C<">).

=head2 $quoter->unquote_identifier($identifier)

This strips quotes from an identifier name. It is provided for the
benefit of the C<Fey::Loader> modules.

=head2 $quoter->quote_string($string)

This quotes a string for use as a value (like in an C<UPDATE> or
C<INSERT> clause). Internally it just calls C<< $dbh->quote() >>.

=head2 $quoter->join_table_and_column( $table_name, $column_name )

This joins together a table and column to form a fully-qualified
reference to a column. This always uses the period character (C<.>) as
the separator.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

See C<Fey::Core> for details on how to report bugs.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
