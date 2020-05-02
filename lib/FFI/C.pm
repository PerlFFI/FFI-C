package FFI::C;

use strict;
use warnings;
use 5.008001;
use Carp ();
use Ref::Util qw( is_ref is_plain_arrayref );

# ABSTRACT: C data types for FFI
# VERSION

=head1 SYNOPSIS

In C:

# EXAMPLE: examples/synopsis/c.c

In Perl:

# EXAMPLE: examples/synopsis/c.pl

=head1 DESCRIPTION

This distribution provides tools for building classes to interface for common C
data types.  Arrays, C<struct>, C<union> and nested types based on those are
supported.

=head1 METHODS

=head2 ffi

=cut

our %ffi;

sub _ffi_get
{
  my($filename) = @_;
  $ffi{$filename} ||= do {
    require FFI::Platypus;
    FFI::Platypus->new( api => 1 );
  };
}

sub ffi
{
  my($class, $new) = @_;
  my(undef, $filename) = caller;

  if($new)
  {
    Carp::croak("Already have an FFI::Platypus instance for $filename")
      if defined $ffi{$filename};
    return $ffi{$filename} = $new;
  }

  _ffi_get($filename);
}

=head2 struct

 FFI::C->struct($name, \@members);
 FFI::C->struct(\@members);

Generate a new L<FFI::C::Struct> class with the given C<@members> into
the calling package.  (C<@members> should be a list of name/type pairs).
You may optionally give a C<$name> which will be used for the
L<FFI::Platypus> type name for the generated class.  If you do not
specify a C<$name>, a C style name will be generated from the last segment
in the calling package name by converting to snake case and appending a
C<_t> to the end.

As an example, given:

 package MyLibrary::FooBar {
   FFI::C->struct([
     a => 'uint8',
     b => 'float',
   ]);
 };

You can use C<MyLibrary::FooBar> via the file scoped L<FFI::Platypus> instance
using the type C<foo_bar_t>.

 my $foobar = MyLibrary::FooBar->new({ a => 1, b => 3.14 });
 $ffi->function( my_library_func => [ 'foo_bar_t' ] => 'void' )->call($foobar);

=cut

our $def_class;
sub _gen
{
  shift;
  my($class, $filename) = caller;

  my($name, $members);

  if(@_ == 2 && !is_ref $_[0] && is_plain_arrayref $_[1])
  {
    ($name, $members) = @_;
  }
  elsif(@_ == 1 && is_plain_arrayref $_[0])
  {
    $name = lcfirst [split /::/, $class]->[-1];
    $name =~ s/([A-Z]+)/'_' . lc($1)/ge;
    $name .= "_t";
    ($members) = @_;
  }
  else
  {
    my($method) = map { lc $_ } $def_class =~ /::([A-Za-z]+)Def$/;
    Carp::croak("usage: FFI::C->$method([\$name], \\\@members)");
  }

  $def_class->new(
    _ffi_get($filename),
    name    => $name,
    class   => $class,
    members => $members,
  );
}

sub struct
{
  require FFI::C::StructDef;
  $def_class = 'FFI::C::StructDef';
  goto &_gen;
}

=head2 union

 FFI::C->union($name, \@members);
 FFI::C->union(\@members);

This works exactly like the C<struct> method above, except a
L<FFI::C::Union> class is generated instead.

=cut

sub union
{
  require FFI::C::UnionDef;
  $def_class = 'FFI::C::UnionDef';
  goto &_gen;
}

=head2 array

 FFI::C->array($name, [$type, $count]);
 FFI::C->array($name, [$type]);
 FFI::C->array([$type, $count]);
 FFI::C->array([$type]);

This is similar to C<struct> and C<union> above, except L<FFI::C::Array> is
generated.  For an array you give it the member type and the element count.
The element count is optional for variable length arrays, but keep in mind
that when you create such an array you do need to provide a size.

=cut

sub array
{
  require FFI::C::ArrayDef;
  $def_class = 'FFI::C::ArrayDef';
  goto &_gen;
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
