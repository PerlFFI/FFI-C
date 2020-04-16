package FFI::C::Def;

use strict;
use warnings;
use 5.008001;
use FFI::C::FFI qw( malloc memset );
use Ref::Util qw( is_blessed_ref is_plain_arrayref );

# ABSTRACT: Data definition for FFI
# VERSION

=head1 CONSTRUCTOR

=head2 new

=cut

sub new
{
  my $class = shift;
  my $ffi = is_blessed_ref($_[0]) && $_[0]->isa('FFI::Platypus') ? shift : FFI::Platypus->new( api => 1 );
  my %args = @_;

  Carp::croak("Only works with FFI::Platypus api level 1 or better") unless $ffi->api >= 1;
  Carp::croak("FFI::C::Def is an abstract class") if $class eq 'FFI::C::Def';

  bless {
    ffi     => $ffi,
    name    => delete $args{name},
    members => {},
    align   => 0,
    size    => 0,
    args    => \%args,
  }, $class;
}

=head1 METHODS

=head2 ffi

=head2 name

=head2 size

=head2 align

=cut

sub name { shift->{name} }
sub ffi  { shift->{ffi} }
sub size { shift->{size} }
sub align { shift->{align} }

=head2 create

=cut

sub create
{
  my $self = shift;;
  my $ptr;
  my $owner;

  if(@_ == 1 && is_plain_arrayref $_[0])
  {
    ($ptr, $owner) = @{ shift() };
  }
  else
  {
    # TODO: we use 1 byte for size 0
    # this is needed if malloc(0) returns undef.
    # we could special case for platforms where malloc(0)
    # returns a constant pointer that can be free()'d
    $ptr = malloc($self->size ? $self->size : 1);
    memset($ptr, 0, $self->size);
  }

  my $class = ref($self);
  $class =~ s/Def$//;

  bless {
    ptr    => $ptr,
    def    => $self,
    owner  => $owner,
  }, $class;
}

1;
