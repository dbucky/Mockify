package Mockify_StaticMock;
use strict;
use FindBin;
## no critic (ProhibitComplexRegexes)
use lib ($FindBin::Bin.'/..'); # point to test base
use lib ($FindBin::Bin.'/../..'); # point to project base
use parent 'TestBase';
use Test::More;
use Test::Mockify;
use Test::Exception;
use Test::Mockify::Matcher qw (
        Number
        String
    );
use t::TestDummies::DummyStaticToolsUser;
use Test::Mockify::Verify qw (GetParametersFromMockifyCall GetCallCount);
use t::TestDummies::DummyStaticTools;
use t::TestDummies::DummyStaticToolsUser_Static;
#----------------------------------------------------------------------------------------
sub testPlan{
    my $self = shift;
    $self->test_InjectionOfStaticedMethod_scopes();
    $self->test_InjectionOfStaticedMethod_scopes_spy();
    $self->test_InjectionOfStaticedMethod_SetMockifyToUndef();
    $self->test_InjectionOfStaticedMethod_Verify();
    $self->test_InjectionOfStaticedMethod_Verify_spy();
    $self->test_functionNameFormatingErrorHandling_mock ();
    $self->test_functionNameFormatingErrorHandling_spy ();
    $self->test_parameterMatchingAndRetrieval_staticFunction();
    $self->test_parameterMatchingAndRetrieval_instanceFunction();
}

#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_scopes {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyStaticToolsUser->new()->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    {#beginn scope
        my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
        $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
        my $DummyStaticToolsUser = $Mockify->getMockObject();
        is(
            $DummyStaticToolsUser->useDummyStaticTools(2),
            'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
            "$SubTestName - Prove that the injection works out"
        );
        is(t::TestDummies::DummyStaticTools::Tripler(2), 'InjectedReturnValueOfTripler', "$SubTestName - Prove injected mock result (direct call)");
    } # end scope
    is(
        t::TestDummies::DummyStaticToolsUser->new()->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    is(t::TestDummies::DummyStaticTools::Tripler(2), 6, "$SubTestName - Prove released original method result (direct call)");
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_scopes_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyStaticToolsUser->new()->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    {#beginn scope
        my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
        $Mockify->spyStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2));
        my $DummyStaticToolsUser = $Mockify->getMockObject();
        is(
            $DummyStaticToolsUser->useDummyStaticTools(2),
            'In useDummyStaticTools, result Tripler call: "6"',
            "$SubTestName - Prove that the injection works out"
        );
    } # end scope
    is(
        t::TestDummies::DummyStaticToolsUser->new()->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_SetMockifyToUndef {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    is(
        t::TestDummies::DummyStaticToolsUser->new()->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
    my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
    $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
    my $DummyStaticToolsUser = $Mockify->getMockObject();
    is(
        $DummyStaticToolsUser->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
        "$SubTestName - Prove that the injection works out"
    );
    is(t::TestDummies::DummyStaticTools::Tripler(2), 'InjectedReturnValueOfTripler', "$SubTestName - Prove injected mock result (direct call)");
    $Mockify = undef;
    is(t::TestDummies::DummyStaticTools::Tripler(2), 6, "$SubTestName - Prove released original method result (direct call)");
    is(
        t::TestDummies::DummyStaticToolsUser->new()->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - prove the unmocked Result"
    );
}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_Verify {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
    $Mockify->mockStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2))->thenReturn('InjectedReturnValueOfTripler');
    my $DummyStaticToolsUser = $Mockify->getMockObject();
    is(
        $DummyStaticToolsUser->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "InjectedReturnValueOfTripler"',
        "$SubTestName - Prove that the injection works out"
    );
    is(
        t::TestDummies::DummyStaticTools::Tripler(2),
        'InjectedReturnValueOfTripler',
        "$SubTestName - Prove injected mock result will increase the counter (direct call) "
    );
    my $aParams =  GetParametersFromMockifyCall($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler');
    is(scalar @{$aParams} ,1 , "$SubTestName - prove amount of parameters");
    is($aParams->[0] ,2 , "$SubTestName - get parameter of first call");
    is(  GetCallCount($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler'), 2, "$SubTestName - prove that the the Tripler only get called twice.");

}
#----------------------------------------------------------------------------------------
sub test_InjectionOfStaticedMethod_Verify_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
    $Mockify->spyStatic('t::TestDummies::DummyStaticTools::Tripler')->when(Number(2));
    my $DummyStaticToolsUser = $Mockify->getMockObject();
    is(
        $DummyStaticToolsUser->useDummyStaticTools(2),
        'In useDummyStaticTools, result Tripler call: "6"',
        "$SubTestName - Prove that the spy works out"
    );
    is(
        t::TestDummies::DummyStaticTools::Tripler(2),
        6,
        "$SubTestName - Prove injected spy result will increase the counter (direct call) "
    );
    my $aParams =  GetParametersFromMockifyCall($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler');
    is(scalar @{$aParams} ,1 , "$SubTestName - prove amount of parameters");
    is($aParams->[0] ,2 , "$SubTestName - get parameter of first call");
    is(  GetCallCount($DummyStaticToolsUser, 't::TestDummies::DummyStaticTools::Tripler'), 2, "$SubTestName - prove that the the Tripler only get called twice.");

}

#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling_mock {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
    throws_ok( sub { $Mockify->mockStatic() },
                   qr/"mockStatic" Needs to be called with one Parameter which need to be a fully qualified path as String. e.g. "Path::To::Your::Function"/sm,
                   "$SubTestName - prove the an undefined will fail"
    );
    throws_ok( sub { $Mockify->mockStatic('OnlyFunctionName') },
                   qr/The function you like to mock needs to be defined with a fully qualified path. e.g. 'Path::To::Your::OnlyFunctionName' instead of only 'OnlyFunctionName'/sm,
                   "$SubTestName - prove the an incomplete name will fail"
    );
}
#----------------------------------------------------------------------------------------
sub test_functionNameFormatingErrorHandling_spy {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser',[]);
    throws_ok( sub { $Mockify->spyStatic() },
                   qr/"spyStatic" Needs to be called with one Parameter which need to be a fully qualified path as String. e.g. "Path::To::Your::Function"/sm,
                   "$SubTestName - prove the an undefined will fail"
    );
    throws_ok( sub { $Mockify->spyStatic('OnlyFunctionName') },
                   qr/The function you like to spy needs to be defined with a fully qualified path. e.g. 'Path::To::Your::OnlyFunctionName' instead of only 'OnlyFunctionName'/sm,
                   "$SubTestName - prove the an incomplete name will fail"
    );
}
#----------------------------------------------------------------------------------------
sub test_parameterMatchingAndRetrieval_staticFunction {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $originalResult = t::TestDummies::DummyStaticToolsUser_Static::parameterTestForStaticFunction();

    {
        my $mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser_Static');
        $mockify->spyStatic('TestDummies::FakeModuleWithoutNew::dummyMethodWithParameterReturn')->when(String('First'), String('Second'));

        my $SUT = $mockify->getMockObject();

        my $spiedResult = $SUT->parameterTestForStaticFunction();

        is($spiedResult, $originalResult, "$SubTestName - Spied result is the same as the original result");

        my $parameters = GetParametersFromMockifyCall($SUT, 'TestDummies::FakeModuleWithoutNew::dummyMethodWithParameterReturn');

        is_deeply($parameters, ['First', 'Second'], "$SubTestName - The parameters seen by the spy are correct");
    }
}
#----------------------------------------------------------------------------------------
sub test_parameterMatchingAndRetrieval_instanceFunction {
    my $self = shift;
    my $SubTestName = (caller(0))[3];

    my $originalResult = t::TestDummies::DummyStaticToolsUser_Static::parameterTestForInstanceFunction();

    {
        my $mockify = Test::Mockify->new('t::TestDummies::DummyStaticToolsUser_Static');
        # Causes the parameter matching to fail, because the instance ($self) is passed in as the first parameter before the explicit ones
        # Using whenAny allows the parameter matching to pass
        $mockify->spyStatic('TestDummies::FakeModuleForMockifyTest::dummyMethodWithParameterReturn')->when(String('First'), String('Second'));

        my $SUT = $mockify->getMockObject();

        my $spiedResult = $SUT->parameterTestForInstanceFunction();

        is($spiedResult, $originalResult, "$SubTestName - Spied result is the same as the original result");

        # The same issue arises when getting the parameters
        # This returns three parameters instead of two: [instance, 'First', 'Second']
        # This doesn't seem like the way it should work. The static version above works as expected.
        my $parameters = GetParametersFromMockifyCall($SUT, 'TestDummies::FakeModuleForMockifyTest::dummyMethodWithParameterReturn');

        is_deeply($parameters, ['First', 'Second'], "$SubTestName - The parameters seen by the spy are correct");
    }
}
__PACKAGE__->RunTest();
1;