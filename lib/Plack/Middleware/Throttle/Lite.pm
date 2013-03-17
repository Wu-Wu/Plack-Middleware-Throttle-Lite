package Plack::Middleware::Throttle::Lite;

# ABSTRACT: Requests throttling for Plack

use strict;
use warnings;
use parent 'Plack::Middleware';

# VERSION
# AUTHORITY

sub prepare_app {
    my ($self) = @_;
}

sub call {
    my ($self, $env) = @_;
}

1; # End of Plack::Middleware::Throttle::Lite

__END__

=pod

=head1 SYNOPSYS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 OPTIONS

=head1 METHODS

=head2 prepare_app

=head2 call

=head1 BUGS

=head1 SEE ALSO

L<Plack>

L<Plack::Middleware>

=cut
