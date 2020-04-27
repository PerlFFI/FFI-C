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

  my $self = bless {
    ffi     => $ffi,
    name    => delete $args{name},
    members => {},
    align   => 0,
    size    => 0,
    args    => \%args,
  }, $class;

  if($self->name)
  {
    my $cdef = ref($self);
    $cdef =~ s/Def$//;
    $ffi->load_custom_type('::CDef' => $self->name,
      name => $self->name,
      def  => $self,
      cdef => $cdef,
    );
  }

  $self;
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
    ptr   => $ptr,
    def   => $self,
    owner => $owner,
  }, $class;
}

package FFI::Platypus::Type::CDef;

use Ref::Util qw( is_blessed_ref );

push @FFI::Platypus::CARP_NOT, __PACKAGE__;

sub ffi_custom_type_api_1
{
  my(undef, undef, %args) = @_;

  my $perl_to_native;
  my $native_to_perl;

  my $name  = $args{name};
  my $class = $args{class};
  my $def   = $args{def}  || Carp::croak("no def defined");
  my $cdef  = $args{cdef} || Carp::croak("no cdef defined");

  if($class)
  {
    $perl_to_native = sub {
      Carp::croak("argument is not a $class")
        unless is_blessed_ref $_[0]
        && $_[0]->isa($class);
      my $ptr = $_[0]->{ptr};
      Carp::croak("pointer for $name went away")
        unless defined $ptr;
    };
    $native_to_perl = sub {
      defined $_[0]
        ? bless { ptr => $_[0], owner => 1 }, $class
        : undef;
    };
  }

  elsif($name)
  {
    $perl_to_native = sub {
      Carp::croak("argument is not a $name")
        unless is_blessed_ref $_[0]
        && ref($_[0]) eq $cdef
        && $_[0]->{def}->{name} eq $name;
      my $ptr = $_[0]->{ptr};
      Carp::croak("pointer for $name went away")
        unless defined $ptr;
      $ptr;
    };
    $native_to_perl = sub {
      defined $_[0]
        ? bless { ptr => $_[0], def => $def, owner => 1 }, $cdef
        : undef;
    };
  }

  return {
    native_type    => 'opaque',
    perl_to_native => $perl_to_native,
    native_to_perl => $native_to_perl,
  }
}

1;
