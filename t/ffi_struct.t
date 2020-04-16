use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Struct;

is(
  FFI::Struct->new,
  object {
    call [ isa => 'FFI::Struct' ] => T();
    call name => U();
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 1;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::Struct::Instance' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'unnamed, empty struct',
);

is(
  FFI::Struct->new( name => 'foo_t' ),
  object {
    call [ isa => 'FFI::Struct' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 1;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::Struct::Instance' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty struct',
);

is(
  FFI::Struct->new( FFI::Platypus->new( api => 1 ), name => 'foo_t' ),
  object {
    call [ isa => 'FFI::Struct' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 1;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::Struct::Instance' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty struct, explicit Platypus',
);

is(
  FFI::Struct->new( members => [
    foo => 'uint8',
    bar => 'uint32',
    baz => 'sint64',
  ]),
  object {
    call [ isa => 'FFI::Struct' ] => T();
    call create => object {
      call sub { shift->foo(22)   } => 22;
      call sub { shift->bar(1900) } => 1900;
      call sub { shift->baz(-500) } => -500;
      call sub { shift->foo       } => 22;
      call sub { shift->bar       } => 1900;
      call sub { shift->baz       } => -500;
    };
  },
  'with members',
);

done_testing;


