=head1 NAME

XML::SAX::Cacheable - XML::SAX::Base interface extension for caching

=head1 SYNOPSIS

  package XML::Filter::MyFilter;
  use XML::SAX::Base;
  use XML::SAX::Cacheable;

  our @ISA = qw(XML::SAX::Base XML::SAX::Cacheable);

=head1 DESCRIPTION

This module extends the interface for XML::SAX to include methods for
controlling the caching of output.  It's default behaviour is to allow the
output of the SAX handler to be cached indefinitely.  This module requires no
initialization.

You can use this interface by simply adding it to your ISA inheritance list,
and then defining any methods you want to.

=head1 REQUIREMENTS

In order to add XML::SAX::Cacheable support using the default methods, your
module must support the get_handler() and set_handler() methods.  These are
provided by XML::SAX::Base automatically so modules using that as a base will
work fine.

=head1 METHODS

A number of methods are defined as the public interface for the caching
system.  Most methods have a default implementation.

=over

=cut
package XML::SAX::Cacheable;

require 5.005;
use strict;
use warnings;
use Carp;

our $VERSION = '1.00';
our @ISA = qw( Exporter );
our @EXPORT_OK = qw( make_cacheable );

=item $x->cacheable()

Returns 1 if the filter output is cacheable, otherwise returns undef.  In the
latter case users should NOT try to call any of the other cache_* methods on
the object, as it may not implement them.

The default implementation returns 1.

=cut

sub cacheable {
    return 1;
}

=item $x->cache_key()

If the output is not going to be consistent for the same input, but is likely
to occur regularly, the filter can return a true value from $x->cacheable(),
and return a key here that can be used to identify the specific variant it
will be outputting on the next run.

For example, a filter than inserts one of 5 random quotes into a document
could return a key string in the set [1..5] to indicate the specific variant.

Users of this interface should use this key when selecting a cache entry
object to supply to the other cache_* methods.  Note that there is no
requirement that the key returned here is globally unique - two filters
returning the same key here would still require different cache entry objects.

The default implementation returns undef (no key).

=cut

sub cache_key {
    return undef;
}

=item $x->cache_immutable($cache_entry)

Returns a boolean value (1 or 0) indicating whether the filter is immutable,
or undef if it is currently unknown.  A filter is immutable if it will always
result in the same output (given the same input) and thus has no dependencies
on other data sources.

When this method is called on the first run (before anything is cached) some
filters wont yet know if they have dependencies or not.  In this situation the
filter should return undef here and then at the end of the run store the
dependencies into the cache (using $cache_entry->set_validity($blah)) or at
least store an indication that there were no dependencies.  On later runs the
cache_entry should be queried (using $blah = $cache_entry->validity()) and the
dependency information extracted - thus allowing a defined result to be
returned.

Example:

    sub cache_immutable {
        my ($self, $cache_entry) = @_;
        # If there is no validity, then this is the first run
        my $validity = $cache_entry->validity();
        defined $validity or return undef;
        # If validity is empty then there are no dependencies
        return $validity? 1 : 0;
    }

The default implementation of this method returns 0.

=cut

sub cache_immutable {
    return 0;
}

=item $x->cache_check($cache_entry)

Returns a boolean value indicating whether the cache is up-to-date with
respect to any dependencies.  If necessary the module can determine this by
comparing with the validity object stored in the cache.

The default implementation returns 1, indicating the cache is always valid.

=cut

sub cache_check {
    return 1;
}

=item $x->cache_enable($cache_entry, [ $validity_only ] )

This method is invoked to direct the filter to cache it's output to the
$cache_entry.  This method should not be called a second time without calling
$x->cache_disable() first.

An optional second argument, $validity_only, is a boolean used to indicate
that the filter should only store a validity object (and expiry) into the
cache - and should not actually store any data.  This is useful if the user
wants to be able to determine when a filters output becomes inconsistent
with previous runs (by calling cache_check) but doesn't actually want to be
able to replay the data from the cache.  This may occur, for instance, with
SAX generators that will not benefit from caching - but where it is required
to know if their output is consistent in order to control caching further down
a SAX pipeline.  It is not required that the filter implement this behaviour,
it may ignore this flag and always cache, but it is strongly desirable.

The default implementation sets up caching by replacing the handler for the
filter with XML::SAX::Cache::Tee, that duplicates the output to the original
handler(s) and also to a consuming filter that stores the SAX events.  By
default that filter is a instance of XML::Filter::Recorder initialized using a
filehandle (which is obtained via $cache_entry->handle()), but this can be
changed by redefining the sax_recorder() method.

At the end of processing $x->cache_expiry() and $x->cache_validity() are
called to retrieve a expiry object and a validity object, which are then
stored in the cache using $cache_entry->set_expiry() and
$cache_entry->set_validity() respectively.

=cut

my @sax_handlers = qw(
    Handler ContentHandler DocumentHandler DTDHandler
    LexicalHandler ErrorHandler DeclHandler EntityResolver
);

sub cache_enable {
    my $self = shift;
    my ($cache_entry, $validity_only) = @_;

    # We require modules here here instead of 'using' above as subclasses
    # might override this method and nolonger need these classes loaded.

    # Subclass of XML::Filter::Tee that takes care of storing validity
    require XML::SAX::Cache::Tee;

    # Extract old handlers
    my %orig_handlers;
    foreach (@sax_handlers) {
        my $handler = $self->get_handler($_)
            or next;
        $orig_handlers{$_} = $handler;
    }

    if (my $handler = $orig_handlers{Handler}) {
        $handler->isa('XML::SAX::Cache::Tee')
                and croak "Cache has already been enabled";
    }

    # The existing handlers are stored into the specially crafted Tee
    # class, since we can't store anything into self as we don't know
    # what it's actual type is.
    my @tee_handlers = ( \%orig_handlers );

    # Add the recorder to tee_handlers - unless we're only caching the validity
    unless ($validity_only) {
        my $fh = $cache_entry->handle('>');
        my $cache_consumer = $self->sax_recorder($fh);
        push(@tee_handlers, $cache_consumer);
    }

    my $tee = XML::SAX::Cache::Tee->new($cache_entry, $self, @tee_handlers);
    
    # Set the default handler to go via the Tee filter, and remove the rest
    foreach (keys %orig_handlers) {
        $self->set_handler($_, undef);
    }
    $self->set_handler($tee);
}

=item $x->cache_disable()

This method is invoked to disable caching.

=cut

sub cache_disable {
    my $self = shift;

    my $tee = $self->get_handler();
    
    $tee->isa('XML::SAX::Cache::Tee')
        or croak "Cache has not been enabled";

    my @handlers = $tee->cache_handlers();
    my $orig_handlers = shift(@handlers);

    # Restore the handlers
    while (my ($key, $handler) = each %$orig_handlers) {
        $self->set_handler($key, $handler);
    }
}

=item $x->cache_playback($cache_entry)

This method causes the cached data to be 'played back' to the downstream SAX
handlers.  This method should NOT be called if caching is enabled (via
cache_enable).  In scalar context it returns a boolean result indicating
whether playback was attempted or whether the cache was empty.  In list
context it also returns the result from the recorder playback function as the
2nd element - this is typically whatever was returned by end_document in the
final handler.  Any failures during playback will be delivered as exceptions.

The user should call cache_check before attempting this method to ensure that
the result is up-to-date.  Then the return value of this method should be
checked to ensure the cached data hasn't expired.

=cut

sub cache_playback {
    my $self = shift;
    my ($cache_entry) = @_;

    if (my $handler = $self->get_handler()) {
        $handler->isa('XML::SAX::Cache::Tee')
            and croak "Can't playback when cache has been enabled";
    }

    my $fh = $cache_entry->handle('<');

    # return if stream is empty
    return undef if not $fh or eof($fh);

    my $cache_recorder = $self->sax_recorder($fh);

    foreach (@sax_handlers) {
        my $handler = $self->get_handler($_)
            or next;
        $cache_recorder->set_handler($_, $handler);
    }

    my $result = $cache_recorder->playback();

    return wantarray? ( 1, $result ) : 1;
}


=back

=head1 'PROTECTED' METHODS

These methods do not form part of the XML::SAX::Cacheable interface, and are
not required to be implemented by classes that support cacheability.  However
the default implementation of cache_check and cache_enable invoke these
'protected' methods to provide a mechanism for derived classes to control the
caching process.

=over

=item $x->cache_validity()

Returns a validity string (or serialisable object) for storing along with the
cached version.

=cut

sub cache_validity {
    return undef;
}

=item $x->cache_expiry()

Returns an integer value indicating the unix time that the cache should expire
at.

=cut

sub cache_expiry {
    return undef;
}

=item $x->sax_recorder($handle)

Returns a recorder object for storing SAX events to the cache (and playing
them back).  Returns an object of type XML::Filter::Recorder by default.

=cut

sub sax_recorder {
	my $self = shift;
	require XML::Filter::Recorder;
	return XML::Filter::Recorder->new(@_);
}


=back

=head1 MAKING A SAX FILTER CACHEABLE

Hopefully, over time, authors of SAX handlers will start to add the required 
cache-ability methods into their interface.  However, to add cache-ability to
any SAX handlers interface you can import the 'make_cacheable' function and
use it to add default implementations of all the cacheability methods into the
handlers interface.  It will only add the methods if the filters package
doesn't already have a 'cacheable' method.

Note that the default implementations mean the handlers output will be
considered indefinitely cacheable and there will be no dependencies
considered.

Use 'make_cacheable' as follows:

  use XML::SAX::Cacheable qw(make_cacheable);

  make_cacheable('XML::Filter::SomeFilter');

This will import the methods into the XML::Filter::SomeFilter package.
make_cacheable returns a true value (1) if it is successful, or a false value
(undef) otherwise.

=cut

sub make_cacheable {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return undef if $class->can('cacheable');

    my $code = "package $class;\n";

    foreach my $sub (
        'cacheable','cache_key', 'cache_immutable',
        'cache_check', 'cache_enable', 'cache_disable',
        'cache_playback', 'cache_validity', 'cache_expiry')
    {
        $code .= "*$sub = \\\&XML::SAX::Cacheable::$sub;\n";
    }

    $code .= "1;";
    eval $code or die $@;
    return 1;
}

1;
__END__

=head1 SEE ALSO

XML::SAX::Cache::Entry, XML::Filter::Recorder, XML::SAX::Base

=head1 AUTHOR

Chris Leishman <chris@leishman.org>

=head1 COPYRIGHT

Copyright (C) 2006 Chris Leishman.  All Rights Reserved.

This module is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND,
either expressed or implied. This program is free software; you can
redistribute or modify it under the same terms as Perl itself.

$Id: Cacheable.pm,v 1.16 2006/02/06 06:11:58 caleishm Exp $

=cut
