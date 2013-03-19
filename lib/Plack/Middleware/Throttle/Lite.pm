package Plack::Middleware::Throttle::Lite;

# ABSTRACT: Requests throttling for Plack

use strict;
use warnings;
use feature ':5.10';
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(limits maxreq units backend def_maxreq def_units def_backend);
use Scalar::Util qw(reftype);
use Plack::Util;
use Carp ();

# VERSION
# AUTHORITY

sub prepare_app {
    my ($self) = @_;

    $self->def_maxreq(199);
    $self->def_units('req/hour');
    $self->def_backend('Simple');

    $self->_normalize_limits;
    $self->_initialize_backend;

}

sub call {
    my ($self, $env) = @_;
    $self->app->($env);
}

#
# Rate limits normalization
sub _normalize_limits {
    my ($self) = @_;

    my $units = {
        'm' => 'req/min',
        'h' => 'req/hour',
        'd' => 'req/day',
    };

    my $limits_re = qr{^(?<numreqs>\d*)(\s*)(r|req)(\/|\sper\s)(?<units>h|hour|d|day|m|min).*};

    if ($self->limits) {
        my $t_limits = lc($self->limits);
        $t_limits =~ s/\s+/ /g;
        $t_limits =~ /$limits_re/;
        $self->maxreq($+{numreqs} || $self->def_maxreq);
        $self->units($units->{$+{units}} || $self->def_units)
    }
    else {
        $self->maxreq($self->def_maxreq);
        $self->units($self->def_units)
    }
}

#
# Storage backend
sub _initialize_backend {
    my ($self) = @_;

    my ($class, $args) = ($self->def_backend, {});

    if ($self->backend) {
        given (reftype $self->backend) {
            when (undef)   { ($class, $args) = ($self->backend, {})            }
            when ('ARRAY') { ($class, $args) = @{ $self->backend }             }
            default        { Carp::croak 'Expected scalar or array reference!' }
        }
    }

    my $backend = Plack::Util::load_class($class, 'Plack::Middleware::Throttle::Lite::Backend');

    $self->backend($backend->new($args));
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
