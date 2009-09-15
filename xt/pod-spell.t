use strict;
use warnings;

use Test::Spelling;

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
APIs
ASC
alias's
attribute's
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
parameterized
params
Pearcey
resultset
rethrows
Runtime
schemas
Siracusa's
SomeTable
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
