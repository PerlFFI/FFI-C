use Test2::V0 -no_srand => 1;
use FFI::C::Util qw( owned take init );
use FFI::Platypus::Memory qw( free );
use FFI::C::StructDef;
use FFI::C::UnionDef;
use FFI::C::ArrayDef;

subtest 'owned / take' => sub {

  imported_ok 'take';
  imported_ok 'owned';

  my $def = FFI::C::StructDef->new(
    name => 'foo_t',
    members => [],
  );

  my $inst = $def->create;

  is
    $inst,
    object {
      call [ isa => 'FFI::C::Struct' ] => T();
      field ptr => match qr/^[0-9]+$/;
      etc;
    },
    'object before take',
  ;

  is owned($inst), T(), 'instance is owned';

  my $ptr = take $inst;
  is $ptr, match qr/^[0-9]+$/, 'gave us a pointer';

  is
    $inst,
    object {
      call [ isa => 'FFI::C::Struct' ] => T();
      field ptr => U();
      etc;
    },
    'object after take',
  ;

  is owned($inst), F(), 'instance is unowned';

};

subtest init => sub {

  my $def = FFI::C::StructDef->new(
    class => 'Class1',
    members => [
      x => 'uint8',
      y => FFI::C::ArrayDef->new(
        class => 'Class2',
        members => [
          FFI::C::StructDef->new(
            class => 'Class3',
            members => [
              foo => 'sint16',
              bar => 'uint32',
              baz => 'double',
            ],
          ),
          2,
        ],
      ),
      z => 'sint16[3]',
      a => FFI::C::UnionDef->new(
        class => 'Class4',
        members => [
          u8  => 'uint8',
          u16 => 'uint16',
        ],
      ),
    ],
  );

  my $inst = $def->create;
  init($inst, {
    x => 1,
    y => [
      { foo => 2, bar => 3, baz => 5.5 },
      { foo => 6, bar => 7, baz => 8.8 },
    ],
    z => [ 1, 2, 3 ],
    a => { u16 => 900 },
  });

  is(
    $inst,
    object {
      call [ isa => 'Class1' ] => T();
      call x => 1;
      call y => object {
        call [ isa => 'Class2' ] => T();
        call [ get => 0 ] => object {
          call [ isa => 'Class3' ] => T();
        };
        call [ get => 1 ] => object {
          call [ isa => 'Class3' ] => T();
        };
      };
      call a => object {
        call [ isa => 'Class4' ] => T();
        # todo
        #call u16 => 900;
      };
    },
    'values initalized',
  );

};

done_testing;
