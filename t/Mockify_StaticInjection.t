package Mockify_StaticInjection;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Exception;
use Test::Mockify;
use Test::Mockify::Verify qw (WasCalled GetCallCount);
use Test::More;
use Test::Mockify::Matcher qw (String Number);
use warnings;
use Data::Dumper;


use strict;
no warnings 'deprecated';

use FakeModuleForMockifyTest;
use FakeModuleWithoutNew;

sub testPlan {
    my $self = shift;

    $self->test_useMethodWhichUsesStaticFunction();
    $self->test_functionNameFormating();
    $self->test_someSelectedMockifyFeatures();
}
#----------------------------------------------------------------------------------------
sub test_useMethodWhichUsesStaticFunction {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $SUT;
    {
        my $Injector = Test::Mockify->new('FakeModulStaticInjection',[]);
        $Injector->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('German'))->thenReturn('Hallo Welt');
        $Injector->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('Spanish'))->thenReturn('Hola Mundo');
        $Injector->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('Esperanto'))->thenReturn('Saluton mondon');
        $SUT = $Injector->getMockObject();

        is($SUT->useStaticFunction('German'), 'German: Hallo Welt',"$SubTestName - prove full path call- german");
        is($SUT->useImportedStaticFunction('German'), 'German: Hallo Welt',"$SubTestName - prove that the same mock can handle also the imported call - german");
        is($SUT->useStaticFunction('Spanish'), 'Spanish: Hola Mundo',"$SubTestName - prove full path call - spanish");
        is($SUT->useImportedStaticFunction('Spanish'), 'Spanish: Hola Mundo',"$SubTestName - prove imported call - spanish");
    }
    # With this approach it also is not binded anymore to the scope. The Override stays with the mocked object
    is($SUT->useStaticFunction('Esperanto'), 'Esperanto: Saluton mondon',"$SubTestName - prove full path call, scope independent- german");
    is($SUT->useImportedStaticFunction('Esperanto'), 'Esperanto: Saluton mondon',"$SubTestName - prove that the same mock can handle also the imported call, scope independent - german");
#
    ok( WasCalled($SUT, 'FakeStaticTools::ReturnHelloWorld'), "$SubTestName - prove verify, independent of scope and call type");
    is( GetCallCount($SUT, 'FakeStaticTools::ReturnHelloWorld'),  6,"$SubTestName - prove that 'ReturnHelloWorld' was called 6 times, independent of scope and call type");
}

#----------------------------------------------------------------------------------------
sub test_functionNameFormating {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Injector = Test::Mockify->new('FakeModulStaticInjection',[]);
    throws_ok( sub { $Injector->mockStatic() },
                   qr/The Parameter needs to be defined and a String. e.g. Path::To::Your::Function/,
                   "$SubTestName - prove the an unfdefined will fail"
    );
    throws_ok( sub { $Injector->mockStatic('OnlyFunctionName') },
                   qr/The function name needs to be with full path. e.g. 'Path::To::Your::OnlyFunctionName' instead of only 'OnlyFunctionName'/,
                   "$SubTestName - prove the an incomplete name will fail"
    );
}
#----------------------------------------------------------------------------------------
sub test_someSelectedMockifyFeatures {
    my $self = shift;
    my $SubTestName = (caller(0))[3];
    my $Injector = Test::Mockify->new('FakeModulStaticInjection',[]);
    $Injector->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('Error'))->thenThrowError('TestError');
    $Injector->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('caller'))->thenCall(sub{return 'returnValue'});
    $Injector->mockStatic('FakeStaticTools::ReturnHelloWorld')->when(String('undef'), String('abc'))->thenReturnUndef();
    $Injector->spyStatic('FakeStaticTools::HelloSpy')->when(String('And you are?'));
    $Injector->mock('overrideMethod')->when(String('override'))->thenReturn('overridden Value');
    $Injector->spy('overrideMethod_spy')->when(String('spyme'));
    $Injector->addMock('overrideMethod_addMock', sub {return 'overridden Value (addMock)'});
    #spy
    my $SUT = $Injector->getMockObject();
    throws_ok( sub{$SUT->useStaticFunction('Error') },
                   qr/TestError/,
                   "$SubTestName - prove if thenThrowError will fail"
    );
    is($SUT->useStaticFunction('caller'), 'caller: returnValue',"$SubTestName - prove thenCall");
    is($SUT->useStaticFunction('undef', 'abc'), 'undef: ',"$SubTestName - prove thenReturnUndef");
    is($SUT->overrideMethod('override'), 'overridden Value',"$SubTestName - prove mock Works");
    $SUT->overrideMethod_spy('spyme'); #1
    $SUT->overrideMethod_spy('spyme'); #2
    is(GetCallCount($SUT,'overrideMethod_spy'), 2,"$SubTestName - prove verify works for override");
    is($SUT->useStaticFunctionSpy('And you are?'), 'And you are?: Bond, James Bond!', "$SubTestName - prove static spy Works - call 1");
    is($SUT->useStaticFunctionSpy('And you are?'), 'And you are?: Bond, James Bond!', "$SubTestName - prove static spy Works- call 2");
    is($SUT->useImportedStaticFunctionSpy('And you are?'), 'And you are?: Bond, James Bond!', "$SubTestName - prove static spy Works. - call 3");
    is(GetCallCount($SUT,'FakeStaticTools::HelloSpy'), 3,"$SubTestName - prove verify works for spy");
    is($SUT->overrideMethod_addMock(), 'overridden Value (addMock)',"$SubTestName - prove mock Works for 'addMock'");
}

__PACKAGE__->RunTest();