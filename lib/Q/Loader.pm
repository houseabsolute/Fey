package Q::Loader;

use strict;
use warnings;

use Q::Validate qw( validate DBI_TYPE );

use Q::Loader::DBI;


{
    my $spec = { dbh  => DBI_TYPE };
    sub new
    {
        my $class = shift;
        my %p     = validate( @_, $spec );

        my $driver = $p{dbh}{Driver}{Name};

        my $subclass = $class->_determine_subclass($driver);

        return $subclass->new(%p);
    }
}

sub _determine_subclass
{
    my $class = shift;
    my $driver = shift;

    my $subclass = $class . '::' . $driver;

    return $subclass if $subclass->can('new');

    eval "use $subclass";
    if ($@)
    {
        die $@ unless $@ =~ /Can't locate/;

        warn <<"EOF";

There is no driver-specific $class subclass for your driver ($driver)
... falling back to the base DBI implementation. This may or may not
work.

EOF

        return $class . '::' . 'DBI';
    }

    return $subclass;
}


1;

__END__
