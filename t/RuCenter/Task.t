#!/usr/bin/env perl
use strict;
use warnings;
use v5.36;
use Data::Dumper;
use Test::More tests => 6;

use lib "src/lib";
use RuCenter::Task;

my @routes = (
    # вот по этому роуту непонятно, так что предполагается, что это "отдельный" маршрут, не связанный с операциями CRUD
    '/api/v1/:storage/:pk/raw',

    '/api/v1/:storage/:pk/:op',
    '/api/v1/:storage/:pk',
);

my @tests = (
    {
        'url' => 'http://localhost:8080/api/v1/order/123/raw',
        'index' => 0,
        'params' => {
            storage => 'order',
            pk => '123',
        }
    },

    {
        'url' => 'http://localhost:8080/api/v1/order/123/update',
        'index' => 1,
        'params' => {
            storage => 'order',
            pk => '123',
            op => 'update'
        }
    },

    {
        'url' => 'http://localhost:8080/api/v1/order/123',
        'index' => 2,
        'params' => {
            storage => 'order',
            pk => '123',
        }
    },
);

my $router = RuCenter::Task->new(\@routes);

foreach my $test (@tests) {
    my $result = $router->find_route($test->{'url'});

    is( $result->{'index'},  $test->{'index'} );
    is_deeply( $result->{'params'}, $test->{'params'});
}
