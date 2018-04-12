package Method;
use Test::Mockify::Matcher qw (
        String
        Number
        HashRef
        ArrayRef
        Object
        Function
        Undef
        Any
);
use strict;

use FindBin;
use lib ($FindBin::Bin);

use parent 'TestBase';
use Test::Exception;
use Test::Mockify::Method;
use Test::Mockify::Instance;
use Test::More;
#------------------------------------------------------------------------
sub testPlan{
    my $self = shift;

    $self->_SignatureWithAnyMatcherAndExpectedMatcher();
    $self->_MultipleAnyMatcher();
    $self->_SingleExpectedMatcher();
    $self->_NullProblems();
    $self->_MockifiedObjectCheck();
    $self->_AnyMatcher();
    $self->_AnyParameter();
    $self->_FunctionCall();
    $self->_MixedExpectedMatcherAndAnyMatcher_Error();
    $self->_MixedAnyMatcherWithDifferentTypes();
    $self->_RedefineSignature();
    $self->_UndefinedSignature_Error();
    $self->_UndefinedType_Error();
    return;
}
#---------------------------------------------------------------------------------
sub _SignatureWithAnyMatcherAndExpectedMatcher {
    my $self = shift;

    my $Method = Test::Mockify::Method->new();
    $Method->when(String('hello'), String() )->thenReturn('World');
    is($Method->call('hello','abcd'), 'World', 'first expected, second any');
    is($Method->call('hello','world'), 'World', 'first expected, second any');

    $Method = Test::Mockify::Method->new();
    $Method->when(String(), String('World'))->thenReturn('Hello');    
    is($Method->call('jaja','World'), 'Hello', 'first any, second expected');
    is($Method->call('something','World'), 'Hello', 'first any, second expected');
}
#---------------------------------------------------------------------------------
sub _MultipleAnyMatcher {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when( String(), Number(),HashRef(), ArrayRef(), Object() , Function(), Undef() )->thenReturn('Hello World');
    my $Obj = bless({},'Test::Package');
    my $Fct = sub {};
    is($Method->call('a',1, {}, [], $Obj,$Fct, undef), 'Hello World', 'mixed parameters');
}

#---------------------------------------------------------------------------------
sub _AnyMatcher {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when(Any())->thenReturn('Result for one any.');

    is($Method->call('OneString'), 'Result for one any.', 'single any parameter type string');
    is($Method->call(123), 'Result for one any.', 'single any parameter type number');
    is($Method->call({1=>23}), 'Result for one any.', 'single any parameter type hashref');
    is($Method->call([1,23]), 'Result for one any.', 'single any parameter type arrayref');
    is($Method->call(bless({},'Test::Package')), 'Result for one any.', 'single any parameter type object');
    is($Method->call(sub{}), 'Result for one any.', 'single any parameter type sub');
    is($Method->call(undef), 'Result for one any.', 'single any parameter type undef');
    throws_ok( sub { $Method->when( String() )->thenReturn('Hello World'); },
               qr/It is not possibel to mix "specific type" with previously set "any type"./,
               'proves that it is not possible to use a specific type after an any type was set.'
     );
    my $StringMethod = Test::Mockify::Method->new();
    $StringMethod->when(String())->thenReturn('Result for one string.');
    throws_ok( sub { $StringMethod->when( Any() )->thenReturn('Hello World'); },
               qr/It is not possibel to mix "any type" with previously set "specific type"./,
               'proves that it is not possible to use an any type after a specific type was set.'
     );
}
#---------------------------------------------------------------------------------
sub _AnyParameter {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->whenAny()->thenReturn('helloWorld');
    is($Method->call(),'helloWorld' , 'proves that "whenAny" works without parameters.');;
    is($Method->call(123),'helloWorld' , 'proves that "whenAny" works one parameter.');;
    is($Method->call('abc',['abc']),'helloWorld' , 'proves that the same"whenAny" works with two parameter.');
    throws_ok( sub { $Method->when(String('abc'))->thenReturn('WaterWorld') },
               qr/It is not possible to use a mixture between "when" and "whenAny"/,
               'proves that it is not possible to use "when" when "whenAny" was used before.'
     );
     $Method = Test::Mockify::Method->new();
    throws_ok( sub { $Method->whenAny('param')->thenReturn('WaterWorld') },
               qr/"whenAny" don`t allow any parameters/,
               'proves that it is not possible to use "whenAny" two times.'
     );
     $Method = Test::Mockify::Method->new();
     $Method->when(String())->thenReturn('helloWorld');
    throws_ok( sub { $Method->whenAny()->thenReturn('WaterWorld') },
               qr/It is not possible to use a mixture between "when" and "whenAny"/,
               'proves that it is not possible to use "whenAny" when "when" was used before.'
     );
}

#---------------------------------------------------------------------------------
sub _SingleExpectedMatcher {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when(String('OneString'))->thenReturn('Result for one string.');
    $Method->when(Number(123))->thenReturn('Result for one number.');
    $Method->when(HashRef({1=>23}))->thenReturn('Result for one hashref.');
    $Method->when(ArrayRef([1,23]))->thenReturn('Result for one arrayref.');
    $Method->when(Object('Test::Package'))->thenReturn('Result for one object.');
    $Method->when(Function())->thenReturn('Result for one function pointer.');
    $Method->when(Undef())->thenReturn('Result for one undef.');
    $Method->when()->thenReturn('Result for one real undef.');

    is($Method->call('OneString'), 'Result for one string.', 'single expected parameter type string');
    is($Method->call(123), 'Result for one number.', 'single expected parameter type number');
    is($Method->call({1=>23}), 'Result for one hashref.', 'single expected parameter type hashref');
    is($Method->call([1,23]), 'Result for one arrayref.', 'single expected parameter type arrayref');
    is($Method->call(bless({},'Test::Package')), 'Result for one object.', 'single expected parameter type object');
    is($Method->call(sub{}), 'Result for one function pointer.', 'single expected parameter type sub');
    is($Method->call(undef), 'Result for one undef.', 'single expected parameter type undef');
    is($Method->call(), 'Result for one real undef.', 'single expected parameter type real undef');
}
#---------------------------------------------------------------------------------
sub _NullProblems {
    # since 0 is "false" and the string '0' is interpreted as a number, also '0' is "false"
    # there are some special cases
    my $Method = Test::Mockify::Method->new();
    $Method->when(Number(0))->thenReturn('Result for zero number.');

    throws_ok( sub { $Method->when(String('0')) },
       qr/Use the Matcher Number\(\) to Check for the string '0' \(perl cannot differ that\)/,
       "proves that an Error is thrown if mockify is used wrongly"
    );

    $Method->when(String(''))->thenReturn('Result for empty string.');

    is($Method->call(0), 'Result for zero number.', 'single expected parameter type number (0)');
    is($Method->call('0'), 'Result for zero number.', 'single expected parameter type number, even though it is a String');
    is($Method->call(''), 'Result for empty string.', 'expected return value for empty string signature');
}
#---------------------------------------------------------------------------------
sub _MockifiedObjectCheck {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when(Object('FakeModuleForMockifyTest'))->thenReturn('Result for mockified Object.');

    my $Mockify = Test::Mockify::Instance->new('FakeModuleForMockifyTest');
    my $MockedFakeModuleForMockifyTest = $Mockify->getInstance();

    is($Method->call($MockedFakeModuleForMockifyTest), 'Result for mockified Object.', 'Match mocked Objects');
    return;
}
#---------------------------------------------------------------------------------
sub _FunctionCall {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when(String(),Number())->thenCall(sub {return \@_;});
    my $ReturnValue = $Method->call('StringToPass', 123);
    is_deeply($ReturnValue, ['StringToPass', 123], 'proves that the parameter will be passed to the hole chain.');
}
#---------------------------------------------------------------------------------
sub _SingleAnyParameter {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when(String())->thenReturn('Result for one string.');
    $Method->when(Number())->thenReturn('Result for one number.');

    is($Method->call('OneString'), 'Result for one string.', 'single any parameter type string');	
    is($Method->call(123), 'Result for one number.', 'single any parameter type number');	
}
#---------------------------------------------------------------------------------
sub _MixedExpectedMatcherAndAnyMatcher_Error {
    my $self = shift;    
    
    my $Method = Test::Mockify::Method->new();
    $Method->when(String('OneString'))->thenReturn('Result for one string.');
    throws_ok( sub { $Method->when( String() )->thenReturn('Hello World'); },
               qr/It is not possibel to mix "any parameter" with previously set "expected parameter"./,
               'error if use of any and expected matcher in first parameter'
     );

    $Method = Test::Mockify::Method->new();
    $Method->when(String())->thenReturn('Result for two strings.');
    throws_ok( sub { $Method->when( String('OneString') )->thenReturn('Hello World'); },
               qr/It is not possibel to mix "expected parameter" with previously set "any parameter"./,
               'error if use of any and expected matcher - single parameter'
     );
} 
#---------------------------------------------------------------------------------
sub _MixedAnyMatcherWithDifferentTypes {
    my $self = shift;    
    
    my $Method = Test::Mockify::Method->new();
    $Method->when( String() )->thenReturn('ResultString');
    $Method->when( Number(123) )->thenReturn('ResultNumber');
    
    is($Method->call(123), 'ResultNumber', 'correct result for expected matcher number -> 123');
    is($Method->call("lalal"), 'ResultString', 'correct result for any matcher sting');

} 
#---------------------------------------------------------------------------------
sub _RedefineSignature{
    my $self = shift;
    
    my $Method = Test::Mockify::Method->new();
    $Method->when(String('Parameter'))->thenReturn('Hello');
    is($Method->call('Parameter'), 'Hello', 'The original return value defined for the Type Parameter is returned.');
    $Method->when(String('Parameter'))->thenReturn('World');
    is($Method->call('Parameter'), 'World', 'The new return value defined for the same Type Parameter is returned.');

    $Method = Test::Mockify::Method->new();
    $Method->when(String())->thenReturn('Hello');
    is($Method->call('Parameter'), 'Hello', 'The original return value defined for the Type Matcher is returned.');
    $Method->when(String())->thenReturn('World');
    is($Method->call('Parameter'), 'World', 'The new return value defined for the same Type Matcher is returned.');

    $Method = Test::Mockify::Method->new();
    $Method->when(Any())->thenReturn('Hello');
    is($Method->call('Parameter'), 'Hello', 'The original return value defined for the Any Matcher is returned.');
    $Method->when(Any())->thenReturn('World');
    is($Method->call('Parameter'), 'World', 'The new return value defined for the same Any Matcher is returned.');

    $Method = Test::Mockify::Method->new();
    $Method->whenAny()->thenReturn('Hello');
    is($Method->call('Parameter'), 'Hello', 'The original return value defined for the WhenAny is returned.');
    $Method->whenAny()->thenReturn('World');
    is($Method->call('Parameter'), 'World', 'The new return value defined for the same WhenAny is returned.');

    $Method = Test::Mockify::Method->new();
    $Method->when()->thenReturn('Hello');
    is($Method->call(), 'Hello', 'The original return value defined for the When is returned.');
    $Method->when()->thenReturn('World');
    is($Method->call(), 'World', 'The new return value defined for the same When is returned.');
}
#---------------------------------------------------------------------------------
sub _UndefinedSignature_Error {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    $Method->when(String())->thenReturn('Hello World');
    throws_ok( sub { $Method->call('not','mocked Signature') },
    	qr/No matching found for string/,
               'unsupported amount of parameters'
     );
}
#---------------------------------------------------------------------------------
sub _UndefinedType_Error {
    my $self = shift;
    my $Method = Test::Mockify::Method->new();
    throws_ok( sub { $Method->when('UnsupportedType')->thenReturn('Result for two strings.'); },
               qr/Use Test::Mockify::Matcher to define proper matchers./,
               'unsupported type, not like string or number'
     );
}
__PACKAGE__->RunTest();
1;