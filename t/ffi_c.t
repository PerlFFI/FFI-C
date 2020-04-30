use Test2::V0 -no_srand => 1;
use FFI::C;

{ package Color;
  use FFI::C
    struct => [ red   => 'uint8',
                green => 'uint8',
                blue  => 'uint8' ];
}

is(
  Color->new({ blue => 10 }),
  object {
    call [ isa => 'Color' ] => T();
    call red   => 0;
    call green => 0;
    call blue  => 10;
    call [ red => 128 ] => 128;
    call red => 128;
  },
  'create generated struct class',
);

{ package AnyInt;
  use FFI::C
    union => [ u8  => 'uint8',
               u16 => 'uint16',
               u32 => 'uint32',
               u64 => 'uint64' ];
}

is(
  AnyInt->new({u16 => 12}),
  object {
    call [ isa => 'AnyInt' ] => T();
    call u16           => 12;
    call [ u32 => 13 ] => 13;
    call u32           => 13;
  },
  'create generated union class'
);

done_testing;
