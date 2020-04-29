use Test2::V0 -no_srand => 1;
use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( malloc );
use FFI::Platypus::Record;
use FFI::C::StructDef;

{
  my $count = 1;
  sub record
  {
    my $struct = shift;
    my $perl = qq{
      package Rec$count;
      use FFI::Platypus::Record;
      record_layout_1(\@_);
    };
    eval $perl;  ## no critic (BuiltinFunctions::ProhibitStringyEval)
    die $@ if $@;
    my $rec = FFI::Platypus->new( api => 1 )->cast( 'opaque' => "record(Rec$count)*", $struct->{ptr} );
    $count++;
    $rec;
  }
}

is(
  FFI::C::StructDef->new,
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call name => U();
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'unnamed, empty struct',
);

is(
  FFI::C::StructDef->new( name => 'foo_t' ),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty struct',
);

is(
  FFI::C::StructDef->new( FFI::Platypus->new( api => 1 ), name => 'foo_t' ),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty struct, explicit Platypus',
);

my $ptr = malloc(10);

is(
  FFI::C::StructDef->new( members => [
    foo => 'uint8',
    bar => 'uint32',
    baz => 'sint64',
    roger => 'opaque',
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call create => object {
      call [ isa => 'FFI::C::Struct' ] => T();
      call sub { shift->foo         } => 0;
      call sub { shift->bar         } => 0;
      call sub { shift->baz         } => 0;
      call sub { shift->roger       } => U();
      call sub { shift->foo(22)     } => 22;
      call sub { shift->bar(1900)   } => 1900;
      call sub { shift->baz(-500)   } => -500;
      call sub { shift->roger($ptr) } => $ptr;
      call sub { shift->foo         } => 22;
      call sub { shift->bar         } => 1900;
      call sub { shift->baz         } => -500;
      call sub { shift->roger       } => $ptr;
      call sub { record(shift, qw( uint8 foo uint32 bar sint64 baz opaque roger ) ) } => object {
        call foo   =>   22;
        call bar   => 1900;
        call baz   => -500;
        call roger => $ptr;
      };
      call sub { shift->roger(undef) } => U();
      call sub { shift->roger        } => U();
    };
  },
  'with members',
);

is(
  FFI::C::StructDef->new( members => [
    foo => 'uint8',
    bar => FFI::C::StructDef->new( members => [
      baz => 'sint32',
    ]),
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call create => object {
      call sub { shift->foo             } => 0;
      call sub { shift->bar->baz        } => 0;
      call sub { shift->foo(200)        } => 200;
      call sub { shift->bar->baz(-9999) } => -9999;
      call sub { shift->foo             } => 200;
      call sub { shift->bar->baz        } => -9999;
    },
  },
  'nested'
);

is(
  FFI::C::StructDef->new( members => [
    foo => 'string(10)',
  ]),
  object {
    call [ isa => 'FFI::C::StructDef' ] => T();
    call create => object {
      call sub { shift->foo          } => "\0\0\0\0\0\0\0\0\0\0";
      call sub { shift->foo("hello") } => "hello\0\0\0\0\0";
      call sub { shift->foo          } => "hello\0\0\0\0\0";
    },
  },
  'fixed string',
);

{
  my $ffi = FFI::Platypus->new( api => 1 );

  FFI::C::StructDef->new(
    $ffi,
    name => 'value_color_t',
    class => 'Color::Value',
    members => [
      red   => 'uint8',
      green => 'uint8',
      blue  => 'uint8',
    ]
  );

  FFI::C::StructDef->new(
    $ffi,
    name    => 'named_color_t',
    class   => 'Color::Named',
    members => [
      name => 'string(5)',
      value => 'value_color_t',
    ],
  );

  is(
    Color::Named->new,
    object {
      call [ isa => 'Color::Named' ] => T();
      call name => "\0\0\0\0\0";
      call [ name => "red" ] => "red\0\0";
      call name => "red\0\0";
      call value => object {
        call [ isa => 'Color::Value' ] => T();
        call red => 0;
        call [ red => 255] => 255;
        call red   => 255;
        call green => 0;
        call blue  => 0;
      };
    },
    'named color',
  );
}

done_testing;
