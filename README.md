# FFI::C [![Build Status](https://travis-ci.org/Perl5-FFI/FFI-C.svg)](http://travis-ci.org/Perl5-FFI/FFI-C) ![windows](https://github.com/Perl5-FFI/FFI-C/workflows/windows/badge.svg) ![macos](https://github.com/Perl5-FFI/FFI-C/workflows/macos/badge.svg)

C data types for FFI

# SYNOPSIS

In your C:

```
#include <stdint.h>

typedef struct {
  uint8_t red;
  uint8_t green;
  uint8_t blue;
} color_value_t;

typedef struct {
  char name[22];
  color_value_t value;
} named_color_t;

typedef named_color_t array_named_color_t[4];

typedef union {
  uint8_t  u8;
  uint16_t u16;
  uint32_t u32;
  uint64_t u64;
} anyint_t;
```

In your Perl:

```perl
package ColorValue {
  use FFI::C
    name => 'color_value_t',
    struct => [
      red => 'uint8',
      green => 'uint8',
      blue  => 'uint8',
    ];
}

package NamedColor {
  use FFI::C
    name => 'named_color_t',
    struct => [
      name => 'string(22)',
      value => 'color_value_t',
    ];
}

package ArrayNamedColor {
  use FFI::C
    name => 'array_named_color_t',
    array => [ 'array_named_color_t', 4 ];
}

my $array = ArrayNamedColor->new([
  { name => "red",    value => { red => 255   } },
  { name => "green",  value => { green => 255 } },
  { name => "blue",   value => { blue => 255  } },
  { name => "purple", value => { red => 255,
                                 blue => 255  } },
]);

# dim each color by 1/2
foreach my $color (@$array)
{
  $color->value->red  ( $color->value->red   / 2 );
  $color->value->green( $color->value->green / 2 );
  $color->value->blue ( $color->value->blue  / 2 );
}

# print out the colors
foreach my $color (@$array)
{
  printf "%s [%02x %02x %02x]\n",
    $color->name,
    $color->value->red,
    $color->value->green,
    $color->value->blue;
}

package AnyInt {
  use FFI::C
    name => 'anyint_t',
    union => [
      u8  => 'uint8',
      u16 => 'uint16',
      u32 => 'uint32',
      u64 => 'uint64',
    ];
}

my $int = AnyInt->new({ u8 => 42 });
print $int->u32;
```

# DESCRIPTION

This distribution provides tools for building classes to interface for common C
data types.  Arrays, `struct`, `union` and nested types based on those are
supported.

# SEE ALSO

- [FFI::C](https://metacpan.org/pod/FFI::C)
- [FFI::C::Array](https://metacpan.org/pod/FFI::C::Array)
- [FFI::C::ArrayDef](https://metacpan.org/pod/FFI::C::ArrayDef)
- [FFI::C::Def](https://metacpan.org/pod/FFI::C::Def)
- [FFI::C::Struct](https://metacpan.org/pod/FFI::C::Struct)
- [FFI::C::StructDef](https://metacpan.org/pod/FFI::C::StructDef)
- [FFI::C::Union](https://metacpan.org/pod/FFI::C::Union)
- [FFI::C::UnionDef](https://metacpan.org/pod/FFI::C::UnionDef)
- [FFI::C::Util](https://metacpan.org/pod/FFI::C::Util)
- [FFI::Platypus::Record](https://metacpan.org/pod/FFI::Platypus::Record)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
