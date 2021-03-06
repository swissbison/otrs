# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::CustomerUser::Generic;

use base 'Kernel::Output::HTML::Base';

use strict;
use warnings;

our $ObjectManagerDisabled = 1;

sub Run {
    my ( $Self, %Param ) = @_;

    # check required params
    my @Params = split /;/, $Param{Config}->{Required};
    for my $Key (@Params) {
        return if !$Key;
        return if !$Param{Data}->{$Key};
    }

    # get all attributes
    @Params = split /;/, $Param{Config}->{Attributes};

    # get layout object
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    # build url
    my $URL = '';
    KEY:
    for my $Key (@Params) {
        next KEY if !$Param{Data}->{$Key};
        if ($URL) {
            $URL .= ', ';
        }
        $URL .= $LayoutObject->LinkEncode( $Param{Data}->{$Key} );
    }
    $URL = $Param{Config}->{URL} . $URL;

    my $IconName = $Param{Config}->{IconName};

    # generate block
    $LayoutObject->Block(
        Name => 'CustomerItemRow',
        Data => {
            %{ $Param{Config} },
            URL      => $URL,
            IconName => $IconName,
        },
    );

    return 1;
}

1;
