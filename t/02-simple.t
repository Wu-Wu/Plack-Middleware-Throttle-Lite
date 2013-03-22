use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use Plack::Middleware::Throttle::Lite::Backend::Simple;

can_ok 'Plack::Middleware::Throttle::Lite::Backend::Simple', qw(
    increment
    reqs_done
    reqs_max
    units
    settings
    expire_in
    cache_key
    ymdh
);

# simple application
my $app = sub {
    [
        200,
        [ 'Content-Type' => 'text/html' ],
        [ '<html><body>OK</body></html>' ]
    ];
};

$app = builder {
    enable 'Throttle::Lite',
        limits => '5 req/hour', backend => 'Simple', routes => '/api/user',
        blacklist => [ '127.0.0.9/32', '10.90.90.90-10.90.90.92', '8.8.8.8', '192.168.0.10/31' ];
    $app;
};

my @per_hour = (
    #   code  used    expire     content              mime
    1,  200,    1,      '',     'OK',              'text/html',
    2,  200,    2,      '',     'OK',              'text/html',
    3,  200,    3,      '',     'OK',              'text/html',
    4,  200,    4,      '',     'OK',              'text/html',
    5,  200,    5,      '1',    'OK',              'text/html',
    6,  503,    5,      '1',    'Limit exceeded',  'text/plain',
    7,  503,    5,      '1',    'Limit exceeded',  'text/plain',
);

test_psgi $app, sub {
    my ($cb) = @_;

    while (my ($num, $code, $used, $expire_in, $content, $type) = splice(@per_hour, 0, 6)) {
        my $reqno = 'Request (' . $num . ')';
        my $res = $cb->(GET '/api/user/login');
        is $res->code,                                      $code,          $reqno . ' code';
        is $res->header('X-Throttle-Lite-Used'),            $used,          $reqno . ' used header';
        is defined($res->header('X-Throttle-Lite-Expire')), $expire_in,     $reqno . ' expire-in header';
        like $res->content,                                 qr/$content/,   $reqno . ' content';
        is $res->content_type,                              $type,          $reqno . ' content type';
    }

};

done_testing();
