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

my $fullred = Color->new;
$fullred->red(255);
$fullred->green(0);
$fullred->blue(0);

printf "[%x %x %x]\n", $fullred->red, $fullred->green, $fullred->blue; # [ff 0 0]
