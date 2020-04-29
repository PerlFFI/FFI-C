package FFI::C::Struct;

use strict;
use warnings;
use FFI::C::FFI ();

# ABSTRACT: Structured data instance for FFI
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/struct.pl

=head2 DESCRIPTION

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

    return $member->{nest}->create($ptr,$self->{owner} || $self) if $member->{nest};

    if(defined $member->{count})
    {
      my $index = shift;
      if(defined $index)
      {
        Carp::croak("Negative index on array member") if $index < 0;
        Carp::croak("OOB index on array member") if $index >= $member->{count};
        $ptr += $index * $member->{unitsize};
      }
      else
      {
        my @a;
        tie @a, 'FFI::C::Struct::MemberArrayTie', $self, $name, $member->{count};
        return \@a;
      }
    }

    my $ffi = $self->{def}->ffi;
    if(@_)
    {
      my $src = \$_[0];

      # For fixed strings, pad short strings with NULLs
      $src = \($_[0] . ("\0" x ($member->{size} - do { use bytes; length $_[0] }))) if $member->{rec} && $member->{size} > do { use bytes; length $_[0] };

      $ffi->function( FFI::C::FFI::memcpy_addr() => [ 'opaque', $member->{spec} . "*", 'size_t' ] => 'opaque' )
          ->call($ptr, $src, $member->{unitsize} || $member->{size});
    }

    my $value = $ffi->cast( 'opaque' => $member->{spec} . "*", $ptr );
    $value = $$value unless $member->{rec};
    return $value;
  }
  else
  {
    Carp::croak("No such member: $name");
  }
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

=item L<FFI::C::Def>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut
