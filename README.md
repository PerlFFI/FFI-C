# FFI::C [![Build Status](https://travis-ci.org/Perl5-FFI/FFI-C.svg)](http://travis-ci.org/Perl5-FFI/FFI-C) ![windows](https://github.com/Perl5-FFI/FFI-C/workflows/windows/badge.svg) ![macos](https://github.com/Perl5-FFI/FFI-C/workflows/macos/badge.svg)

C data types for FFI

# SYNOPSIS

In C:

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

In Perl:

```perl
use FFI::C;

package ColorValue {
  FFI::C->struct([
    red   => 'uint8',
    green => 'uint8',
    blue  => 'uint8',
  ]);
}

package NamedColor {
  FFI::C->struct([
    name  => 'string(22)',
    value => 'color_value_t',
  ]);
}

package ArrayNamedColor {
  FFI::C->array(['array_named_color_t' => 4]);
};

my $array = ArrayNamedColor->new([
  { name => "red",    value => { red   => 255 } },
  { name => "green",  value => { green => 255 } },
  { name => "blue",   value => { blue  => 255 } },
  { name => "purple", value => { red   => 255,
                                 blue  => 255 } },
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
  FFI::C->union([
    u8  => 'uint8',
    u16 => 'uint16',
    u32 => 'uint32',
    u64 => 'uint64',
  ]);
}

my $int = AnyInt->new({ u8 => 42 });
print $int->u32;
```

# DESCRIPTION

This distribution provides tools for building classes to interface for common C
data types.  Arrays, `struct`, `union` and nested types based on those are
supported.

# METHODS

## ffi

## struct

```
FFI::C->struct($name, \@members);
FFI::C->struct(\@members);
```

Generate a new [FFI::C::Struct](https://metacpan.org/pod/FFI::C::Struct) class with the given `@members` into
the calling package.  (`@members` should be a list of name/type pairs).
You may optionally give a `$name` which will be used for the
[FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) type name for the generated class.  If you do not
specify a `$name`, a C style name will be generated from the last segment
in the calling package name by converting to snake case and appending a
`_t` to the end.

As an example, given:

```perl
package MyLibrary::FooBar {
  FFI::C->struct([
    a => 'uint8',
    b => 'float',
  ]);
};
```

You can use `MyLibrary::FooBar` via the file scoped [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance
using the type `foo_bar_t`.

```perl
my $foobar = MyLibrary::FooBar->new({ a => 1, b => 3.14 });
$ffi->function( my_library_func => [ 'foo_bar_t' ] => 'void' )->call($foobar);
```

## union

```
FFI::C->union($name, \@members);
FFI::C->union(\@members);
```

This works exactly like the `struct` method above, except a
[FFI::C::Union](https://metacpan.org/pod/FFI::C::Union) class is generated instead.

## array

```
FFI::C->array($name, [$type, $count]);
FFI::C->array($name, [$type]);
FFI::C->array([$type, $count]);
FFI::C->array([$type]);
```

This is similar to `struct` and `union` above, except [FFI::C::Array](https://metacpan.org/pod/FFI::C::Array) is
generated.  For an array you give it the member type and the element count.
The element count is optional for variable length arrays, but keep in mind
that when you create such an array you do need to provide a size.

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
