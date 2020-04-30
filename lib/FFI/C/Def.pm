package FFI::C::Def;

use strict;
use warnings;
use 5.008001;
use FFI::C::FFI qw( malloc memset );
use FFI::C::Util;
use Ref::Util qw( is_blessed_ref is_ref is_plain_hashref );
use Sub::Install ();

# ABSTRACT: Data definition for FFI
# VERSION

=head1 SYNOPSIS

In your C code:

# EXAMPLE: examples/synopsis/structdef.c

In your Perl code:

# EXAMPLE: examples/synopsis/structdef.pl

=head1 DESCRIPTION

This class is the base class for all def classes in the L<FFI::C> collection.
The def classes are for defining C C<struct>, C<union> and array types that
can be used from Perl and passed to C via L<FFI::Platypus>.

You don't create an instance of this class directly, rather one of the subclasses:
L<FFI::C::StructDef>, L<FFI::C::UnionDef>, L<FFI::C::ArrayDef>.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::StructDef->new(%opts);
 my $def = FFI::C::StructDef->new($ffi, %opts);
 my $def = FFI::C::UnionDef->new(%opts);
 my $def = FFI::C::UnionDef->new($ffi, %opts);
 my $def = FFI::C::ArrayDef->new(%opts);
 my $def = FFI::C::ArrayDef->new($ffi, %opts);

The constructor for this class shouldn't be invoked directly.  If you try
and exception will be thrown.

For subclasses, the first argument should be the L<FFI::Platypus> instance
that you want to use with the def.  If you do not provide it, then one
will be created internally for you.  All def classes accept these standard options:

=over 4

=item name

The L<FFI::Platypus> alias for this def.  This name can be used
in function signatures when creating or attaching functions in L<FFI::Platypus>.

=item class

The Perl class for this def.  The Perl class can be used to create an instance
of this def instead of invoking the C<create> method below.

=item members

This is an array reference, which specifies the member fields for the
def.  How exactly it works depends on the subclass, so see the documentation
for the specific def class that you are using.

=back

=cut

sub new
{
  my $class = shift;

  Carp::croak("Attempt to call new on a def object (did you mean ->create?)") if is_blessed_ref $class;

  my $ffi = is_blessed_ref($_[0]) && $_[0]->isa('FFI::Platypus') ? shift : FFI::Platypus->new( api => 1 );
  my %args = @_;

  Carp::croak("Only works with FFI::Platypus api level 1 or better") unless $ffi->api >= 1;
  Carp::croak("FFI::C::Def is an abstract class") if $class eq 'FFI::C::Def';

  my $self = bless {
    ffi     => $ffi,
    name    => delete $args{name},
    class   => delete $args{class},
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
      name  => $self->name,
      class => $self->class,
      def   => $self,
      cdef  => $cdef,
    );
    $ffi->_def('FFI::C::Def', $self->name, $self);
  }

  $self;
}

sub _generate_class
{
  my($self, @accessors) = @_;

  # first run through all the members, and make sure that we
  # can generate a class based on the def.  That means that:
  #  1. there is no constructor or destructor defined yet.
  #  2. none of the member accessors already exist
  #  3. Any nested cdefs have Perl classes, this will be done
  #     in the subclass

  foreach my $method (qw( new DESTROY ))
  {
    my $accessor = join '::', $self->class, $method;
    Carp::croak("$accessor already defined") if $self->class->can($method);
  }

  foreach my $name (@accessors)
  {
    next if $name =~ /^:/;
    my $accessor = $self->class . '::' . $name;
    Carp::croak("$accessor already exists")
      if $self->class->can($name);
  }

  require FFI::Platypus::Memory;

  if($self->isa('FFI::C::ArrayDef'))
  {

    my $size = $self->size;
    my $count = $self->{members}->{count};
    my $member_size = $self->{members}->{member}->size;

    Sub::Install::install_sub({
      code => sub {
        my $class = shift;
        my($ptr, $owner);

        my $size  = $size;
        my $count = $count;
        if(@_ == 1 && !is_ref $_[0])
        {
          $count = shift;
          $size = $member_size * $count;
        }

        if(@_ == 2 && ! is_ref $_[0])
        {
          ($ptr, $owner) = @_;
        }
        else
        {
          Carp::croak("Cannot create array without knowing the number of elements")
            unless $size;
          $ptr = FFI::Platypus::Memory::malloc($size);
          FFI::Platypus::Memory::memset($ptr, 0, $size);
        }
        bless {
          ptr   => $ptr,
          owner => $owner,
          count => $count,
        }, $class;
      },
      into => $self->class,
      as   => 'new',
    });
  }
  else
  {
    my $size = $self->size;
    $size = 1 unless $size > 0;
    Sub::Install::install_sub({
      code => sub {
        my $class = shift;
        my($ptr, $owner);
        if(@_ == 2 && ! is_ref $_[0])
        {
          ($ptr, $owner) = @_;
        }
        else
        {
          $ptr = FFI::Platypus::Memory::malloc($size);
          FFI::Platypus::Memory::memset($ptr, 0, $size);
        }
        bless {
          ptr => $ptr,
          owner => $owner,
        }, $class;
      },
      into => $self->class,
      as   => 'new',
    });
  }

  Sub::Install::install_sub({
    code => \&_common_destroy,
    into => $self->class,
    as   => 'DESTROY',
  });
}

sub _common_destroy
{
  my($self) = @_;
  if($self->{ptr} && !$self->{owner})
  {
    FFI::Platypus::Memory::free(delete $self->{ptr});
  }
}

=head1 METHODS

=head2 ffi

 my $ffi = $def->ffi;

Returns the L<FFI::Platypus> instance used by this def.

=head2 name

 my $name = $def->name;

Return the L<FFI::Platypus> alias for this def.  This name can be used
in function signatures when creating or attaching functions in L<FFI::Platypus>.

=head2 class

 my $class = $def->class;

Returns the Perl class for this def, if one was specified.  The Perl class
can be used to create an instance of this def instead of invoking the
C<create> method below.

=head2 size

 my $size = $def->size;

Returns the size of the def in bytes.

=head2 align

 my $align = $def->align;

Returns the alignment in bytes of the def.

=cut

sub name  { shift->{name} }
sub class { shift->{class} }
sub ffi   { shift->{ffi} }
sub size  { shift->{size} }
sub align { shift->{align} }

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;  # if class was specified

Creates an instance of the def.

=cut

sub create
{
  my $self = shift;

  return $self->class->new(@_) if $self->class;

  my $ptr;
  my $owner;

  if(@_ == 2 && ! is_ref $_[0])
  {
    ($ptr, $owner) = @_;
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

  my $inst = bless {
    ptr   => $ptr,
    def   => $self,
    owner => $owner,
  }, $class;

  FFI::C::Util::init($inst, $_[0]) if @_ == 1 && is_plain_hashref $_[0];

  $inst;
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
      $ptr;
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
