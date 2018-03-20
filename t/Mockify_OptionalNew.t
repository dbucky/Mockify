package Mockify_OptionalNew;
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Mockify::Instance;
use Test::More;
use warnings;
no warnings 'deprecated';
sub testPlan {
    my $self = shift;
    $self->test_MockModule();
}
#----------------------------------------------------------------------------------------
sub test_MockModule {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $mockifyInstance = Test::Mockify::Instance->new('FakeModuleWithoutNew');
    my $mockFakeModule = $mockifyInstance->getInstance();
    is($mockFakeModule->secondDummyMethodForTestOverriding(),'A second dummy method',"$SubTestName - test if the loaded module still have the unmocked methods");

    return;
}

__PACKAGE__->RunTest();