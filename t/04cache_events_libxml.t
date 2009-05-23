# Test that caching works via a cache_entry that stores SAX events and then
# replays them.  This test checks that everything works with the LibXML SAX
# parser supplying the initial SAX stream.
#
use strict;
use warnings;
use XML::SAX::Writer;
use Cache::Memory;

use Test::More;

eval { require XML::LibXML::SAX::Parser }
	or plan skip_all => 'XML::LibXML is required for this test.';

plan tests => 10;

my $diff;
eval { require XML::SemanticDiff; $diff = XML::SemanticDiff->new() };

use lib 't';
require_ok('TestFilter');


## Create a simple pipeline

# Create output writer
my $testout;
my $writer = XML::SAX::Writer->new(Output => \$testout);

# Create filter
my $filter = TestFilter->new(Handler => $writer);
ok($filter->isa('TestFilter'), 'Filter is correct type');
ok($filter->isa('XML::SAX::Base'), 'Filter is a sax base');
ok($filter->isa('XML::SAX::Cacheable'), 'Filter is cacheable');
ok($filter->can('cacheable'), 'Filter has cacheable method');

# Create parser
my $parser = XML::LibXML::SAX::Parser->new(Handler => $filter);


## Setup caching

# Set a validity string
my $validity = 'A test validity string';
$filter->test_set_validity($validity);

# Set an expiry
my $expiry = time + 600;
$filter->test_set_expiry($expiry);

# Create cache entry
my $cache = Cache::Memory->new();
my $cache_entry = $cache->entry('testentry');

# Enable caching
$filter->cache_enable($cache_entry);


## Run pipeline

my $testxml =
"<?xml version='1.0'?>
<data xmlns:test='http://leishman.org/xml/sax/cacheable/test/1.0'>
<test:somedata>Hello</test:somedata>
<test:moredata>World</test:moredata>
</data>";

# Parse data
$parser->parse_string($testxml);

# Data should be output unchanged
SKIP: {
    $diff or skip 'XML::SemanticDiff required for these tests', 1;
    is(scalar $diff->compare($testout, $testxml), 0, 'Pipeline output is correct');
}

# Entry should now exist
ok($cache_entry->exists(), 'Entry created');

# Validity should have been set
is($cache_entry->validity(), $validity, 'Validity correctly set');

# The expiry should have been set
is($cache_entry->expiry(), $expiry, 'Expiry correctly set');


# Disable caching
$filter->cache_disable();


## Playback cache

# Set new output
my $testout2;
my $writer2 = XML::SAX::Writer->new(Output => \$testout2);
$filter->set_handler($writer2);

# Playback
$filter->cache_playback($cache_entry);

# Data should be same as original output
is($testout2, $testout, 'Cached output is correct');
