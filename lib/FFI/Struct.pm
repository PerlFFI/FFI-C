package FFI::Struct;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref );
use FFI::Platypus 1.00;
use FFI::Platypus::Memory qw( malloc );
use Carp ();

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

  # TODO: add ->api method to Platypus
  Carp::croak("Only works with FFI::Platypus api level 1 or better") unless $ffi->{api} >= 1;

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

  if(defined $args{members})
  {
    my @members = @{ $args{members} };
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

  bless {
    ptr    => $ptr,
    def    => $self,
    owner  => undef,
  }, 'FFI::Struct::Instance';
}

package FFI::Struct::Instance;

use FFI::Platypus::Memory ();

sub AUTOLOAD
{
  our $AUTOLOAD;
  my($self, $value) = @_;
  my $member = $AUTOLOAD;
  $member =~ s/^.*:://;
  if($self->{def}->{$member})
  {
  }
  else
  {
    Carp::croak("No such member: $member");
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
