use Test2::V0 -no_srand => 1;
use FFI::Union;

is(
  FFI::Union->new,
  object {
    call [ isa => 'FFI::Union' ] => T();
    call name => U();
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::Union::Instance' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'unnamed, empty union',
);

is(
  FFI::Union->new( name => 'foo_t' ),
  object {
    call [ isa => 'FFI::Union' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::Union::Instance' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty union',
);

is(
  FFI::Union->new( FFI::Platypus->new( api => 1 ), name => 'foo_t' ),
  object {
    call [ isa => 'FFI::Union' ] => T();
    call name => 'foo_t';
    call ffi => object {
      call [ isa => 'FFI::Platypus' ] => T();
    };
    call size => 0;
    call align => match qr/^[0-9]+$/;
    call create => object {
      call [ isa => 'FFI::Union::Instance' ] => T();
      call sub { my $self = shift; dies { $self->foo } } => match qr/No such member/;
    };
  },
  'named, empty union, explicit Platypus',
);

is(
  FFI::Union->new( members => [
    u8  => 'uint8',
    u16 => 'uint16',
    u32 => 'uint32',
    u64 => 'uint64',
  ]),
  object {
    call [ isa => 'FFI::Union' ] => T();
    # I don't think there is any arch out there where 8-64 ints
    # are more than 8 byte aligned?
    call size => 8;
    call create => object {
      call [ isa => 'FFI::Union::Instance' ] => T();
      call sub { shift->u8          } => 0;
      call sub { shift->u16         } => 0;
      call sub { shift->u32         } => 0;
      call sub { shift->u64         } => 0;
      call sub { shift->u8(22)      } => 22;
      call sub { shift->u8          } => 22;
      call sub { shift->u16(1024)   } => 1024;
      call sub { shift->u16         } => 1024;
      call sub { shift->u32(999999) } => 999999;
      call sub { shift->u32         } => 999999;
      call sub { shift->u64(55)     } => 55;
      call sub { shift->u64         } => 55;
    };
  },
  'union with members',
);

done_testing;
