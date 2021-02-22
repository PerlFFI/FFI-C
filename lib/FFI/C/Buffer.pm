package FFI::C::Buffer;

use strict;
use warnings;
use FFI::C::FFI ();
use Ref::Util qw( is_ref is_plain_scalarref );

# ABSTRACT: Interface to unstructured C buffer data
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/buffer.pl

=head1 DESCRIPTION

This class provides an interface to an unstructured buffer in memory.  This is essentially a
region of memory as defined by a pointer and a size in bytes.

The size can be undefined when a buffer is immediately returned from C space because buffers
are typically returned as two argument types or an argument and a return value.  Be sure
to set the buffer size on the object as soon as possible, otherwise some operations may
not work.

=head1 CONSTRUCTOR

=head2 new

 my $buf = FFI::C::BUffer->new($buffer_size);
 my $buf = FFI::C::Buffer->new(\$raw);

Creates a new buffer of the given size.

The first form creates an uninitialized buffer of the given size.

The second form creates a buffer the same size as C<$raw> and copies
the content of C<$raw> into it.

If C<$raw> is a Perl UTF-8 string then it will be encoded correctly.

=cut

sub new
{
  my $class = shift;

  my $buffer_size;
  my $ptr;
  my $owner;

  if(@_ == 1)
  {
    if(is_plain_scalarref $_[0])
    {
      die 'todo';
    }
    elsif(!is_ref $_[0])
    {
      $buffer_size = shift;
      $ptr = FFI::C::FFI::malloc($buffer_size);
      die "Unable to allocate $buffer_size bytes" unless defined $ptr;
    }
    else
    {
      die 'bad usage';
    }
  }
  elsif(@_ == 2)
  {
    ($ptr, $owner) = @_;
  }
  else
  {
    die 'wrong number of arguments';
  }

  return bless {
    ptr         => $ptr,
    buffer_size => $buffer_size,
    owner       => $owner,
  }, $class;
}

=head1 METHODS

=head2 buffer_size

 my $size = $buf->buffer_size;
 $buf->buffer_size($size);
 
Get or set the size of the buffer.

Setting the buffer size should be done with great care!  Normally you would only ever
set the buffer size if the buffer is returned from C code and the size of the buffer
is provided by another argument.

You could also set the buffer size to a smaller size to truncate the size of the buffer,
although the space will not be freed until the entire buffer is freed.

=cut

sub buffer_size
{
  my $self = shift;
  @_ > 0
    ? $self->{buffer_size} = shift
    : $self->{buffer_size};
}

sub DESTROY
{
  my($self) = @_;
  if($self->{ptr} && !$self->{owner})
  {
    FFI::C::FFI::free(delete $self->{ptr});
  }
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Buffer>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut
