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

1; # End of Plack::Middleware::Throttle::Lite::Backend::Abstract

__END__

=pod

=head1 SYNOPSYS

=head1 DESCRIPTION

=head1 DESCRIPTION

=head1 OPTIONS

=head1 METHODS

=head2 new

=head2 mk_attrs

=head1 BUGS

=head1 SEE ALSO

=cut
