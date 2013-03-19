package Plack::Middleware::Throttle::Lite;

# ABSTRACT: Requests throttling for Plack

use strict;
use warnings;
use feature ':5.10';
use parent 'Plack::Middleware';
use Plack::Util::Accessor qw(limits maxreq units backend routes blacklist whitelist def_maxreq def_units def_backend);
use Scalar::Util qw(reftype);
use List::MoreUtils qw(any);
use Plack::Util;
use Carp ();
use Net::CIDR::Lite;

# VERSION
# AUTHORITY

#
# Some important routines
sub prepare_app {
    my ($self) = @_;

    $self->def_maxreq(199);
    $self->def_units('req/hour');
    $self->def_backend('Simple');

    $self->_normalize_limits;
    $self->_initialize_backend;
    $self->_normalize_routes;
    $self->blacklist($self->_initialize_accesslist($self->blacklist));
    $self->whitelist($self->_initialize_accesslist($self->whitelist));
}

#
# Execute middleware
sub call {
    my ($self, $env) = @_;

    my $response;

    if ($self->have_to_throttle($env)) {
        return $self->reject_request(blacklist => 503) if $self->is_remote_blacklisted($env);

        if ($self->is_remote_whitelisted($env)) {
            $response = $self->app->($env);
        } else {
            $response = $self->is_limits_available($env) ? $self->app->($env) : $self->reject_request(ratelimit => 503);
        }

        $self->response_cb($response, sub {
            $self->modify_headers(@_);
        });
    }
    else {
        $response = $self->app->($env);
    }

    $response;
}

#
# Rejects incoming request with some reason
sub reject_request {
    my ($self, $reason, $code) = @_;

    my $reasons = {
        blacklist => 'Access from blacklisted IP address cannot be done!',
        ratelimit => 'Limit exceeded!',
    };

    [
        $code,
        [ 'Content-Type' => 'text/plain', ],
        [ $reasons->{$reason} ]
    ];
}

#
# Rate limit normalization
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

#
# Routes' normalization
sub _normalize_routes {
    my ($self) = @_;

    my $routes = [];

    if ($self->routes) {
        given (reftype $self->routes) {
            when (undef) {
                $routes = [ $self->routes ];
            }
            when ('REGEXP') {
                $routes = [ $self->routes ];
            }
            when ('ARRAY') {
                $routes = $self->routes;
            }
            default {
                Carp::croak 'Expected scalar, regex or array reference!';
            }
        }
    }

    $self->routes($routes);
}

#
# Adds extra headers to response
sub modify_headers {
    my ($self, $response) = @_;
    my $headers = $response->[1];

    my %info = (
        Limit => $self->maxreq,
        Units => $self->units,
    );

    map { Plack::Util::header_set($headers, 'X-Throttle-Lite-' . $_, $info{$_}) } sort keys %info;

    $response;
}

#
# Checks if requested path should be throttled
sub have_to_throttle {
    my ($self, $env) = @_;

    any { $env->{PATH_INFO} =~ /$_/ } @{ $self->routes };
}

#
# Checks if the requester's IP in the blacklist
sub is_remote_blacklisted {
    my ($self, $env) = @_;

    $self->_is_listed_in(blacklist => $env);
}

#
# Checks if the requester's IP in the whitelist
sub is_remote_whitelisted {
    my ($self, $env) = @_;

    $self->_is_listed_in(whitelist => $env);
}

#
# Checks if remote IP address in accesslist
sub _is_listed_in {
    my ($self, $list, $env) = @_;

    return unless $self->$list;
    return $self->$list->find($env->{REMOTE_ADDR});
}

#
# Populates the blacklist/whitelist
sub _initialize_accesslist {
    my ($self, $items) = @_;

    my $list = Net::CIDR::Lite->new;

    if ($items) {
        map { $list->add_any($_) } reftype($items) eq 'ARRAY' ? @$items : ( $items );
    }

    $list;
}

#
# Check if limits is not exceeded
sub is_limits_available {
    my ($self, $env) = @_;
    1;
}

#
# Requester's ID
sub requester_id {
    my ($self, $env) = @_;
    join ':' => 'throttle', $env->{REMOTE_ADDR}, ($env->{REMOTE_USER} || 'nobody');
}

1; # End of Plack::Middleware::Throttle::Lite

__END__

=pod

=head1 SYNOPSYS

    # inside your app.psgi
    my $app = builder {
        enable 'Throttle::Lite',
            limits => '100 req/hour', backend => 'Simple', routes => [ qr{^/(host|item)/search}, qr{^/users/add} ],
            blacklist => [ '127.0.0.9/32', '10.90.90.90-10.90.90.92', '8.8.8.8', '192.168.0.10/31' ];
        sub {
            [ 200, ['Content-Type' => 'text/plain'], [ 'OK' ] ];
        }
    };

=head1 DESCRIPTION

=head1 CONFIGURATION OPTIONS

=head2 limits

=head2 backend

=head2 routes

=head2 ident

=head2 blacklist

=head2 whitelist

=head1 METHODS

=head2 prepare_app

See L<Plack::Middleware>

=head2 call

See L<Plack::Middleware>

=head2 modify_headers

Adds extra headers to response..

=head2 reject_request

Rejects incoming request with specific code and reason..

=head2 have_to_throttle

Checks if requested path should be throttled..

=head2 is_remote_blacklisted

Checks if the requester's IP in the blacklist..

=head2 is_remote_whitelisted

Checks if the requester's IP in the whitelist..

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/Wu-Wu/Plack-Middleware-Throttle-Lite/issues>

=head1 SEE ALSO

L<Plack>

L<Plack::Middleware>

=cut
