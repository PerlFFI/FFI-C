package FFI::C::String;

use strict;
use warnings;
use FFI::Platypus::Memory ();
use FFI::Platypus::Buffer 1.28 ();
use Encode ();
use Carp ();
use FFI::C::FFI ();
use List::Util ();
use Ref::Util qw( is_plain_arrayref is_blessed_hashref is_ref );

# ABSTRACT: Structured data instance for FFI
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/string.pl

=head1 DESCRIPTION

=head1 CONSTRUCTOR

=head2 new

 my $cstring = FFI::C::String->new($size);
 my $cstring = FFI::C::String->new([$string]);
 my $cstring = FFI::C::String->new([$string, $size]);
 my $cstring = FFI::C::String->new([$string, $size, $type]);

Allocate C<$size> bytes for a new C string object.
If provided, C<$string> converted into the appropriate encoding and
copied into the new string.  A C<NULL> terminator will be included
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

  my $size;   # TODO: size should be divisible by 1, 2 or 4 bytes depending on the encoding.
  my $ptr;
  my $owner;

  if(@_ == 1)
  {

    my $string;
    my $type;

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

    # TODO: handle FFI::C::String objects  (same as ->copy)
    # TODO: handle stringified objects     (same as ->copy)
    # TODO: if we are going from ASCII -> ASCII or ASCII or UTF-8 -> UTF-8
    #       we might be able to simplify this.
    # TODO: handle truncate?  can we even do that with UTF-8????
    $string = "$string\0" unless $string =~ /\0/;
    my $tmp = Encode::encode($class->encoding, $string);
    $size = length($tmp) if $size == 0;

    $ptr = FFI::Platypus::Memory::malloc($size);

    FFI::C::FFI::memcpy($ptr, $tmp, $size);
  }
  elsif(@_ == 2)
  {
    ($ptr, $owner) = @_;
  }

  bless {
    ptr   => $ptr,
    owner => $owner,
    size  => $size,
  }, $class;
}

=head1 METHODS

=head2 copy

 my $count = $cstring->copy($sorce);

Copy the content of C<$source> into C<$cstring>, overwriting any existing
value.   C<$source> can be either a regular Perl string, or another
L<FFI::C::String> object.  If the encoding for C<$source> and C<$cstring>
do not match, then it will be re-encoded to match at the destination
to match C<$cstring>.

Returns a count of the number of bytes copied.  If the source string
is larger than what can fit into the strings buffer, the string will
be truncated at the destination and the count will be smaller than
the source string.

=cut

sub copy
{
  my($self, $source) = @_;

  Carp::croak("Source string is undef") unless defined $source;

  if(is_blessed_hashref $source && $source->isa("FFI::C::String"))
  {
    # TODO: can we do this without so many intermediate copies?
    my $win;
    FFI::Platypus::Buffer::window($win, $source->{ptr}, $source->{size});
    my $tmp = Encode::encode($self->encoding, Encode::decode($source->encoding, $win));
    my $len = List::Util::min(length $tmp, $self->size);
    FFI::C::FFI::memcpy($self->{ptr}, $tmp, $len);
    return $len;
  }

  # stringify objects that can be stringified if not
  # already Perl strings.
  if(is_ref $source)
  {
    $source = "$source";
  }

  my $tmp = Encode::encode($self->encoding, $source);
  my $len = List::Util::min(length $tmp, $self->size);
  FFI::C::FFI::memcpy($self->{ptr}, $tmp, $len);

  return $len;
}

=head2 to_string

 my $string = $cstring->to_string;

Converts the NULL terminated C string C<$cstring> back to a Perl string.
The Perl string will be re-encoded appropriately.

=cut

sub to_string
{
  my($self) = @_;

  $DB::single = 1;
  my $buf = FFI::Platypus::Buffer::buffer_to_scalar($self->{ptr}, $self->{size});
  $buf =~ s/\0.*$//;
  return Encode::decode($self->encoding, $buf);
}

=head2 size

 my $size = FFI::C::String->size;
 my $size = $cstring->size;

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
 my $enc = $cstring->encoding;

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
