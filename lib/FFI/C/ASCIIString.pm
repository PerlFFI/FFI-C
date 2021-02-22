package FFI::C::ASCIIString;

use strict;
use warnings;
use Ref::Util qw( is_plain_scalarref is_ref );
use FFI::Platypus::Buffer 1.28 ();
use base qw( FFI::C::String );

# ABSTRACT: C string class for ASCII
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/ascii_string.pl

=head1 DESCRIPTION

This class represents a NULL terminated C ASCII string, which is common to many C APIs.
It inherits from L<FFI::C::String> and L<FFI::C::Buffer>, so you can use all of the
methods that those classes implement.

In particular, the amount of memory allocated for the string B<can> be more than initially
needed, which allows appending (C<strcat> below) to the end of the string.  By default just
enough space is allocated to store the string, including its NULL termination.

This class endeavors to ensure the string contain only ASCII characters.  If non-ASCII
characters are seen passing to or from C space then this class will throw an exception.

=head1 CONSTRUCTOR

=head2 new

 my $str = FFI::C::ASCIIString->new($buffer_size);
 my $str = FFI::C::ASCIIString->new(\$perl_string);

Creates a new NULL terminated string C string object.

The first form creates a new NULL terminated string C<""> with a buffer capacity of C<$buffer_size>.

The second form computes the buffer size from the provided C<$perl_string> and copies it to the
new C string.  If the Perl string doesn't include the NULL termination it will be added to the
new C string.  If there are non-ASCII characters in the C<$perl_string> then it will throw an exception.

=cut

sub new
{
  my $class = shift;

  if(@_ == 1)
  {
    if(is_plain_scalarref $_[0] && !is_ref ${$_[0]})
    {
      Carp::croak("Non ASCII characters found in string") if ${$_[0]} =~ /[^[:ascii:]]/;

      return ${$_[0]} =~ /\0/
        ? $class->SUPER::new($_[0])
        : $class->SUPER::new(\"${$_[0]}\0");
    }
    elsif(!is_ref $_[0])
    {
      my $self = $class->SUPER::new(@_);
      $self->from_perl("\0");
      return $self;
    }
    else
    {
      return $class->SUPER::new(@_);
    }
  }
  else
  {
    return $class->SUPER::new(@_);
  }
}

=head1 METHODS

=head2 to_perl

 my $perl_string = $str->to_perl;

Copies the NULL terminated C string to a Perl string.
If the string contains non-ASCII characters it will
throw an exception.

=cut

sub to_perl
{
  my $self = shift;
  my $win;
  $self->window($win);
  Carp::croak("Non ASCII characters found in string") if $win =~ /[^[:ascii:]]/;
  my $copy = "$win";
  $copy =~ s/\0.*$//;
  $copy;
}

=head2 from_perl

 $str->from_perl($perl_string);
 $str->from_perl($perl_string, $size);

=cut

sub from_perl
{
  my $self = shift;
  Carp::croak("Argument is undef") unless @_ >= 1 && defined $_[0];
  Carp::croak("Non ASCII characters found in string") if $_[0] =~ /[^[:ascii:]]/;
  if($_[0] !~ /\0/)
  {
    my $str = shift @_;
    unshift @_, "$str\0";
  }
  $self->SUPER::from_perl(@_);
}

=head2 strlen

 my $len = $str->strlen;

Returns the length of the string in characters.

=cut

$FFI::C::FFI::ffi->attach( [ strnlen => 'strlen' ] => ['opaque','size_t'] => 'size_t' => sub {
  my($xsub, $self) = @_;
  $xsub->($self->ptr, $self->buffer_size);
});

=head2 strcat

 $str->strcat($perl_string);

Append the content of the Perl string to the end of the C string.

=cut

$FFI::C::FFI::ffi->attach( [ 'strncat' => 'strcat' ] => ['opaque','string','size_t'] => sub {
  my $xsub = shift;
  my $self = shift;
  Carp::croak("Non ASCII characters found in string") if $_[0] =~ /[^[:ascii:]]/;
  $xsub->($self->ptr, $_[0], $self->buffer_size);
});

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
