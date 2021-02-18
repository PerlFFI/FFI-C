package FFI::C::Union;

use strict;
use warnings;
use base qw( FFI::C::Struct );

# ABSTRACT: Union data instance for FFI
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/union.pl

=head1 DESCRIPTION

This class represents an instance of a C C<union>.  This class can be created using
C<new> on the generated class, if that was specified for the L<FFI::C::UnionDef>,
or by using the C<create> method on L<FFI::C::UnionDef>.

For each member defined in the L<FFI::C::UnionDef> there is an accessor for the
L<FFI::C::Union> instance.

=head1 CONSTRUCTOR

=head2 new

 FFI::C::UnionDef->new( class => 'User::Union::Class', ... );
 my $instance = User::Union::Class->new;

Creates a new instance of the C<union>.

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::Def>

=item L<FFI::C::File>

=item L<FFI::C::PosixFile>

=item L<FFI::C::String>

=item L<FFI::C::Struct>

=item L<FFI::C::StructDef>

=item L<FFI::C::Union>

=item L<FFI::C::UnionDef>

=item L<FFI::C::Util>

=item L<FFI::Platypus::Record>

=back

=cut

1;
