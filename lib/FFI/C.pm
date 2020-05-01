package FFI::C;

use strict;
use warnings;
use 5.008001;
use FFI::C::StructDef;
use FFI::C::UnionDef;
use FFI::C::ArrayDef;
use Carp ();
use Ref::Util qw( is_plain_arrayref );

# ABSTRACT: C data types for FFI
# VERSION

=head1 SYNOPSIS

In your C:

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

In your Perl:

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

=head1 DESCRIPTION

This distribution provides tools for building classes to interface for common C
data types.  Arrays, C<struct>, C<union> and nested types based on those are
supported.

=cut

sub import
{
  my(undef, %args) = @_;
  my($class,$filename) = caller;
  return if $class eq 'main';

  my $name   = delete $args{name} || (lc($class) . '_t');

  my($def_class, $members, @extra) = map { defined $args{$_} ? ('FFI::C::' . ucfirst($_) . 'Def' => delete $args{$_} ) : () } qw( struct union array );
  Carp::croak("Specify only one of 'struct', 'union', or 'array'") if @extra;

  return unless defined $def_class && defined $members;

  Carp::croak("Members must be an array ref")
    unless is_plain_arrayref $members;

  Carp::croak("Unknown option keys: " . join(', ', keys %args))
    if %args;

  $def_class->new(
    FFI::Platypus->new( api => 1 ),
    name    => $name,
    class   => $class,
    members => $members,
  );
}

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut

1;
