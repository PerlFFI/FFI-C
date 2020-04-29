use Test2::V0 -no_srand => 1;
use FFI::C::Util qw( owned take );
use FFI::Platypus::Memory qw( free );
use FFI::C::StructDef;

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

done_testing;
