package FFI::C::ArrayDef;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref is_plain_arrayref is_ref );
use FFI::C::Array;
use Sub::Install ();
use base qw( FFI::C::Def );

# ABSTRACT: Array data definition for FFI
# VERSION

=head1 SYNOPSIS

In your C code:

# EXAMPLE: examples/synopsis/arraydef.c

In your Perl code:

# EXAMPLE: examples/synopsis/arraydef.pl

=head1 DESCRIPTION

This class creates a def for a C array of structured data.  Usually the def
contains a L<FFI::C::StructDef> or L<FFI::C::UnionDef> and optionally a number
of elements.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::ArrayDef->new(%opts);
 my $def = FFI::C::ArrayDef->new($ffi, %opts);

For standard def options, see L<FFI::C::Def>.

=over 4

=item members

This should be an array reference the member type, and
optionally the number of elements.  Examples:

 my $struct = FFI::C::StructDef->new(...);
 
 my $fixed = FFI::C::ArrayDef->new(
   members => [ $struct, 10 ],
 );
 
 my $var = FFI::C::ArrayDef->new(
   members => [ $struct ],
 );

=back

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

  if(my $def = $self->ffi->_def('FFI::C::Def', $member))
  {
    $member = $def;
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

  if($self->class)
  {
    # not handled by the superclass:
    #  3. Any nested cdefs must have Perl classes.

    {
      my $member = $self->{members}->{member};
      my $accessor = $self->class . '::get';
      Carp::croak("Missing Perl class for $accessor")
        if $member->{nest} && !$member->{nest}->{class};
    }

    $self->_generate_class(qw( get ));

    {
      my $member_class = $self->{members}->{member}->class;
      my $member_size  = $self->{members}->{member}->size;
      Sub::Install::install_sub({
        code => sub {
          my($self, $index) = @_;
          Carp::croak("Negative array index") if $index < 0;
          Carp::croak("OOB array index") if $self->{count} && $index >= $self->{count};
          my $ptr = $self->{ptr} + $member_size * $index;
          $member_class->new([$ptr,$self]);
        },
        into => $self->class,
        as   => 'get',
      });
    }

    {
      no strict 'refs';
      push @{ join '::', $self->class, 'ISA' }, 'FFI::C::Array';
    }

  }

  $self;
}

=head1 METHODS

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;          # if class was specified
 my $instance = $def->create($count);
 my $instance = $def->class->new($count);  # if class was specified

This creates an instance of the array.  If C<$count> is given, this
is used for the element count, possibly overriding what was specified
when the def was created.  If the def doesn't have an element count
specified, then you MUST provide it here.  Returns a L<FFI::C::Array>.

=cut

sub create
{
  my($self) = @_;

  return $self->class->new(@_) if $self->class;

  local $self->{size} = $self->{size};
  my $count = $self->{members}->{count};
  if(@_ == 1 && ! is_ref $_[0])
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

=item L<FFI::Platypus::Record>

=back

=cut
