use strict;
use warnings;
use FFI::Platypus;
use FFI::C::ASCIIString;

my $ffi = FFI::Platypus->new( api => 1, lib => [undef]);

$ffi->attach( puts => ['opaque'] => 'int' );

my $str = FFI::C::ASCIIString->new(1024);
$str->from_perl("Hello: ");

print "length = ", $str->strlen, "\n";   # prints 7

puts($str->ptr);  # prints Hello:

$str->strcat("World!");

puts($str->ptr);  # prints Hello: World!

