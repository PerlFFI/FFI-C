use Test2::V0 -no_srand => 1;
use FFI::C::String;

is dies { FFI::C::String->new }, match qr/You cannot create an instance of FFI::C::String/;

done_testing;
