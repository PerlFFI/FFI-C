package FFI::C::String;

use strict;
use warnings;
use base qw( FFI::C::Buffer );
use Carp ();
use Ref::Util qw( is_blessed_hashref is_plain_hashref is_plain_scalarref is_ref);
use Encode ();

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

=head1 CONSTRUCTOR

=head2 new

 my $str = FFI::C::ASCIIString->new(\%args);

Supported arguments:

=over 4

=item encoding_name

[required]

The encoding name as understood by L<Encode>.

=item encoding_width

[optional]

The number of bytes it takes to represent a character, if the encoding is fixed-width.
If the encoding is not fixed-width or you aren't sure this should be C<undef>.

=item buffer_size

[require this or string]

The size of the buffer.  This can be larger than the initial string provided.

=item string

[require this or buffer_size]

The Perl string to initially populate the new string object.  This should be a Perl string,
possibly with Unicode characters in it which will be encoded into the proper encoding.

=back

=cut

sub new
{
  my $class = shift;

  local $@;
  eval { $class->encoding_name };
  if($@)
  {
    if(defined $_[0] && is_plain_hashref $_[0])
    {
      my %args = %{ $_[0] };
      Carp::croak("encoding_name is required") unless defined $args{encoding_name};

      my $encoding = Encode::find_encoding($args{encoding_name});
      Carp::croak("Unknown encoding: $args{encoding_name}") unless defined $encoding;

      Carp::croak("buffer_size or string are required") unless defined $args{buffer_size} || defined $args{string};

      my $self = $class->SUPER::new(defined $args{buffer_size} ? $args{buffer_size} : \$args{string});
      $self->{encoding_name} = $encoding->name;
      $self->{encoding_width} = $args{encoding_width} if defined $args{encoding_width};
      $args{string} = '' unless defined $args{string};
      $self->from_perl($args{string});
      return $self;
    }
    else
    {
      Carp::croak("No encoding provided for this class / object");
    }
  }
  elsif(@_ == 1)
  {
    if(is_plain_scalarref $_[0] && !is_ref ${$_[0]})
    {
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

=head1 PROPERTIES

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
  my $copy = $self->SUPER::to_perl;
  $copy =~ s/\0.*$//sm;  #  doesn't work for UTF-16 UTF-32 etc.
  Encode::decode($self->encoding_name, $copy, Encode::FB_CROAK);
}

=head2 from_perl

 $str->from_perl($perl_string);
 $str->from_perl($perl_string, $size);

Copy the content of a Perl into the C string.

=cut

sub from_perl
{
  my $self = shift;
  Carp::croak("Argument is undef") unless @_ >= 1 && defined $_[0];
  my $str = shift @_;
  $str .= "\0" unless $str =~ /\0/;
  $str = Encode::encode($self->encoding_name, $str, Encode::FB_CROAK);
  $self->SUPER::from_perl($str, @_);
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
