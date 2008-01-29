use strict;
use warnings;

use Test::More tests => 19;

use Fey::NamedObjectSet;


{
    my $set = Fey::NamedObjectSet->new();
    ok( $set, 'made a named object set object' );

    eval { $set->add(1) };
    like( $@, qr/was a 'scalar'/,
          'cannot add an integer to a NamedObjectSet' );

    eval { $set->add( NoName->new() ) };
    like( $@, qr/does not have the method: 'name'/,
          'cannot add a NoName object to a NamedObjectSet');
}

{
    my $set = Fey::NamedObjectSet->new();

    my $bob  = Name->new('bob');
    my $faye = Name->new('faye');

    eval { $set->add() };
    like( $@, qr/0 parameters were passed/,
          'add() requires at least one argument' );

    $set->add($bob);
    my @objects = $set->objects();
    is( scalar @objects, 1, 'set has one object' );
    is( $objects[0]->name(), 'bob', 'that one object is bob' );

    $set->add($faye);
    @objects = sort { $a->name() cmp $b->name() } $set->objects();
    is( scalar @objects, 2, 'set has two objects' );
    is_deeply( [ map { $_->name() } @objects ],
               [ 'bob', 'faye' ],
               'those objects are bob and faye' );

    eval { $set->delete() };
    like( $@, qr/0 parameters were passed/,
          'delete() requires at least one argument' );

    $set->delete($bob);
    @objects = $set->objects();
    is( scalar @objects, 1, 'set has one object' );
    is( $objects[0]->name(), 'faye', 'that one object is faye' );

    $set->add($bob);
    @objects = $set->objects('bob');
    is( scalar @objects, 1, 'objects() returns one object named bob' );
    is( $objects[0]->name(), 'bob', 'that one object is bob' );

    is( $set->object('bob')->name(), 'bob',
        'object() returns one object by name and it is bob' );

    ok( $set->is_same_as($set),
        'set is_same_as() itself' );

    my $other_set = Fey::NamedObjectSet->new();
    ok( ! $set->is_same_as($other_set),
        'set not is_same_as() empty set' );

    $other_set->add($bob);
    ok( ! $set->is_same_as($other_set),
        'set not is_same_as() other set with just one object' );

    $other_set->add($faye);
    ok( $set->is_same_as($other_set),
        'set not is_same_as() other set which has the same objects' );
}

{
    my $bob  = Name->new('bob');
    my $faye = Name->new('faye');

    my $set1 = Fey::NamedObjectSet->new( $bob, $faye );

    my $set2 = Fey::NamedObjectSet->new();
    $set2->add($_) for $bob, $faye;

    ok( $set1->is_same_as($set2),
        'set with items added at construction is same as set with items added via add()' );
}


package NoName;

sub new { return bless {}, shift }

package Name;

sub new 
{
    my $class = shift;

    return bless { name => shift }, $class;
}

sub name { $_[0]->{name} }
