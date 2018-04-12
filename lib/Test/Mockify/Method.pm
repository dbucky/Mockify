=pod

=head1 Name

Test::Mockify::Method - chained setup

=head1 DESCRIPTION

L<Test::Mockify::Method> is used to provide the chained mock setup

=head1 METHODS

=cut
package Test::Mockify::Method;
use Test::Mockify::Parameter;
use Test::Mockify::TypeTests qw (
        IsInteger
        IsFloat
        IsString
        IsArrayReference
        IsHashReference
        IsObjectReference
        IsCodeReference
);
use Test::Mockify::Matcher qw (SupportedTypes);
use Test::Mockify::Tools qw (GetExplicitParameters);
use Scalar::Util qw( blessed );
use Data::Dumper;
use strict;
use warnings;

#---------------------------------------------------------------------
sub new {
    my $Class = shift;
    my $package = shift;
    my $self  = bless {
        'Package'=> $package,
        'TypeStore'=> undef,
        'MatcherStore'=> undef,
        'AnyStore'=> undef,
    }, $Class;
    foreach my $Type (SupportedTypes()){
        $self->{'MatcherStore'}{$Type} = [];
    }
    return $self;
}
=pod

=head2 when

C<when> have to be called with a L<Test::Mockify::Matcher> to specify the expected parameter list (signature).
This will create for every signature a Parameter Object which will stored and also returned. So it is possible to create multiple signatures for one Method.
It is not possible to mix C<when> with C<whenAny>.

  when(String())
  when(Number(),String('abc'))

=cut
sub when {
    my $self = shift;
    my @Parameters = @_;
    my @Signature;
    foreach my $Signature (keys %{$self->{'TypeStore'}}){
        if($Signature eq 'UsedWithWhenAny'){
            die('It is not possible to use a mixture between "when" and "whenAny"');
        }
    }
    foreach my $hParameter ( @Parameters ){
        die('Use Test::Mockify::Matcher to define proper matchers.') unless (ref($hParameter) eq 'HASH');
        push(@Signature, $hParameter->{'Type'});
    }
    $self->_checkExpectedParameters(\@Parameters);
    return $self->_addToTypeStore(\@Signature, \@Parameters);
}
=pod

=head2 whenAny

C<whenAny> have to be called without parameter, when called it will accept any type and amount of parameter. It will return a Parameter Object.
It is not possible to mix C<whenAny> with C<when>.

  whenAny()

=cut
sub whenAny {
    my $self = shift;
    die ('"whenAny" don`t allow any parameters' ) if (@_);
    my $numKeys = scalar keys %{$self->{'TypeStore'}};
    my $whenAny = $self->{'TypeStore'}{'UsedWithWhenAny'};
    if($numKeys && ($numKeys > 1 || !$whenAny)){
        die('It is not possible to use a mixture between "when" and "whenAny"');
    }
    return $self->_addToTypeStore(['UsedWithWhenAny']);
}
#---------------------------------------------------------------------
sub _checkExpectedParameters{
    my $self = shift;
    my ( $NewExpectedParameters) = @_;
    my $SignatureKey = '';
    for(my $i = 0; $i < scalar @$NewExpectedParameters; $i++){
        my $Type = $NewExpectedParameters->[$i]->{'Type'};
        $SignatureKey .= $Type;
        my $NewExpectedParameter = $NewExpectedParameters->[$i];
        $self->_testMatcherStore($self->{'MatcherStore'}{$Type}->[$i], $NewExpectedParameter);
        $self->{'MatcherStore'}{$Type}->[$i] = $NewExpectedParameter;
        $self->_testAnyStore($self->{'AnyStore'}->[$i], $Type);
        $self->{'AnyStore'}->[$i] = $Type;
    }
}

#---------------------------------------------------------------------
sub _testMatcherStore {
    my $self = shift;
    my ($MatcherStore, $NewExpectedParameterValue) = @_;
    if( defined $NewExpectedParameterValue->{'Value'} ){
        if($MatcherStore and not $MatcherStore->{'Value'}){
            die('It is not possibel to mix "expected parameter" with previously set "any parameter".');
        }
    } else {
        if($MatcherStore && $MatcherStore->{'Value'}){
            die('It is not possibel to mix "any parameter" with previously set "expected parameter".');
        }
    }
    return;
}
#---------------------------------------------------------------------
sub _testAnyStore {
    my $self = shift;
    my ($AnyStore, $Type) = @_;
    if($AnyStore){
        if($AnyStore eq 'any' and $Type ne 'any'){
            die('It is not possibel to mix "specific type" with previously set "any type".');
        }
        if($AnyStore ne 'any' and $Type eq 'any'){
            die('It is not possibel to mix "any type" with previously set "specific type".');
        }
    }
    return;
}
#---------------------------------------------------------------------
sub _addToTypeStore {
    my $self = shift;
    my ($Signature, $NewExpectedParameters) = @_;
    my $SignatureKey = join('',@$Signature);

    # if existing parameter with the same signature and expected params exists, return it
    foreach my $ExistingParameter (@{$self->{'TypeStore'}{$SignatureKey}}) {
        if ($ExistingParameter->compareExpectedParameters($NewExpectedParameters)) {
            return $ExistingParameter->buildReturn();
        }
    }

    my $Parameter = Test::Mockify::Parameter->new($NewExpectedParameters);
    push(@{$self->{'TypeStore'}{$SignatureKey}}, $Parameter );
    return $Parameter->buildReturn();
}
=pod

=head2 call

C<call> will be called with a list of parameters. If the signature of this parameters match a stored signature it will call the corresponding parameter object.

  call()

=cut
sub call {
    my $self = shift;
    my @Parameters = @_;
    my @ExplicitParameters = GetExplicitParameters($self->{'Package'}, @Parameters);
    my $SignatureKey = '';
    for(my $i = 0; $i < scalar @ExplicitParameters; $i++){
        if($self->{'AnyStore'}->[$i] && $self->{'AnyStore'}->[$i] eq 'any'){
            $SignatureKey .= 'any';
        }else{
            $SignatureKey .= $self->_getType($ExplicitParameters[$i]);
        }
    }
    if($self->{'TypeStore'}{'UsedWithWhenAny'}){
        return $self->{'TypeStore'}{'UsedWithWhenAny'}->[0]->call(@ExplicitParameters);
    }else {
        foreach my $ExistingParameter (@{$self->{'TypeStore'}{$SignatureKey}}){
            if($ExistingParameter->matchWithExpectedParameters(@ExplicitParameters)){
                return $ExistingParameter->call(@Parameters);
            }
        }
    }
    die ("No matching found for $SignatureKey -> ".Dumper(\@ExplicitParameters));
}
#---------------------------------------------------------------------
sub _getType{
    my $self = shift;
    my ($Parameter) = @_;
    return 'arrayref' if(IsArrayReference($Parameter));
    return 'hashref' if(IsHashReference($Parameter));
    return 'object' if(IsObjectReference($Parameter));
    return 'sub' if(IsCodeReference($Parameter));
    return 'number' if(IsFloat($Parameter));
    return 'string' if(IsString($Parameter));
    return 'undef' if( not $Parameter);
    die("UnexpectedParameterType for: '$Parameter'");
}

1;

__END__

=head1 LICENSE

Copyright (C) 2017 ePages GmbH

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Christian Breitkreutz E<lt>christianbreitkreutz@gmx.deE<gt>

=cut
