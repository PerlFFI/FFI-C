package FFI::C::String;

use strict;
use warnings;
use FFI::Platypus::Memory ();
use Encode ();
use Carp ();
use FFI::C::FFI ();
use Ref::Util qw( is_plain_arrayref is_blessed_hashref is_ref );

# ABSTRACT: Structured data instance for FFI
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/string.pl

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

 my $str = FFI::C::String->new($size);
 my $str = FFI::C::String->new([$string]);
 my $str = FFI::C::String->new([$string, $size]);
 my $str = FFI::C::String->new([$string, $size, $type]);

Allocate C<$size> bytes for a new string object.
If provided, C<$string> converted into the appropriate encoding and 
copied into the new string.  The C<NULL> terminator will be included
in the new string object.
If the C<$size> is not provided, then the size will be computed
based on C<$string>.

C<$type> should be one of:

=over 4

=item ASCII

Plan 8bit ASCII strings that work with most libc functions.

=item Wide

Strings that use the C<wchar_t> type.  On Unix this is typically a 32bit code point using UTF-32.
On Windows this could be either UCS-2 or UTF-16 (commonly referred to as WTF-16).  The endianness
of the code points will match the CPU architecture that you are running on.

=item UTF8

UTF-8

=back

=cut

sub new
{
  my $class = shift;

  my $string;
  my $size;
  my $type;

  my $ptr;
  my $owner;

  if(@_ == 1)
  {
    if(! is_ref $_[0])
    {
      $size = $_[0];
    }
    elsif(is_plain_arrayref $_[0])
    {
      ($string, $size, $type) = @{ $_[0] };
    }

    $size = $class->size unless defined $size;
    unless(defined $string)
    {
      Carp::croak("String type does not have a default size") unless $size > 0;
      $string = '';
    }

    if($class eq 'FFI::C::String')
    {
      $type = 'ASCII' unless defined $type;
      $class = "FFI::C::${type}String";
      Carp::croak("No such string type: $type") unless $class->can("new");
    }

    $ptr = FFI::Platypus::Memory::malloc($size);
  }
  elsif(@_ == 2)
  {
    ($ptr, $owner) = @_;
  }

  my $self = bless {
    ptr   => $ptr,
    owner => $owner,
    size  => $size,
  }, $class;

  if(defined $string)
  {
    # TODO: can we do this without so many intermediate copies?
    my $buf = Encode::encode($self->encoding, "$string\0");
    my $len = length $buf;
    $len = $size if $len > $size;
    FFI::C::FFI::memcpy($ptr, $buf, $len);
  }

  $self;
}

=head1 METHODS

=head2 size

 my $size = FFI::C::String->size;
 my $size = $str->size;

Returns the size of the string in bytes.

=cut

sub _default_size { 0 }

sub size
{
  my($self) = @_;

  if(is_blessed_hashref $self && $self->isa('FFI::C::String'))
  {
    return $self->{size};
  }
  else
  {
    return $self->_default_size;
  }
}

=head2 encoding

 my $enc = FFI::C::String->encoding;
 my $enc = $str->encoding;

Returns the encoding of the string, as understood by L<Encode>.

=cut

sub encoding
{
  Carp::croak("The base string class does not have an encoding");
}

sub DESTROY
{
  my($self) = @_;
}

package FFI::C::ASCIIString;

our @ISA = qw( FFI::C::String );   ## no critic (ClassHierarchies::ProhibitExplicitISA)

sub encoding { 'ASCII' }

package FFI::C::WideString;

our @ISA = qw( FFI::C::String );   ## no critic (ClassHierarchies::ProhibitExplicitISA)

# TODO: this is probably roughly right for modern platforms,
# but we want to make this more bullet proof.
sub encoding { $^O eq 'MSWin32' ? 'UTF-16le' : 'UTF-32le' }

package FFI::C::UTF8String;

our @ISA = qw( FFI::C::String );   ## no critic (ClassHierarchies::ProhibitExplicitISA)

sub encoding { 'UTF-8' }

1;

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

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
