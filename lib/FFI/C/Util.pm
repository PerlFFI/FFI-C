package FFI::C::Util;

use strict;
use warnings;
use 5.008001;
use Ref::Util qw( is_blessed_ref );
use Carp ();
use base qw( Exporter );

our @EXPORT_OK = qw( init take owned );

# ABSTRACT: Utility functions for dealing with structured C data
# VERSION

=head1 SYNOPSIS

#EXAMPLE: examples/synopsis/util.pl

=head1 DESCRIPTION

This module provides some useful utility functions for dealing with
the various def instances provided by L<FFI::C>

=head1 FUNCTIONS

=head2 init

=cut

sub init
{
}

=head2 owned

 my $bool = owned $instance;

Returns true of the C<$instance> owns its allocated memory.  That is,
it will free up the allocated memory when it falls out of scope.
Reasons an instance might not be owned are:

=over 4

=item the instance is nested inside another object that owns the memory

=item the instance was returned from a C function that owns the memory

=item ownership was taken away by the C<take> function below.

=back

=cut

sub owned
{
  my $object = shift;
  !!($object->{ptr} && !$object->{owner});
}

=head2 take

 my $ptr = take $instance;

This function takes ownership of the instance pointer, and returns
the opaque pointer.  This means a couple of things:

=over 4

=item C<$instance> will not free its data automatically

You should call C<free> on it manually to free the memory it is using.

=item C<$instance> cannot be used anymore

So don't try to get/set any of its members, or pass it into a function.

=back

The returned pointer can be cast into something else or passed into
a function that takes an C<opaque> argument.

=cut

sub take ($)
{
  my $object = shift;
  Carp::croak("Not an object") unless is_blessed_ref $object;
  Carp::croak("Object is owned by someone else") if $object->{owner};
  my $ptr = delete $object->{ptr};
  Carp::croak("Object pointer went away") unless $ptr;
  $ptr;
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
