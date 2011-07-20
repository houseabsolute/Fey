use strict;
use warnings;

use Test::Spelling;

BEGIN {
    unless ($ENV{RELEASE_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
}

my @stopwords;
for (<DATA>) {
    chomp;
    push @stopwords, $_
        unless /\A (?: \# | \s* \z)/msx;    # skip comments, whitespace
}

add_stopwords(@stopwords);
set_spell_cmd('aspell list -l en');

# This prevents a weird segfault from the aspell command - see
# https://bugs.launchpad.net/ubuntu/+source/aspell/+bug/71322
local $ENV{LC_ALL} = 'C';
all_pod_files_spelling_ok;

__DATA__
Alzabo
Alzabo's
API
APIs
ASC
alias's
attribute's
CPAN
datetime
deflator
deflators
dbms
dbms's
dbh
DBI
DDL
DESC
distro
DML
fiddliness
fk
FromSelect
inflator
iterator's
literal's
Lionheart
lookup
MYISAM
ORM
metaclass
metaclass's
multi
namespace
nullable
NULLs
numification
OO
parameterized
params
Pearcey
Postgres
RDBMS
resultset
rethrows
Rolsky
Runtime
schemas
Siracusa's
SomeTable
SQL
SQLite
SQLy
subclause
subref
subselect
subselects
unblessed
unhashed
unsets
username
wildcard
