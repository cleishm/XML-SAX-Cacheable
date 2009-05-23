=head1 NAME

XML::SAX::Cache::Tee - Helper class for defaul XML::SAX::Cacheable

=head1 DESCRIPTION

This module is a helper for the default implementation of the
XML::SAX::Cacheable interface and is not for normal usage.
It defines a wrapper for XML::Filter::Tee that correctly sets all handlers and
also takes care of storing validity objects and setting expiry at the end of
parsing.

=cut
package XML::SAX::Cache::Tee;

require 5.005;
use strict;
use warnings;

use base qw(XML::Filter::Tee);


sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my ($cache_entry, $filter, @handlers) = @_;

	my $self = $class->SUPER::new(@handlers);
	bless $self, $class;

	$self->{SAXCacheEntry} = $cache_entry;
	$self->{SAXCacheFilter} = $filter;
	$self->{SAXCacheHandlers} = \@handlers;

	return $self;
}

sub cache_handlers {
	my $self = shift;
	return @{$self->{SAXCacheHandlers}};
}

sub end_document {
	my $self = shift;

	my $result = $self->SUPER::end_document(@_);

	# Document has ended, retrieve and store the validity object and
	# expiry
	my $validity = $self->{SAXCacheFilter}->cache_validity();
	$self->{SAXCacheEntry}->set_validity($validity) if defined $validity;

	my $expiry = $self->{SAXCacheFilter}->cache_expiry();
	$self->{SAXCacheEntry}->set_expiry($expiry) if defined $expiry;

	return $result;
}


1;
__END__

=head1 SEE ALSO

XML::SAX::Cacheable

=head1 AUTHOR

Chris Leishman <chris@leishman.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Tee.pm,v 1.7 2006/02/04 14:38:18 caleishm Exp $

=cut
