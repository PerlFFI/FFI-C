package FFI::C::StructDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::Util;
use FFI::C::Struct;
use FFI::C::FFI ();
use FFI::Platypus 1.21;
use Ref::Util qw( is_blessed_ref is_plain_arrayref is_ref );
use Carp ();
use Sub::Install ();
use Sub::Util ();
use constant _is_union => 0;
use base qw( FFI::C::Def );

our @CARP_NOT = qw( FFI::C::Util );

# ABSTRACT: Structured data definition for FFI
# VERSION

=head1 SYNOPSIS

In your C code:

# EXAMPLE: examples/synopsis/structdef.c

In your Perl code:

# EXAMPLE: examples/synopsis/structdef.pl

=head1 DESCRIPTION

This class creates a def for a C C<struct>.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::StructDef->new(%opts);
 my $def = FFI::C::StructDef->new($ffi, %opts);

For standard def options, see L<FFI::C::Def>.

=over 4

=item members

This should be an array reference containing name, type pairs,
in the order that they will be stored in the struct.

=back

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
      elsif($name !~ /^[A-Za-z_][A-Za-z_0-9]*$/)
      {
        Carp::croak("Illegal member name");
      }
      elsif($name eq 'new')
      {
        Carp::croak("new now allowed as a member name");
      }

      if(my $def = $self->ffi->_def('FFI::C::Def', $spec))
      {
        $spec = $def;
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
      elsif($self->_is_kind($spec, 'array'))
      {
        $member{spec}     = $self->ffi->_unitof($spec);
        $member{count}    = $self->ffi->_countof($spec);
        $member{size}     = $self->ffi->sizeof($spec);
        $member{unitsize} = $self->ffi->sizeof($member{spec});
        $member{align}    = $self->ffi->alignof($spec);
        Carp::croak("array members must have at least one element")
          unless $member{count} > 0;
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
    # not handled by the superclass:
    #  3. Any nested cdefs must have Perl classes.

    foreach my $name (keys %{ $self->{members} })
    {
      next if $name =~ /^:/;
      my $member = $self->{members}->{$name};
      my $accessor = $self->class . '::' . $name;
      Carp::croak("Missing Perl class for $accessor")
        if $member->{nest} && !$member->{nest}->{class};
    }

    $self->_generate_class(keys %{ $self->{members} });

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
            my $m = $class->new($ptr,$self);
            FFI::C::Util::init($m, $_[0]) if @_;
            $m;
          };
        }
        else
        {
          my $type  = $self->{members}->{$name}->{spec} . '*';
          my $size  = $self->{members}->{$name}->{size};

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
          elsif(my $count = $self->{members}->{$name}->{count})
          {
            my $unitsize = $self->{members}->{$name}->{unitsize};
            my $atype    = $self->{members}->{$name}->{spec} . "[$count]";
            my $all = $ffi->function( FFI::C::FFI::memcpy_addr() => ['opaque',$atype,'size_t'] => 'void' );
            $code = sub {
              my $self = shift;
              if(defined $_[0])
              {
                if(is_plain_arrayref $_[0])
                {
                  my $array = shift;
                  Carp::croak("$name OOB index on array member") if @$array > $count;
                  my $ptr = $self->{ptr} + $offset;
                  my $size = (@$array ) * $unitsize;
                  $all->($ptr, $array, (@$array * $unitsize));
                  # we don't want to have to get the array and tie it if
                  # it isn't going to be used anyway.
                  return unless defined wantarray;  ## no critic (Freenode::Wantarray)
                }
                elsif(! is_ref $_[0])
                {
                  my $index = shift;
                  Carp::croak("$name Negative index on array member") if $index < 0;
                  Carp::croak("$name OOB index on array member") if $index >= $count;
                  my $ptr = $self->{ptr} + $offset + $index * $unitsize;
                  return @_
                    ? ${ $set->($ptr,\$_[0],$unitsize) }
                    : ${ $get->($ptr) };
                }
                else
                {
                  Carp::croak("$name tried to set element to non-scalar");
                }
              }
              my @a;
              tie @a, 'FFI::C::Struct::MemberArrayTie', $self, $name, $count;
              return \@a;
            };
          }
          else
          {
            $code = sub {
              my $self = shift;
              my $ptr = $self->{ptr} + $offset;
              Carp::croak("$name tried to set member to non-scalar") if @_ && is_ref $_[0];
              @_
                ? ${ $set->($ptr,\$_[0],$size) }
                : ${ $get->($ptr) };
            };
          }
        }

        Sub::Util::set_subname(join('::', $self->class, $name), $code);
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

1;

=head1 METHODS

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;          # if class was specified
 my $instance = $def->create(\%init);
 my $instance = $def->class->new(\%init);  # if class was specified

This creates an instance of the C<struct>, returns a L<FFI::C::Struct>.

You can optionally initialize member values using C<%init>.

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
