package FFI::C::ArrayDef;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref is_plain_arrayref );
use FFI::C::Array;
use base qw( FFI::C::Def );

# ABSTRACT: Array data definition for FFI
# VERSION

=head1 CONSTRUCTOR

=head2 new

=cut

sub new
{
  my $self = shift->SUPER::new(@_);

  my %args = %{ delete $self->{args} };

  my $member;
  my $count = 0;

  my @members = @{ delete $args{members} || [] };
  if(@members == 1)
  {
    ($member) = @members;
  }
  elsif(@members == 2)
  {
    ($member, $count) = @members;
  }
  else
  {
    Carp::croak("The members argument should be a struct/union type and an optional element count");
  }

  Carp::croak("Illegal member")
    unless defined $member && is_blessed_ref($member) && $member->isa("FFI::C::Def");

  Carp::croak("The element count must be a positive integer")
    if defined $count && $count !~ /^[1-9]*[0-9]$/;

  $self->{size}              = $member->size * $count;
  $self->{align}             = $member->align;
  $self->{members}->{member} = $member;
  $self->{members}->{count}  = $count;

  Carp::carp("Unknown argument: $_") for sort keys %args;

  $self;
}

=head1 METHODS

=head2 create

=cut

sub create
{
  my($self) = @_;

  local $self->{size} = $self->{size};
  my $count = $self->{members}->{count};
  if(@_ == 1 && $_[0] =~ /^[0-9]+$/)
  {
    $count = shift;
    $self->{size} = $self->{members}->{member}->size * $count;
  }

  if( (@_ == 1 && is_plain_arrayref $_[0]) || ($self->size) )
  {
    my $array = $self->SUPER::create(@_);
    $array->{count} = $count;
    return $array;
  }

  Carp::croak("Cannot create array without knowing the number of elements");
}

1;
