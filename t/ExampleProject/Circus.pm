package ExampleProject::Circus;
use strict;

use t::ExampleProject::MagicShow::Magician;
use t::ExampleProject::KidsShow::TimberBeam;
use t::ExampleProject::KidsShow::SeeSaw;

sub new {
    my $class = shift;
    my ($Magician)  = @_;
    my $self  = bless {
        'Magician' => $Magician ? $Magician :  t::ExampleProject::MagicShow::Magician->new(),
        'Counter' => 0,
    }, $class;
    return $self;
}
#----------------------------------------------------------------------------------------
sub getLineUp {
    my $self = shift;
    my $aLineUpList = [];
    push(@{$aLineUpList}, $self->{'Magician'}->getLineUpName());
    push(@{$aLineUpList}, t::ExampleProject::KidsShow::TimberBeam::GetLineUpName());
    push(@{$aLineUpList}, t::ExampleProject::KidsShow::SeeSaw->new()->getLineUpName() );
    return $aLineUpList;
}

1;