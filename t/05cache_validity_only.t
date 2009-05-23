# Test that cache_enable with the validity_only flag works (does not cache
# data - only caches validity).
#
use strict;
use warnings;
use XML::SAX::PurePerl;
use XML::SAX::Writer;
use Cache::Memory;

use Test::More tests => 10;

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
my $parser = XML::SAX::PurePerl->new(Handler => $filter);


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
$filter->cache_enable($cache_entry, 1);


## Run pipeline

my $testxml =
"<data xmlns:test='http://leishman.org/xml/sax/cacheable/test/1.0'>
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

# Data should NOT be cached
ok(!$cache_entry->get(), 'Pipeline cache is empty');

# Validity should have been set
is($cache_entry->validity(), $validity, 'Validity correctly set');

# The expiry should have been set
is($cache_entry->expiry(), $expiry, 'Expiry correctly set');
