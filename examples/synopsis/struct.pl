use strict;
use warnings;
use FFI::C::StructDef;

my $def = FFI::C::StructDef->new(
  name  => 'color_t',
  class => 'Color',
  members => [
    red   => 'uint8',
    green => 'uint8',
    blue  => 'uint8',
  ],
);

my $red = $def->create;  # creates a FFI::C::Stuct
$red->red(255);
$red->green(0);
$red->blue(0);

printf "[%02x %02x %02x]\n", $red->red, $red->green, $red->blue;  # [ff 00 00]

my $green = Color->new;  # creates a FFI::C::Stuct
$green->red(0);
$green->green(255);
$green->blue(0);

printf "[%02x %02x %02x]\n", $green->red, $green->green, $green->blue;  # [00 ff 00]
