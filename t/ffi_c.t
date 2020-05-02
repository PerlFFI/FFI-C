use Test2::V0 -no_srand => 1;
use FFI::C;
use FFI::Platypus;
use Capture::Tiny qw( capture_merged );

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

{
  my($out, $ret) = capture_merged {
    require './examples/synopsis/c.pl';
  };
  is $ret, T(), 'example compiles';
  note $out;
}

done_testing;
