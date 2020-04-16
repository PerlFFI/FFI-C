package FFI::Struct;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref );
use FFI::Platypus 1.11;
use FFI::Platypus::Memory qw( malloc );
use Carp ();
use constant memset => FFI::Platypus->new( lib => [undef] )->find_symbol( 'memset' );

# ABSTRACT: Structured data types for FFI
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $struct = FFI::Struct->new(%options);

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

      $member{spec}   = $spec;
      $member{size}   = $ffi->sizeof($spec);
      $member{align}  = $ffi->alignof($spec);
      $self->{align} = $member{align} if $member{align} > $self->{align};

      $offset++ while $offset % $member{align};
      $member{offset} = $offset;
      $offset += $member{size};

      $self->{members}->{$name} = \%member;
    }
  }

  $self->{size} = $offset;

  # TODO: this is needed if malloc(0) returns undef.
  # we could special case for platforms where malloc(0)
  # returns a constant pointer that can be free()'d
  $self->{size} = 1 if $self->{size} == 0;

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
  my($self) = @_;

  my $ptr = malloc($self->size);
  $self->ffi->function( memset() => ['opaque','int','size_t'] => 'opaque' )
    ->call($ptr, 0, $self->size);

  bless {
    ptr    => $ptr,
    def    => $self,
    owner  => undef,
  }, 'FFI::Struct::Instance';
}

package FFI::Struct::Instance;

use FFI::Platypus::Memory ();
use constant memcpy => FFI::Platypus->new( lib => [undef] )->find_symbol( 'memcpy' );

sub AUTOLOAD
{
  our $AUTOLOAD;
  my $self = shift;
  my $name = $AUTOLOAD;
  $name=~ s/^.*:://;
  if(my $member = $self->{def}->{members}->{$name})
  {
    my $ffi = $self->{def}->ffi;
    my $ptr = $self->{ptr} + $member->{offset};
    if(@_)
    {
      $ffi->function( memcpy() => [ 'opaque', $member->{spec} . "*", 'size_t' ] => 'opaque' )
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
    FFI::Platypus::Memory::free(delete $self->{ptr});
  }
}

1;
