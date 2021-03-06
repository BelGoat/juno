use strict;
use warnings;
package Juno::Check::Ping;
# ABSTRACT: A Ping check for Juno

use AnyEvent::Ping;
use Moo;
use MooX::Types::MooseLike::Base qw<Int Num Object>;
use namespace::autoclean;
use List::Util qw(first );

with 'Juno::Role::Check';

has pinger => (
    is      => 'ro',
    isa     => Object,
    lazy    => 1,
    default => sub { AnyEvent::Ping->new },
    builder => '_build_pinger'
);

has ping_interval => (
    is        => 'ro',
    isa       => Num,
    predicate => 'has_ping_interval',
);

has ping_timeout => (
    is      => 'ro',
    isa     => Num,
    predicate => 'has_ping_timeout',
);

has count => (
    is      => 'ro',
    isa     => Int, #change this for a check of the data (positive int - no zero)
    default => sub {1},
);


sub _build_pinger {
    my $self   = shift;
    my $pinger = AnyEvent::Ping->new (
        $self->has_ping_timeout  ? ( timeout  => $self->ping_timeout  ) : (),
        $self->has_ping_interval ? ( interval => $self->ping_interval ) : (),
    );

    return $pinger;
}

sub check {
    my $self  = shift;
    my @hosts = @{ $self->hosts };
    my $pinger = $self->pinger;

    foreach my $host (@hosts) {

        $self->has_on_before
            and $self->on_before->( $self, $host );

        $pinger->ping( $host, $self->count, sub {
            my $results = shift;

            $self->has_on_result
                and $self->on_result->( $self, $host, $results );

            if ( first { $_->[0] eq 'OK' } @{$results} ) {
                $self->has_on_success
                    and $self->on_success->( $self, $host, $results );
            } else {
                $self->has_on_fail
                    and $self->on_fail->( $self, $host, $results );
            }
        } );
    }

    return 0;
}

1;

__END__

=head1 DESCRIPTION
	Juno::Check::Ping uses AnyEvent::Ping to check one or more host for consistanc connections and act to a given method.
	Greate for monitoring latency and connection lost and acting accordingly.

=head1 SYNOPSIS

		my $juno = Juno->new(
			checks => {
				Ping => {
					hosts => [ 'tom, 'jerry' ],
				}

=head1 ATTRIBUTES

=head2 pinger
Handle of the pinger method.
Default: AnyEvent::Ping -> new
