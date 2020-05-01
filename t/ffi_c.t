use Test2::V0 -no_srand => 1;
use FFI::C;
use FFI::Platypus;

my $ffi = FFI::Platypus->new( api => 1 );

is(
  FFI::C->ffi($ffi),
  object {
    call [ isa => 'FFI::Platypus' ] => T();
  },
  'FFI::C->ffi first set ok',
);

is(
  dies { FFI::C->ffi($ffi) },
  match qr/Already have an FFI::Platypus instance for/,
  'FFI::C->ffi second call dies',
);

is(
  FFI::C->ffi,
  object {
    call [ isa => 'FFI::Platypus' ] => T();
  },
  'FFI::C->ffi can call get as many times as we like',
);

done_testing;
