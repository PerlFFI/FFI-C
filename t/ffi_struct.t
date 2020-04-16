use Test2::V0 -no_srand => 1;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc );
use FFI::Platypus::Record;
use FFI::Struct;

{
  my $count = 1;
  sub record
  {
    my $struct = shift;
    eval qq{
      package Rec$count;
      use FFI::Platypus::Record;
      record_layout_1(\@_);
    };
    die $@ if $@;
    my $rec = FFI::Platypus->new( api => 1 )->cast( 'opaque' => "record(Rec$count)*", $struct->{ptr} );
    $count++;
    $rec;
  }
}

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

my $ptr = malloc(10);

is(
  FFI::Struct->new( members => [
    foo => 'uint8',
    bar => 'uint32',
    baz => 'sint64',
    roger => 'opaque',
  ]),
  object {
    call [ isa => 'FFI::Struct' ] => T();
    call create => object {
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

done_testing;


