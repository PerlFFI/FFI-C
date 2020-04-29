use Test2::V0 -no_srand => 1;
use FFI::C::Util qw( take );
use FFI::Platypus::Memory qw( free );
use FFI::C::StructDef;

subtest 'take' => sub {
  imported_ok 'take';
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

};

done_testing;
