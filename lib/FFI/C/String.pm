package FFI::C::String;

use strict;
use warnings;
use base qw( FFI::C::Buffer );
use Carp ();
use Ref::Util qw( is_blessed_hashref );

# ABSTRACT: Base class for C string classes
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/ascii_string.pl

=head1 DESCRIPTION

This is a base class for classes that represent NULL terminated C strings.
The encoding is defined by the subclass.  This class can be instantiated


This class is itself a subclass of L<FFI::C::Buffer>, so you can use all
of the methods that class provides.  In particular it is worth remembering
that the buffer size of the C string object can be larger than the string
contained within.

Subclasses include:

=over 4

=item L<FFI::C::ASCIIString>

=back

=head1 ATTRIBUTES

=head2 encoding_name

 my $name = $str->encoding_name;

Returns the name of the string encoding.  Throws

=cut

sub encoding_name
{
  my($self) = @_;

  if(is_blessed_hashref $self && exists $self->{encoding_name})
  {
    return $self->{encoding_name};
  }
  else
  {
    Carp::croak("No encoding specified for this class / object");
  }
}

=head2 encoding_width

 my $width = FFI::C::ASCIIString->encoding_width;
 my $width = $str->encoding_width;

Returns the size of a character, if the encoding has fixed width characters.  For encodings
which do not have a fixed width per-character this will return undef.

=cut

sub encoding_width
{
  my($self) = @_;

  if(is_blessed_hashref $self && exists $self->{encoding_width})
  {
    return $self->{encoding_width};
  }
  else
  {
    return undef;
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::ASCIIString>

=item L<FFI::C::Buffer>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::String>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut
