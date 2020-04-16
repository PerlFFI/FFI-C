package FFI::C::StructDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::FFI qw( malloc memset );
use FFI::C::Struct;
use FFI::Platypus 1.11;
use Ref::Util qw( is_blessed_ref is_plain_arrayref );
use FFI::Platypus::Memory qw( malloc );
use Carp ();
use constant _is_union => 0;

# ABSTRACT: Structured data definition for FFI
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $struct = FFI::C::StructDef->new(%options);

=over 4

=item name

The name of the struct.

=back

=cut

sub new
{
  my $class = shift;
  my $ffi = is_blessed_ref($_[0]) && $_[0]->isa('FFI::Platypus') ? shift : FFI::Platypus->new( api => 1 );
  my %args = @_;

  Carp::croak("Only works with FFI::Platypus api level 1 or better") unless $ffi->api >= 1;

  my $self = bless {
    ffi     => $ffi,
    name    => delete $args{name},
    members => {},
    align   => 0,
    size    => 0,
  }, $class;

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
        if($spec->isa('FFI::C::StructDef'))
        {
          $member{nest}  = $spec;
          $member{size}  = $spec->size;
          $member{align} = $spec->align;
        }
      }
      else
      {
        $member{spec}   = $spec;
        $member{size}   = $ffi->sizeof($spec);
        $member{align}  = $ffi->alignof($spec);
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

=head1 METHODS

=head2 name

 my $name = $struct->name;

Returns the name of the struct.

=cut

sub name { shift->{name} }

=head2 ffi

 my $ffi = $struct->ffi;

Returns the L<FFI::Platypus> instance for this struct.

=cut

sub ffi { shift->{ffi} }

=head2 size

 my $bytes = $struct->size;

Returns the size of the struct in bytes.

=cut

sub size { shift->{size} }

=head2 align

 my $bytes = $struct->align;

Returns the structure alignment in bytes.

=cut

sub align { shift->{align} }

=head2 create

 my $instance = $struct->create(%initalizers);

Creates a new instance of the struct.

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
