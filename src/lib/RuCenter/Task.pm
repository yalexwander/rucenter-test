#!/usr/bin/env perl
package RuCenter::Task;
use strict;
use warnings;

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;
    return $self->_init(@args);
}

sub _init {
    my ($self, @args) = @_;

    $self->{'routes'} = $args[0];
    $self->{'route_params'} = [];
    $self->{'regexps'} = [];
    $self->_build_regex_for_routes;

    return $self;
}


sub _build_regex_for_routes {
    my ($self) = @_;

    foreach my $route (@{ $self->{'routes'} }) {
        # делаем допущение, что у нас нет в роуте метасимволов типа * и прочих, которые могут быть неправильно интерпретированы регуляркой.
        # иначе нужно будет повозиться с quotemeta или \Q и \E
        my $regex = $route;
        # делаем допущение о допустимых символах в имени параметра
        my @route_params = $route =~ /:([a-z0-9]+)/g;
        push @{$self->{'route_params'}}, \@route_params;

        $regex =~ s/:([a-z0-9]+)/\([^\/]+\)/g;
        push @{$self->{'regexps'}}, $regex;
    }

    # вероятно, можно сделать общую регулярку-склейку, и может будет
    # работать быстрее, но тяжело отлаживать. Также как и варианты с
    # деревом или конечным автоматом.
}

sub find_route {
    my ($self, $url) = @_;

    my $result = {
        'index' => -1,
        'params' => {}
    };

    my $path = substr(
        $url,
        index($url, "/", length("https://"))
    );
    # более правильный способ, но зависимость
    # my (undef, undef, $path) = URI::Split::uri_split($url);

    my @matched = ();
    my $matched_no = 0;
    my @route_params = ();
    foreach my $regexp (@{ $self->{'regexps'} }) {
        if (@route_params = $path =~ m/$regexp/) {
            push @matched, $matched_no;
            last;
        }
        $matched_no++;
    }

    # поскольку в условии сказано "первый подходящий маршрут", можем
    # позволить просто взять номер. Иначе - можно сортировать @matched
    # или по длине или по количеству задекларированных параметров
    if (@matched) {
        $result->{'index'} = $matched[0];

        for (my $i = 0; $i < @route_params; $i++) {
            $result->{'params'}->{
                $self->{'route_params'}->[$result->{'index'}]->[$i]
            } = $route_params[$i];
        }
    }

    return $result;
}

1;
