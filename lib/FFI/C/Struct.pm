package FFI::C::Struct;

use strict;
use warnings;
use FFI::C::Util;
use FFI::C::FFI ();
use Ref::Util qw( is_ref is_plain_arrayref );

# ABSTRACT: Structured data instance for FFI
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/struct.pl

=head1 DESCRIPTION

This class represents an instance of a C C<struct>.  This class can be created using
C<new> on the generated class, if that was specified for the L<FFI::C::StructDef>,
or by using the C<create> method on L<FFI::C::StructDef>.

For each member defined in the L<FFI::C::StructDef> there is an accessor for the
L<FFI::C::Struct> instance.

=head1 CONSTRUCTOR

=head2 new

 FFI::C::StructDef->new( class => 'User::Struct::Class', ... );
 my $instance = User::Struct::Class->new;

Creates a new instance of the C<struct>.

=cut

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;
  my $name = $AUTOLOAD;
  $name=~ s/^.*:://;
  if(my $member = $self->{def}->{members}->{$name})
  {
    my $ptr = $self->{ptr} + $member->{offset};

    if($member->{nest})
    {
      my $m = $member->{nest}->create($ptr,$self->{owner} || $self);
      FFI::C::Util::perl_to_c($m, $_[0]) if @_;
      return $m;
    }

    my $ffi = $self->{def}->ffi;

    if(defined $member->{count})
    {
      if(defined $_[0])
      {
        if(! is_ref $_[0])
        {
          my $index = shift;
          Carp::croak("$name Negative index on array member") if $index < 0;
          Carp::croak("$name OOB index on array member") if $index >= $member->{count};
          $ptr += $index * $member->{unitsize};
        }
        elsif(is_plain_arrayref $_[0])
        {
          my $array = shift;
          Carp::croak("$name OOB index on array member") if @$array > $member->{count};
          my $asize = @$array * $member->{unitsize};
          $ffi->function( FFI::C::FFI::memcpy_addr() => [ 'opaque', $member->{spec} . "[@{[ scalar @$array ]}]", 'size_t' ] => 'opaque' )
              ->call($ptr, $array, $asize);
          my @a;
          tie @a, 'FFI::C::Struct::MemberArrayTie', $self, $name, $member->{count};
          return \@a;
        }
        else
        {
          Carp::croak("$name tried to set element to non-scalar");
        }
      }
      else
      {
        my @a;
        tie @a, 'FFI::C::Struct::MemberArrayTie', $self, $name, $member->{count};
        return \@a;
      }
    }

    if(@_)
    {
      Carp::croak("$name tried to set member to non-scalar") if is_ref $_[0];

      my $src = \$_[0];

      # For fixed strings, pad short strings with NULLs
      $src = \($_[0] . ("\0" x ($member->{size} - do { use bytes; length $_[0] }))) if $member->{rec} && $member->{size} > do { use bytes; length $_[0] };

      if(my $enum = $member->{enum})
      {
        if(exists $enum->str_lookup->{$$src})
        {
          $src = \($enum->str_lookup->{$$src});
        }
        elsif(exists $enum->int_lookup->{$$src})
        {
          # nothing
        }
        else
        {
          Carp::croak("$name tried to set member to invalid enum value");
        }
      }

      $ffi->function( FFI::C::FFI::memcpy_addr() => [ 'opaque', $member->{spec} . "*", 'size_t' ] => 'opaque' )
          ->call($ptr, $src, $member->{unitsize} || $member->{size});
    }

    my $value = $ffi->cast( 'opaque' => $member->{spec} . "*", $ptr );
    $value = $$value unless $member->{rec};
    $value =~ s/\0.*$// if $member->{trim_string};

    if(my $enum = $member->{enum})
    {
      if($enum->rev eq 'str')
      {
        if(exists $enum->int_lookup->{$value})
        {
          $value = $enum->int_lookup->{$value};
        }
      }
    }

    return $value;
  }
  else
  {
    Carp::croak("No such member: $name");
  }
}

sub can
{
  my($self, $name) = @_;
  $self->{def}->{members}->{$name}
    ? sub { shift->$name(@_) }
    : $self->SUPER::can($name);
}

sub DESTROY
{
  my($self) = @_;
  if($self->{ptr} && !$self->{owner})
  {
    FFI::C::FFI::free(delete $self->{ptr});
  }
}

package FFI::C::Struct::MemberArrayTie;

sub TIEARRAY
{
  my($class, $struct, $name, $count) = @_;
  bless [ $struct, $name, $count ], $class;
}

sub FETCH
{
  my($self, $index) = @_;
  my($struct, $name) = @$self;
  $struct->$name($index);
}

sub STORE
{
  my($self, $index, $value) = @_;
  my($struct, $name) = @$self;
  $struct->$name($index, $value);
}

sub FETCHSIZE
{
  my($self) = @_;
  $self->[2];
}

sub STORESIZE
{
  my($self) = @_;
  $self->[2];
}

sub CLEAR
{
  Carp::croak("Cannot clear");
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
