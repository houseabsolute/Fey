package Fey::SQL::Intersect;

use strict;
use warnings;

use Moose;

with 'Fey::Role::SetLike' => { keyword => 'INTERSECT' };

no Moose;

1;
