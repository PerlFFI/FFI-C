use Test2::V0 -no_srand => 1;
use FFI::C::ArrayDef;
use FFI::C::StructDef;

is(
  FFI::C::ArrayDef->new( name => 'foo', members => [
    FFI::C::StructDef->new( members => [
      u64 => 'uint64',
    ]),
    10,
  ]),
  object {
    call [ isa => 'FFI::C::ArrayDef' ] => T();
    call ffi   => object { call [ isa => 'FFI::Platypus' ] => T() };
    call size  => 80;
    call align => match qr/^[0-9]+$/;
    call name  => 'foo';
    call create => object {
      call [ isa => 'FFI::C::Array' ] => T();
      call [ get => 5] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call sub { shift->u64     } => 0;
        call sub { shift->u64(10) } => 10;
        call sub { shift->u64     } => 10;
      };
      call [ get => 4] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call sub { shift->u64     } => 0;
        call sub { shift->u64(6)  } => 6;
        call sub { shift->u64     } => 6;
      };
      call [ get => 5] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call sub { shift->u64     } => 10;
      };
      call [ get => 4] => object {
        call [ isa => 'FFI::C::Struct' ] => T();
        call sub { shift->u64     } => 6;
      };
      call_list sub { map { $_->u64 } @{ shift() } } => [ 0, 0, 0, 0, 6, 10, 0, 0, 0, 0 ];
    };
  },
  'simple'
);

done_testing;
