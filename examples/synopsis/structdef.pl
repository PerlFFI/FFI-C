use strict;
use warnings;
use FFI::Platypus 1.00;
use FFI::C::StructDef;

my $ffi = FFI::Platypus->new( api => 1 );
# See FFI::Platypus::Bundle for how bundle works.
$ffi->bundle;

my $def = FFI::C::StructDef->new(
  $ffi,
  name  => 'color_t',
  class => 'Color',
  members => [
    red   => 'uint8',
    green => 'uint8',
    blue  => 'uint8',
  ],
);

my $red = Color->new;
$red->red(255);
$red->green(0);
$red->blue(0);

my $green = Color->new;
$green->red(0);
$green->green(255);
$green->blue(0);

$ffi->attach( print_color => ['color_t'] );

print_color($red);   # [ff 00 00]
print_color($green); # [00 ff 00]
