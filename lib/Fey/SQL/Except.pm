package Fey::SQL::Except;

use strict;
use warnings;

use Moose;

with 'Fey::Role::SetLike' => { keyword => 'EXCEPT' };

no Moose;

1;
