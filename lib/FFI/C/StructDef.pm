package FFI::C::StructDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::Struct;
use FFI::Platypus 1.11;
use Ref::Util qw( is_blessed_ref );
use Carp ();
use constant _is_union => 0;
use base qw( FFI::C::Def );

# ABSTRACT: Structured data definition for FFI
# VERSION

=head1 CONSTRUCTOR

=head2 new

=cut

sub _is_kind
{
  my($self, $name, $want) = @_;
  my $kind = eval { $self->ffi->_kindof($name) };
  return undef unless defined $kind;
  return $kind eq $want;
}

sub new
{
  my $self = shift->SUPER::new(@_);

  my %args = %{ delete $self->{args} };

  my $offset    = 0;
  my $alignment = 0;
  my $anon      = 0;

  if(my @members = @{ delete $args{members} || [] })
  {
    Carp::croak("Odd number of arguments in member spec") if scalar(@members) % 2;
    while(@members)
    {
      my $name = shift @members;
      my $spec = shift @members;
      my %member;

      if($name ne ':' && $self->{members}->{$name})
      {
        Carp::croak("More than one member with the name $name");
      }

      if($name eq ':')
      {
        $name .= (++$anon);
      }
      elsif($name !~ /^[A-Za-z_][A-Za-z_0-9]+$/)
      {
        Carp::croak("Illegal member name");
      }

      if(is_blessed_ref $spec)
      {
        if($spec->isa('FFI::C::Def'))
        {
          $member{nest}  = $spec;
          $member{size}  = $spec->size;
          $member{align} = $spec->align;
        }
      }
      elsif($self->_is_kind($spec, 'scalar'))
      {
        $member{spec}   = $spec;
        $member{size}   = $self->ffi->sizeof($spec);
        $member{align}  = $self->ffi->alignof($spec);
      }
      elsif($self->_is_kind("$spec*", 'record'))
      {
        $member{spec}   = $spec;
        $member{rec}    = 1;
        $member{size}   = $self->ffi->sizeof("$spec*");
        $member{align}  = $self->ffi->alignof("$spec*");
      }
      else
      {
        Carp::croak("FFI-C doesn't support $spec for struct or union members");
      }

      $self->{align} = $member{align} if $member{align} > $self->{align};

      if($self->_is_union)
      {
        $self->{size} = $member{size} if $member{size} > $self->{size};
        $member{offset} = 0;
      }
      else
      {
        $offset++ while $offset % $member{align};
        $member{offset} = $offset;
        $offset += $member{size};
      }

      $self->{members}->{$name} = \%member;
    }
  }

  $self->{size} = $offset unless $self->_is_union;

  Carp::carp("Unknown argument: $_") for sort keys %args;

  $self;
}

1;
