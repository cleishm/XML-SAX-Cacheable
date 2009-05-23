=head1 NAME

XML::SAX::Cache::Entry - Interface for a cache store for XML::SAX::Cache

=head1 SYNOPSIS

  package XML::SAX::Cache::MyCache::Entry;
  use XML::SAX::Cache::Entry;

  our @ISA = qw(XML::SAX::Cache::Entry);

=head1 DESCRIPTION

This module defines the required interface for a cache entry for use with
XML::SAX::Cacheable.

Currently this interface is fully implemented by the Cache::Entry module (from
the Cache package on CPAN) which may be used as a concrete caching
implementation.

=head1 METHODS

=over

=cut
package XML::SAX::Cache::Entry;

require 5.005;
use strict;
use warnings;
use Storable qw(freeze thaw);

our $VERSION = '1.00';

=item $e->handle( $mode )

Returns an IO::Handle by which data can be read, or written, to the cache.
If there is no data in the cache, it should return undef.

=cut

sub handle;

=item my $val = $e->validity()

Returns the validity object that was stored with this cache entry.

=cut

sub validity;

=item $e->set_validity($val)

Store a validity object with this cache entry.

=cut

sub set_validity;

=item my $date = $e->expires()

Returns the expiry date (in unix time) for this cache entry.

=cut

sub expires;

=item $e->set_expiry($date)

Set the date (in unix time) that this cache entry should be automatically
expired.

=cut

sub set_expiry;


1;
__END__

=back

=head1 SEE ALSO

XML::SAX::Cacheable

=head1 AUTHOR

Chris Leishman <chris@leishman.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Entry.pm,v 1.10 2006/02/04 14:38:18 caleishm Exp $

=cut
