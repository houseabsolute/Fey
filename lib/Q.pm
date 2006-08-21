package Q;

use strict;
use warnings;

our $VERSION = '0.01';


1;

__END__

=head1 NAME

Q - The fantastic new Q!

=head1 SYNOPSIS

Perhaps a little code snippet.

  use Q;

  my $foo = Q->new;

=head1 DESCRIPTION

The goal of this module is to provide a (relatively) simple, flexible
way to I<dynamically> generate SQL queries from Perl. The emphasis
here is on dynamic, and by that I mean that the structure of the SQL
query may change dynamically.

This is different from simply changing the parameters of a query
dynamically. For example:

 SELECT user_id FROM User where username = ?

While this is a dynamic query in the sense that the username is
parameter-ized, and may change on each invocation, it is still easily
handled by a phrasebook class. If that is all you need, I suggest
checking out C<Class::Phrasebook::SQL>, C<Data::Phrasebook>, and
C<SQL::Library> on CPAN.

=head2 Why Not Use a Phrasebook?

Let's assume we have a simple User table with the following columns:

 username
 state
 first_name
 last_name
 access_level

Limiting ourselves to queries of equality ("username = ?"), we would
still need 32 (1 + 5 + 10 + 10 + 5 + 1) entries to handle all the
possible combinations. Now imagine adding in variants like allowing
for wildcard searches using LIKE or regexes, or more complex variants
involving an "OR" in a subclause.

This gets even more complicated if you start adding in joins, outer
joins, and so on. It's plain to see that a phrasebook gets too large
to be usable at this point, and you'd probably have to write a program
just to generate the phrasebook and keep it up to date at this point!

=head2 Why Not String Manipulation?

The first solution that might come to mind is to dump the phrasebook
in favor of string manipulation. This is simple enough at first, but
quickly gets ugly. Handling all of the possible options correctly
requires lots of fiddly code that has to concatenate bits of SQL in
the correct order.

=head2 The Solution

Hopefully, this module provides a solution to this problem. It allows
you to specify queries in the form of I<Perl data structures>. It
provides a set of objects to represent specific parts of a schema,
specifically tables, columns, and foreign keys. Using these objects
you can easily generate very complex queries by combining them with
strings and passing them to the appropriate query-generating method.

I also hope that this module can be used as a building block to build
other tools. A good example would be a tool for generating DDL
statements (like Alzabo ;).

=head1 HISTORY AND GOALS

This module comes from my experience writing and using Alzabo. Alzabo
does everything this module does, and a lot more. The fact that Alzabo
does so many things has become a bit problematic in its maintenance,
and Alzabo is over 6 years old at this time (August of 2006).

=head2 Problems with Alzabo

Here are some of the problems I've had with Alzabo over the years:

=over 4

=item *

Adding support for a new RDBMS is a lot of work, so it only supports
MySQL and Pg. Alzabo tried to be really smart about preventing users
from shooting themselves in the foot, and required a lot of specific
code for each DBMS to achieve this.

=item *

It doesn't support multiple versions of a DBMS very well. Either it
doesn't work with an older version at all, or it doesn't support some
enhanced capability of a newer version.

On a side note, if DBMS's were to provide a standard API for asking
questions about their DDL syntax and vcapabilities like "what is the
max number of chars in a column name?" or "what data are the names of
each data type?" that would have made things infinitely easier.

=item *

There are now free GUI design tools for specific databases that do a
better job of supporting the database in question.

=item *

Alzabo separates its classes into Create (for generation of DDL) and
Runtime (for DML) subclasses, which might have been worth the memory
savings six years ago, but just makes for an extra hassle now.

=item *

When I originally developed Alzabo, I thought that generating OO
classes that subclasses the Alzabo classes and added "business logic"
methods was a good idea, thus C<Alzabo::MethodMaker>. Nowadays, I
prefer to have my business logic classes simple use the Alzabo
classes. In other words, I now prefer "has-a" versus "is-a" object
design for this case.

Method auto-generation based on a specific schema can be quite handy,
but it should be done in the domain-specific classes, not as a
subclass of the core functionality.

=item *

Storing schemas in an Alzabo-specific format is problematic for many
obvious reasons. It's simpler to simply get the schema definition from
an existing schema, or to allow users to define it in code.

=item *

Alzabo's referential integrity checking was really cool back when I
mostly used MySQL with MYISAM tables, but is a burden nowadays.

=item *

I didn't catch the testing bug until quite a while after I'd started
working on Alzabo. Alzabo's test suite is nasty. Q will be built for
testability, and I'll make sure that high test coverage is part of my
ongoing goals.

=item *

Alzabo does too many things, which makes it hard to explain and
document.

=back

=head2 Goals

Overall, rather than coming up with a very smart solution that allows
us to use 80% of a DBMS's functionality, I'd rather come up with a
100% solution that's dumber. It's easy to add smarts on top of a dumb
layer, but it can be terribly hard to add that last 20% once you've
got something really smart.

A good example of this is Alzabo's support of database functions like
"AVG" or "SUM". It supports them in a very clever way, but adding
support for a new function can be a pain, especially if it has odd
syntax.

The goals for Q, based on my experience with Alzabo, are the
following:

=over 4

=item *

Provide a simple way to generate queries dynamically. I really like
the way this works with Alzabo, except that Alzabo is not as flexible
as I'd like.

Specifically, I want to be able to issue updates and deletes to more
than one row at a time. I want support for sub-selects, unions,
etc. and all that other good stuff.

=item *

I want complex query creation to requires less fiddliness than
Alzabo. This means that class to represent queries will be a little
smarter and more flexible about the order in which bits are added.

For example, in using Alzabo I often come across cases where I want to
add a table to a query's join I<if it hasn't already been
added>. Right now there's no nice simple way to do this. Specifying
the table twice will cause an error. It would be nice to simply be
able to do this:

  $query->join( $foo_table => $bar_table )
      unless $query->join_includes($bar_table);

=item *

Provide the base for a tool that does what the C<Alzabo::Runtime::Row>
class does. There will be a separate tool that takes query results and
turns them into low-level "row" objects instead of returning them as
DBI statement handles.

This tool will support something like Alzabo's "potential" rows, which
are objects that have the same API as these row objects, but do not
represent data in the DBMS.

Finally, it will have support the same type of simple "unique row
cache" that Alzabo provides. This type of dirt-simple caching has
proven to be a big win in many applications I've written.

=back

=head1 OTHER MODULES

This module is based on many years of using and maintaining C<Alzabo>,
which is a much more ambitious project. There are modules similar to
this one on CPAN:

=over 4

=item * SQL::Abstract

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-q@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
