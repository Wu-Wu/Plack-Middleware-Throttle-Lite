package Plack::Middleware::Throttle::Lite::Backend::Simple;

# ABSTRACT: Simple (in-memory) backend for Throttle::Lite

use strict;
use warnings;
use parent 'Plack::Middleware::Throttle::Lite::Backend::Abstract';

# VERSION
# AUTHORITY

my $_storage;

sub reqs_done {
    my ($self) = @_;
    exists $_storage->{$self->cache_key} ? $_storage->{$self->cache_key} : 0;
}

sub increment {
    my ($self) = @_;
    $_storage->{$self->cache_key}++;
}

1; # End of Plack::Middleware::Throttle::Lite::Backend::Simple

__END__

=pod

=head1 SYNOPSIS

    # inside your app.psgi
    enable 'Throttle::Lite', backend => 'Simple';

=head1 DESCRIPTION

This is very simple implemetation of the storage backend. It holds all data in memory. If you restart application
all data will be flushed.

=head1 CONFIGURATION

The parameter B<backend> must be set to C<Simple> in order to use this storage backend with
the Throttle::Lite middleware in your Plack application.

=head1 METHODS

=head2 reqs_done

Returns total proceeded requests for current key.

=head2 increment

Increments total proceeded requests by one for current key.

=head1 SEE ALSO

L<Plack::Middleware::Throttle::Lite>

L<Plack::Middleware::Throttle::Lite::Backend::Abstract>

=cut
