package Fey::Core;

use strict;
use warnings;

our $VERSION = '0.01';


use Fey::Column;
use Fey::FK;
use Fey::SQL;
use Fey::Schema;
use Fey::Table;


1;

__END__

=head1 NAME

Fey::Core - Core classes for Fey

=head1 SYNOPSIS

  use Fey::Core;

  # loads all the modules in the Fey::Core distro

=head1 DESCRIPTION

The C<Fey::Core> distribution contains a set of modules for
representing the components of a DBMS schema, and for dynamically
generating SQL queries based on that schema.

=head1 USAGE

The C<Fey::Core> I<module> itself provides no methods. Loading this
module simply loads the various modules in the C<Fey::Core>
distribution, such as C<Fey::Schema>, F<Fey::Table>, C<Fey::Column>,
etc.

=head1 WHAT IS Fey::Core?

The goal of the C<Fey::Core> is to provide a (relatively) simple,
flexible way to I<dynamically> generate complex SQL queries in
Perl. The emphasis here is on dynamic, and by that I mean that the
structure of the SQL query may change dynamically.

This is different from simply changing the parameters of a query
dynamically. For example:

 SELECT user_id FROM User where username = ?

While this is a dynamic query in the sense that the username is
parameter-ized, and may change on each invocation, it is still easily
handled by a phrasebook class. If that is all you need, I suggest
checking out C<Class::Phrasebook::SQL>, C<Data::Phrasebook>, or
C<SQL::Library> on CPAN.

=head2 Why Not Use a Phrasebook?

Let's assume we have a simple User table with the following columns:

 username
 state
 first_name
 last_name
 access_level

Limiting ourselves to queries of equality ("username = ?", "state =
?"), we would still need 32 (1 + 5 + 10 + 10 + 5 + 1) entries to
handle all the possible combinations of columns. Now imagine adding in
variants like allowing for wildcard searches using LIKE or regexes, or
more complex variants involving an "OR" in a subclause.

This gets even more complicated if you start adding in joins, outer
joins, and so on. It's plain to see that a phrasebook gets too large
to be usable at this point. You'd probably have to write a program
just to generate the phrasebook and keep it up to date!

=head2 Why Not String Manipulation?

The next idea that might come to mind is to dump the phrasebook in
favor of string manipulation. This is simple enough at first, but
quickly gets ugly. Handling all of the possible options correctly
requires lots of fiddly code that has to concatenate bits of SQL in
the correct order.

=head2 The Solution

Hopefully, this module provides a solution to this problem. It allows
you to specify queries in the form of I<Perl methods and data
structures>. It provides a set of objects to represent the parts of a
schema, specifically tables, columns, and foreign keys. Using these
objects you can easily generate very complex queries by combining them
with strings and passing them to the appropriate query-generating
method.

I also hope that this module can be used as a building block to build
other tools. A good example would be an RDBMS-OO mapper.

=head2 Random ideas to elaborate on ...

* Why building queries via method calls on objects is easier
* Join support is crucial
* De-coupling of query from ORM

=head1 HISTORY AND GOALS

This module comes from my experience writing and using Alzabo. Alzabo
does everything this module does, and a lot more. The fact that Alzabo
does so many things has become a fairly problematic in its
maintenance, and Alzabo was over 6 years old at the time this project
was begun (August of 2006).

=head2 Goals

Rather than coming up with a very smart solution that allows us to use
80% of a DBMS's functionality, I'd rather come up with a 100% solution
that's dumber. It's easy to add smarts on top of a dumb layer, but it
can be terribly hard to add that last 20% once you've got something
really smart.

The goals for Fey, based on my experience with Alzabo, are the
following:

=over 4

=item *

Provide a simple way to generate queries dynamically. I really like
how this works with Alzabo conceptually, but Alzabo is not as flexible
as I'd like and it's "biuld a data structure" approach to query
building can become very cumbersome.

Specifically, Fey will be able to issue updates and deletes to more than
one row at a time. Fey will support sub-selects, unions, etc. and all
that other good stuff.

=item *

Fey will support complex query creation with less fiddliness than
Alzabo. This means that the class to represent queries will be a
little smarter and more flexible about the order in which bits are
added.

For example, in using Alzabo I often come across cases where I want to
add a table to a query's join I<if it hasn't already been
added>. Right now there's no nice simple way to do this. Specifying
the table twice will cause an error. It would be nice to simply be
able to do this

  $select->join( $foo_table => $bar_table );

and have it do the right thing if that join already
exists. C<Fey::SQL> does exactly that.

=item *

Provide the core for an RDBMS-OO mapper similar to a combination of
C<Alzabo::Runtime::Row> and C<Class::AlzaboWrapper>.

This mapper will support something like Alzabo's "potential" rows,
which are objects that have the same API as these row objects, but do
not represent data in the DBMS.

Finally, it will have support the same type of simple "unique
row/object cache" that Alzabo provides. This type of dirt-simple
caching has proven to be a big win in many applications I've written.

=item *

Be declarative like Moose. In particular, Fey's ORM pieces will be as
declarative as possible, and aim to emulate Moose where possible.

=back

=head2 Problems with Alzabo

Here are some of the problems I've had with Alzabo over the years:

=over 4

=item *

Adding support for a new DBMS is a lot of work, so it only supports
MySQL and Postgres. Alzabo tries to be really smart about preventing
users from shooting themselves in the foot, and required a lot of
specific code for each DBMS to achieve this.

In retrospect, being a lot dumber and allowing for foot-shooting makes
supporting a new DBMS much easier. People generally know how their
DBMS works, and if they generate an invalid query or table name, it
will throw an error.

For example, while Fey can accomodate per-DBMS query (sub)classes, it
does not include any by default, and is capable of supporting many
DBMS-specific features without per-DBMS classes.

=item *

Alzabo has too much DBMS-specific knowledge. If you want to use a SQL
function in a query, you have to import a corresponding Perl function
from the appropriate C<Alzabo::SQLMaker> subclass.

This means that you're limited to what that subclass defines.

By contrast, Fey has simple generic support for arbitrary functions
via the C<Fey::Literal::Function> class. If you need more flexibility
you can use the C<Fey::Literal::Term> subclass to generate an
arbitrary snippet to insert into your SQL.

A related problem is that Alzabo doesn't support multiple versions of
a DBMS very well. Either it doesn't work with an older version at all,
or it doesn't support some enhanced capability of a newer version.

=item *

There are now free GUI design tools for specific databases that do a
better job of supporting the database in question than Alzabo ever
has.

=item *

Alzabo separates its classes into Create (for generation of DDL) and
Runtime (for DML) subclasses, which might have been worth the memory
savings six years ago, but just makes for an extra hassle now.

=item *

When I originally developed Alzabo, I included a feature for
generating high-level application object classes which subclass the
Alzabo classes and add "business logic" methods. This is what is
provided by C<Alzabo::MethodMaker>.

Nowadays, I prefer to have my business logic classes simple use the
Alzabo classes. In other words, I now prefer "has-a" and "uses-a"
versus "is-a" object design for this case.

Method auto-generation based on a specific schema can be quite handy,
but it should be done in the domain-specific application classes, not
as a subclass of the core functionality.

=item *

Storing schemas in an Alzabo-specific format is problematic for many
reasons. It's simpler to simply get the schema definition from an
existing schema, or to allow users to define it in code.

=item *

Alzabo's referential integrity checking code was really cool back when
I mostly used MySQL with MYISAM tables. Now it's just a maintenance
burden and a barrier for various new features.

=item *

I didn't catch the testing bug until quite a while after I'd started
working on Alzabo. Alzabo's test suite is nasty. Fey is built with
testability in mind, and high test coverage is part of my ongoing
goals for the project.

=item *

Alzabo does too many things, which makes it hard to explain and
document.

=back

=head1 WHY IS IT NAMED Fey?

When I first started working on Fey, it was named "Q". This was a nice
short name to type, but obviously unsuitable for releasing on CPAN. I
wanted a nice short name that could be used in multiple distributions,
like John Siracusa's "Rose" modules.

I was standing in the shower one day and had the following series of
thoughts leading to Fey. Reading this will may give you an unpleasant
insight into my mind. You have been warned.

=over 4

=item * SQLy

This module is "SQL-y", as in "related to SQL". However, this name is
bad for a number of reasons. First, it's not clear how to pronounce
it. It may make you think of a YACC grammar ("SQL.y"). It's a weird
combo of upper- and lower-case letters.

=item * SQLy => Squall

"SQLy" and "Squall" share a number of letters, obviously.

Squall is a single short word, which is good. However, it's a bit
awkward to type and has a somewhat negative meaning to me, because a
storm can mean trouble.

=item * Squall => Lionheart => Faye

Squall Lionheart is a character in Final Fantasy VIII, which IMO is
the best Final Fantasy game before the PS2.

The inimitable Faye Wong sang the theme song for FF VIII. I love Faye
Wong.

=item * Faye => Fey

And thus we arrive at "Fey". It's nice and short, easy to type, and
easy to say.

Some of its meanings are "otherworldly" or "magical". Attempting to
combine SQL and OO in any way is certainly unnatural, and if done
right, perhaps magical. Fey can also mean "appearing slightly
crazy". This project is certainly that.

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
C<bug-fey-core@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2006-2007 Dave Rolsky, All Rights Reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. The full text of the license
can be found in the LICENSE file included with this module.

=cut
