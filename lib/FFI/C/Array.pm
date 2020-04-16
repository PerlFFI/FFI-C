package FFI::C::Array;

use strict;
use warnings;
use FFI::C::FFI ();
use overload
  '@{}' => \&tie,
  bool => sub { 1 },
  fallback => 1;

# ABSTRACT: Array instance for FFI
# VERSION

=head1 METHODS

=head2 get

=head2 count

=head2 tie

=cut

sub get
{
  my($self, $index) = @_;
  Carp::croak("Negative array index") if $index < 0;
  Carp::croak("OOB array index") if $self->{count} && $index >= $self->{count};
  my $member = $self->{def}->{members}->{member};
  my $ptr = $self->{ptr} + $member->size * $index;
  $member->create([$ptr,$self->{owner} || $self]);
}

sub count { shift->{count} }

sub tie
{
  my @a;
  CORE::tie @a, 'FFI::C::ArrayTie', shift;
  \@a;
}

sub DESTROY
{
  my($self) = @_;
  if($self->{ptr} && !$self->{owner})
  {
    FFI::C::FFI::free(delete $self->{ptr});
  }
}

package FFI::C::ArrayTie;

sub TIEARRAY
{
  my($class, $array) = @_;
  bless \$array, $class;
}

sub FETCH
{
  my($self, $index) = @_;
  ${$self}->get($index);
}

sub STORE
{
  Carp::croak("Cannot set");
}

sub FETCHSIZE
{
  my($self) = @_;
  ${$self}->count;
}

sub STORESIZE
{
  my($self) = @_;
  ${$self}->count;
}

sub CLEAR
{
  Carp::croak("Cannot clear");
}

1;
