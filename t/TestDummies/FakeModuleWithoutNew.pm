package TestDummies::FakeModuleWithoutNew;

use strict;

sub DummyMethodForTestOverriding {
    return 'A dummy method';
}

sub secondDummyMethodForTestOverriding {
    return 'A second dummy method';
}

sub dummyMethodWithParameterReturn {
    my ( $Parameter ) = @_;
    return $Parameter;
}

1;