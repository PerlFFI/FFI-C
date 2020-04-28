use strict;
use warnings;
use FFI::C::ArrayDef;
use FFI::C::StructDef;

my $point_def = FFI::C::StructDef->new(
  name  => 'point_t',
  class => 'Point',
  members => [
    x => 'double',
    y => 'double',
  ],
);

my $rect_def = FFI::C::ArrayDef->new(
  name    => 'rectangle_t',
  class   => 'Rectangle',
  members => [
    $point_def, 2,
  ]
);

my $square = $rect_def->create;
$square->[0]->x(1.0);
$square->[0]->y(1.0);
$square->[1]->x(2.0);
$square->[1]->y(2.0);

my $rect = Rectangle->new;
$rect->[0]->x(1.0);
$rect->[0]->y(1.0);
$rect->[1]->x(2.0);
$rect->[1]->y(3.0);

