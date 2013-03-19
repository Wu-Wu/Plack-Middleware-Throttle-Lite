use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Plack::Middleware::Throttle::Lite;

can_ok 'Plack::Middleware::Throttle::Lite', qw(prepare_app call limits);

# simple application
my $app = sub {
    [
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ];
};

eval { $app = builder { enable 'Throttle::Lite', backend => 'Bogus'; $app } };
like $@, qr|Can't locate Plack.*Bogus\.pm|, 'Unknown non-FQN backend exception';

eval { $app = builder { enable 'Throttle::Lite', backend => [ 'Bogus' => {} ]; $app } };
like $@, qr|Can't locate Plack.*Bogus\.pm|, 'Unknown non-FQN backend exception with options';

eval { $app = builder { enable 'Throttle::Lite', backend => '+My::Own::Bogus'; $app } };
like $@, qr|Can't locate My.*Bogus\.pm|, 'Unknown FQN backend exception';

eval { $app = builder { enable 'Throttle::Lite', backend => { 'Bogus' => {} }; $app } };
like $@, qr|Expected scalar or array reference|, 'Invalid backend configuration exception (hash ref)';

eval { $app = builder { enable 'Throttle::Lite', backend => (bless {}, 'Bogus'); $app } };
like $@, qr|Expected scalar or array reference|, 'Invalid backend configuration exception (blessed ref)';

# $app = builder {
#     enable 'Throttle::Lite',
#         limits => '100 req/hour';
#     $app;
# };

# test_psgi $app, sub {
#     my ($cb) = @_;
#     my $res = $cb->(GET '/');
#     is $res->code, 200;
# };

done_testing();
