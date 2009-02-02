use strict;
use warnings;

use Test::More tests => 2;
use Fey::FakeDBI;


{
    is( Fey::FakeDBI->quote('foo'), q{"foo"}, 'FakeDBI->quote foo' );
    is( Fey::FakeDBI->quote(q{"blah"}), q{"""blah"""}, 'FakeDBI->quote "blah"' );
}
