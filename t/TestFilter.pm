package TestFilter;

use strict;
use warnings;

use XML::SAX::Base;
use XML::SAX::Cacheable;
our @ISA = qw(XML::SAX::Base XML::SAX::Cacheable);

sub cache_validity {
	my $self = shift;
	return $self->{TestFilterValidity};
}

sub cache_expiry {
	my $self = shift;
	return $self->{TestFilterExpires};
}

sub test_set_validity {
	my $self = shift;
	my ($validity) = @_;
	$self->{TestFilterValidity} = $validity;
}

sub test_set_expiry {
	my $self = shift;
	my ($expires) = @_;
	$self->{TestFilterExpires} = $expires;
}

1;
