package FFI::C::Struct;

use strict;
use warnings;
use FFI::C::FFI ();

# ABSTRACT: Structured data instance for FFI
# VERSION

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;
  my $name = $AUTOLOAD;
  $name=~ s/^.*:://;
  if(my $member = $self->{def}->{members}->{$name})
  {
    my $ptr = $self->{ptr} + $member->{offset};
    return $member->{nest}->create([$ptr,$self]) if $member->{nest};
    my $ffi = $self->{def}->ffi;
    if(@_)
    {
      $ffi->function( FFI::C::FFI::memcpy_addr() => [ 'opaque', $member->{spec} . "*", 'size_t' ] => 'opaque' )
          ->call($ptr, \$_[0], $member->{size});
    }
    return ${ $ffi->cast( 'opaque' => $member->{spec} . "*", $ptr ) };
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

1;
