# FFI::Struct [![Build Status](https://secure.travis-ci.org/Perl5-FFI/FFI-Struct.png)](http://travis-ci.org/Perl5-FFI/FFI-Struct) ![windows](https://github.com/Perl5-FFI/FFI-Struct/workflows/windows/badge.svg) ![macos](https://github.com/Perl5-FFI/FFI-Struct/workflows/macos/badge.svg)

Structured data types for FFI

# CONSTRUCTOR

## new

```perl
my $struct = FFI::Struct->new(%options);
```

- name

    The name of the struct.

# METHODS

## name

```perl
my $name = $struct->name;
```

Returns the name of the struct.

## ffi

```perl
my $ffi = $struct->ffi;
```

Returns the [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instance for this struct.

## size

```perl
my $bytes = $struct->size;
```

Returns the size of the struct in bytes.

## align

```perl
my $bytes = $struct->align;
```

Returns the structure alignment in bytes.

## create

```perl
my $instance = $struct->create(%initalizers);
```

Creates a new instance of the struct.

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
