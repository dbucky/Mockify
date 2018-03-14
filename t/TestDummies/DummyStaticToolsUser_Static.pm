package t::TestDummies::DummyStaticToolsUser_Static;
use strict;
use warnings;
use FindBin;
use lib ($FindBin::Bin.'/..');
use t::TestDummies::DummyStaticTools;
use TestDummies::FakeModuleForMockifyTest;
use TestDummies::FakeModuleWithoutNew;


sub useDummyStaticTools {
    my ($Value) = @_;
     my $Triplet = t::TestDummies::DummyStaticTools::Tripler($Value);
    return "In useDummyStaticTools, result Tripler call: \"$Triplet\"";
}

sub OverrideDummyFunctionUser {
    my ($Value) = @_;
    return '('._OverrideDummyFunction($Value)." with '$Value')";
}

sub _OverrideDummyFunction {
    my ($Value) = @_;
    return "(_OverrideDummyFunction: '$Value')";
}

sub parameterTestForInstanceFunction {
    my $instance = TestDummies::FakeModuleForMockifyTest->new();
    return $instance->dummyMethodWithParameterReturn('First', 'Second');
}

sub parameterTestForStaticFunction {
    return TestDummies::FakeModuleWithoutNew::dummyMethodWithParameterReturn('First', 'Second');
}
1;