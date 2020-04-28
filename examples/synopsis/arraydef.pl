use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::C::ArrayDef;
use FFI::C::StructDef;

my $ffi = FFI::Platypus->new( api => 1 );
# See FFI::Platypus::Bundle for how bundle works.
$ffi->bundle;

my $point_def = FFI::C::StructDef->new(
  $ffi,
  name  => 'point_t',
  class => 'Point',
  members => [
    x => 'double',
    y => 'double',
  ],
);

my $rect_def = FFI::C::ArrayDef->new(
  $ffi,
  name    => 'rectangle_t',
  class   => 'Rectangle',
  members => [
    $point_def, 2,
  ]
);

$ffi->attach( print_rectangle => ['rectangle_t'] );

my $rect = Rectangle->new;
$rect->[0]->x(1.5);
$rect->[0]->y(2.0);
$rect->[1]->x(3.14);
$rect->[1]->y(11.0);

print_rectangle($rect);  # [[1.5 2] [3.14 11]]
