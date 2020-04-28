package FFI::C::StructDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::Struct;
use FFI::C::FFI ();
use FFI::Platypus 1.11;
use Ref::Util qw( is_blessed_ref is_plain_arrayref);
use Carp ();
use Sub::Install ();
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
  my $method = $self->ffi->can('kindof') || $self->ffi->can('_kindof');
  die "The platypus you are using doesn't support kindof method" unless $method;
  my $kind = eval { $self->ffi->$method($name) };
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
        local $@;
        $member{align}  = eval { $self->ffi->alignof("$spec*") };
        Carp::croak("FFI-C doesn't support $spec for struct or union members") if $@;
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

  if($self->class)
  {

    # first run through all the members, and make sure that we
    # can generate a class based on the def.  That means that:
    #  1. there is no constructor or destructor defined yet.
    #  2. none of the member accessors already exist
    #  3. Any nested cdefs have Perl classes.

    foreach my $method (qw( new DESTROY ))
    {
      my $accessor = join '::', $self->class, $method;
      Carp::croak("$accessor already defined") if $self->class->can($method);
    }

    foreach my $name (keys %{ $self->{members} })
    {
      next if $name =~ /^:/;
      my $accessor = $self->class . '::' . $name;
      Carp::croak("$accessor already exists")
        if $self->class->can($name);
      my $member = $self->{members}->{$name};
      Carp::croak("Missing Perl class for $accessor")
        if $member->{nest} && !$member->{nest}->{class};
    }

    require FFI::Platypus::Memory;

    {
      my $size = $self->size;
      $size = 1 unless $size > 0;

      Sub::Install::install_sub({
        code => sub {
          my $class = shift;
          my($ptr, $owner);
          if(@_ == 1 && is_plain_arrayref $_[0])
          {
            ($ptr, $owner) = @{ shift() };
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

    {
      my $ffi = $self->ffi;

      foreach my $name (keys %{ $self->{members} })
      {
        my $offset = $self->{members}->{$name}->{offset};
        my $code;
        if($self->{members}->{$name}->{nest})
        {
          my $class = $self->{members}->{$name}->{nest}->{class};
          $code = sub {
            my $self = shift;
            my $ptr = $self->{ptr} + $offset;
            $class->new([$ptr,$self]);
          };
        }
        else
        {
          my $type = $self->{members}->{$name}->{spec} . '*';
          my $size = $self->{members}->{$name}->{size};

          my $set = $ffi->function( FFI::C::FFI::memcpy_addr() => ['opaque',$type,'size_t'] => $type)->sub_ref;
          my $get = $ffi->function( 0                          => ['opaque'] => $type)->sub_ref;

          if($self->{members}->{$name}->{rec})
          {
            $code = sub {
              my $self = shift;
              my $ptr = $self->{ptr} + $offset;
              if(@_)
              {
                my $length = do { use bytes; length $_[0] };
                my $src = \($size > $length ? $_[0] . ("\0" x ($size-$length)) : $_[0]);
                return $set->($ptr, $src, $size);
              }
              $get->($ptr)
            };
          }
          else
          {
            $code = sub {
              my $self = shift;
              my $ptr = $self->{ptr} + $offset;
              @_
                ? ${ $set->($ptr,\$_[0],$size) }
                : ${ $get->($ptr) };
            };
          }
        }

        Sub::Install::install_sub({
          code => $code,
          into => $self->class,
          as   => $name,
        });
      }
    }
  }

  $self;
}

sub _common_destroy
{
  my($self) = @_;
  if($self->{ptr} && !$self->{owner})
  {
    FFI::Platypus::Memory::free(delete $self->{ptr});
  }
}

1;
