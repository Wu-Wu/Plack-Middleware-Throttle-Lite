package Plack::Middleware::Throttle::Lite::Backend::Abstract;

# ABSTRACT: Base class for Throttle::Lite backends

use strict;
use warnings;
use Carp ();

# VERSION
# AUTHORITY

sub new {
    my ($class) = shift;
    my $args = defined $_[0] && UNIVERSAL::isa($_[0], 'HASH') ? shift : { @_ };
    my $self = $args;
    bless $self, $class;
    $self->init($args);
    return $self;
}

sub init { 1 }

sub mk_attrs {
    my ($class, @attributes) = @_;

    foreach my $attr (@attributes) {
        my $code = sub {
             my ($self, $value) = @_;
             if (@_ == 1) {
                 return $self->{$attr};
             }
             else {
                 return $self->{$attr} = $value;
             }
         };

        my $method = "${class}::${attr}";
        { no strict 'refs'; *$method = $code; }
    }
}

sub reqs_done { Carp::confess 'method \'reqs_done\' is not implemented' }
sub increment { Carp::confess 'method \'increment\' is not implemented' }

__PACKAGE__->mk_attrs(qw(reqs_max requester_id units));

sub settings {
    my ($self) = @_;

    my $settings = {
        'req/day'  => {
            'interval' => 86400,
            'format'   => '%.4d%.2d%.2d',
        },
        'req/hour' => {
            'interval' => 3600,
            'format'   => '%.4d%.2d%.2d%.2d',
        },
    };

    $settings->{$self->units};
}

sub expire_in {
    my ($self) = @_;

    my ($sec, $min) = localtime(time);
    $self->settings->{'interval'} - (60 * $min + $sec);
}

sub ymdh {
    my ($self) = @_;

    my (undef, undef, $hour, $mday, $mon, $year) = localtime(time);
    sprintf($self->settings->{'format'} => (1900 + $year), (1 + $mon), $mday, $hour);
}

sub cache_key {
    my ($self) = @_;

    $self->requester_id . ':' . $self->ymdh
}

1; # End of Plack::Middleware::Throttle::Lite::Backend::Abstract

__END__

=pod

=head1 SYNOPSYS

=head1 DESCRIPTION

=head1 OPTIONS

=head1 METHODS

=head2 new

=head2 init

=head2 mk_attrs

=head2 cache_key

=head2 reqs_done

=head2 increment

=head2 expire_in

=head2 reqs_max

=head2 requester_id

=head2 settings

=head2 units

=head2 ymdh

=head1 BUGS

=head1 SEE ALSO

L<Plack::Middleware::Throttle::Lite::Backend::Simple>

=cut
