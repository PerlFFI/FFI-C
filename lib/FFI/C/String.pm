package FFI::C::String;

use strict;
use warnings;
use base qw( FFI::C::Buffer );
use Carp ();

# ABSTRACT: Base class for C string classes
# VERSION

=head1 SYNOPSIS

# EXAMPLE: examples/synopsis/ascii_string.pl

=head1 DESCRIPTION

This is a base class for classes that represent NULL terminated C strings.
The encoding is defined by the subclass.  This class can't be initialized
by itself.

This class is itself a subclass of L<FFI::C::Buffer>, so you can use all
of the methods that class provides.  In particular it is worth remembering
that the buffer size of the C string object can be larger than the string
contained within.

Subclasses include:

=over 4

=item L<FFI::C::ASCIIString>

=back

=cut

1;

=head1 SEE ALSO

=over 4

=item L<FFI::C>

=item L<FFI::C::Array>

=item L<FFI::C::ArrayDef>

=item L<FFI::C::ASCIIString>

=item L<FFI::C::Buffer>

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
