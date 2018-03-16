package Test::Mockify::Tools;
use Module::Load;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw( blessed );
use base qw( Exporter );
our @EXPORT_OK = qw (
        Error
        ExistsMethod
        IsValid
        LoadPackage
        Isa
        GetExplicitParameters
    );

#------------------------------------------------------------------------
sub LoadPackage {
    my ($Package) = @_;

    my $PackageFileName = join( '/', split /::/, $Package ) . '.pm';
    load($PackageFileName);
    return;
}
#------------------------------------------------------------------------
sub IsValid {
    my ($Value) = @_;

    my $IsValid = 0;
    if( defined($Value) && $Value ne '' ){
        $IsValid = 1;
    }
    return $IsValid;
}
#------------------------------------------------------------------------
sub ExistsMethod {
    my ( $PathOrObject, $MethodName ) = @_;

    Error('Path or Object is needed') unless defined $PathOrObject;
    Error('Method name is needed') unless defined $MethodName;
    if( not $PathOrObject->can( $MethodName ) ){
        if( IsValid( ref( $PathOrObject ) ) ){
            $PathOrObject = ref( $PathOrObject );
        }
        Error( $PathOrObject." doesn't have a method like: $MethodName", {'Method' => $MethodName});
    }

    return 1;
}
#------------------------------------------------------------------------
sub Isa {
    my ($Object, $ClassName) = @_;
    return 0 unless blessed( $Object );
    return 0 unless $ClassName;
    my $ResultIsaCheck = $Object->isa( $ClassName );
    if($ResultIsaCheck eq ''){
        return 0;
    }
    return $ResultIsaCheck;
}
#------------------------------------------------------------------------
sub Error {
    my ($Message, $hData) = @_;

    die('Message is needed')unless(defined $Message);
    # print hData
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Pair = '=';
    local $Data::Dumper::Quotekeys = 0;
    my $MockedMethod = delete $hData->{'Method'} if defined $hData->{'Method'}; ## no critic (ProhibitConditionalDeclarations)
    $MockedMethod //= '-no method set-';
    my $DumpedData = Dumper($hData);
    # print Callerstack
    my $CallerStack = '';
    my $CallerStackPosition = 1; # 0 would be this function
    while (my @Caller = caller($CallerStackPosition++) ) {
        my $FileName = $Caller[1];
        my $LineNumber = $Caller[2];
        my $FunctionName = $Caller[3];
        $CallerStack .= sprintf(
            "%s,%s(line %s)\n",
            $FunctionName,
            $FileName,
            $LineNumber,
        );
       
    }
    # If the last element is a newline, the "at Xxxx.pm line XX" will not be printed
    my $ErrorOutput = sprintf(
        "%s:\nMockedMethod: %s\nData:%s\n%s\n",
        $Message,
        $MockedMethod,
        $DumpedData,
        $CallerStack,
    );
    
    die($ErrorOutput);
}
#------------------------------------------------------------------------
sub GetExplicitParameters {
    my ($package, @Parameters) = @_;

    return @Parameters unless $package;

    my @ExplicitParameters = @Parameters;
    my $firstParameter = $ExplicitParameters[0] if scalar @ExplicitParameters;

    if ($firstParameter) {
        $firstParameter =~ s/=[^=]+$//; # remove =HASH(0x1234abc)

        if ($firstParameter eq $package) {
            shift @ExplicitParameters;
        }
    }

    return @ExplicitParameters;
}


1;
