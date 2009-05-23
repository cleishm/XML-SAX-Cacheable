use Test::More tests => 4;

BEGIN { use_ok('XML::SAX::Cacheable', 'make_cacheable'); }
use XML::SAX::Base;

ok(make_cacheable('XML::SAX::Base'), 'making cacheable');
ok(XML::SAX::Base::cacheable(), 'cacheable method was added');

ok(!make_cacheable('XML::SAX::Base'), 'trying to remake cacheable');
