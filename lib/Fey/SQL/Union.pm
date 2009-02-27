package Fey::SQL::Union;

use strict;
use warnings;

use Moose;

with 'Fey::Role::SetLike' => { keyword => 'UNION' };

no Moose;

1;
