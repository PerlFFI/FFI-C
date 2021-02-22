package FFI::C::Buffer;

use strict;
use warnings;
use FFI::Platypus::Buffer 1.28 ();
use FFI::C::FFI ();
use Ref::Util qw( is_ref is_plain_scalarref );
use Carp qw( croak );

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

The buffer is freed when the buffer object is undefined or falls out of scope.  Care must be
taken that the pointer isn't being used after the buffer is freed.

=head1 CONSTRUCTOR

=head2 new

 my $buf = FFI::C::BUffer->new($buffer_size);
 my $buf = FFI::C::Buffer->new(\$raw);

Creates a new buffer of the given size.

The first form creates an uninitialized buffer of the given size.

The second form creates a buffer the same size as C<$raw> and copies
the content of C<$raw> into it.  Keep in mind that if C<$raw> is a
UTF-8 Perl string then that flag will be lost when the data is
retrieved from the buffer object in Perl and you will need to encode
it to get it back to its original state.

=cut

sub new
{
  my $class = shift;

  Carp::croak("You cannot create an instance of FFI::C::String directly")
    if $class eq 'FFI::C::String';

  my $buffer_size;
  my $ptr;
  my $owner;

  if(@_ == 1)
  {
    my $src_ptr;
    if(is_plain_scalarref $_[0] && !is_ref ${$_[0]})
    {
      ($src_ptr, $buffer_size) = FFI::Platypus::Buffer::scalar_to_buffer(${$_[0]});
    }
    elsif(!is_ref $_[0])
    {
      $buffer_size = shift;
    }
    else
    {
      die 'bad usage';
    }
    $ptr = FFI::C::FFI::malloc($buffer_size);
    die "Unable to allocate $buffer_size bytes" unless defined $ptr;
    FFI::C::FFI::memcpy($ptr, $src_ptr, $buffer_size) if defined $src_ptr;
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

=head2 ptr

 my $ptr = $buf->ptr;

Get the pointer to the start of the buffer.

Care should be taken when using this pointer, because the buffer will be
freed if the C<$buf> object is explicitly freed or falls out of scope.
If the buffer is freed then the pointer is no longer valid.

=cut

sub ptr
{
  shift->{ptr};
}

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

=head2 to_perl

 my $raw = $buf->to_perl;

Copies the raw data into a Perl scalar and returns it.  If this is UTF-8 (or some
other encoding) data then you will want to encode it before treating it as such.

=cut

sub to_perl
{
  my($self) = @_;
  my $win;
  $self->window($win);
  return $win;  # oddly this will copy the scalar.
}

=head2 window

 $buf->window($win);

This creates a read-only window into the buffer.  This can save some memory and
time if you want to just read from the buffer in Perl without having to copy
it into a real Perl scalar.

As with other methods, care must be taken with the window variable if the buffer
is freed.

=cut

sub window
{
  my $self = shift;
  if(@_ == 1)
  {
    push @_, $self->ptr, $self->buffer_size;
    goto \&FFI::Platypus::Buffer::window;
  }
  else
  {
    Carp::croak("usage: \$buf->window(\$win)");
  }
}

=head2 from_perl

 $buf->from_perl($raw)
 $buf->from_perl($raw, $size)

Copies the raw data from C<$raw> into the buffer.  In the first form the size copied is
computed from the size of the scalar C<$raw>.  If the size of C<$raw> is larger than
the buffer, then an exception will be thrown.

In the second form, C<$size> bytes will be copied.  If this is larger than C<$raw> or
larger than the buffer then an exception will be thrown.

=cut

sub from_perl
{
  my $self = shift;
  if(@_ == 1)
  {
    my($src_ptr, $src_size) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
    Carp::croak("Source scalar is larger than the buffer") if $src_size > $self->buffer_size;
    FFI::C::FFI::memcpy($self->{ptr}, $src_ptr, $src_size);
  }
  elsif(@_ == 2)
  {
    my $size = pop;
    my($src_ptr, $src_size) = FFI::Platypus::Buffer::scalar_to_buffer($_[0]);
    Carp::croak("Specified size is larger than source string") if $size > $src_size;
    Carp::croak("Specified size is larger than the buffer") if $size > $self->buffer_size;
    FFI::C::FFI::memcpy($self->{ptr}, $src_ptr, $size);
  }
  else
  {
    Carp::croak("usage: \$buf->from_perl(\$raw [, \$size])");
  }

  1;
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
