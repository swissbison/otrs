# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::Base;

use strict;
use warnings;

use utf8;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get UserID param
    $Self->{UserID} = $Param{UserID} || die "Got no UserID!";

    return $Self;
}

=head1 NAME

Kernel::Output::HTML::Base - Base class for Output classes

=head1 SYNOPSIS

    package Kernel::Output::HTML::ToolBar::MyToolBar;
    use base 'Kernel::Output::HTML::Base';

    # methods go here

=head1 PUBLIC INTERFACE

=item new()

Creates an object. Call it not on this class, but on a subclass.

    use Kernel::Output::HTML::ToolBar::MyToolBar;
    my $Object = Kernel::Output::HTML::ToolBar::MyToolBar->new(
        UserID  => 123,
    );

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

1;
