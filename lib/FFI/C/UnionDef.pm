package FFI::C::UnionDef;

use strict;
use warnings;
use 5.008001;
use FFI::C::Union;
use FFI::Platypus 1.24;
use constant _is_union => 1;
use base qw( FFI::C::StructDef );

# ABSTRACT: Union data definition for FFI
# VERSION

=head1 SYNOPSIS

In your C code:

# EXAMPLE: examples/synopsis/uniondef.c

In your Perl code:

# EXAMPLE: examples/synopsis/uniondef.pl

=head1 DESCRIPTION

This class creates a def for a C C<union>.

=head1 CONSTRUCTOR

=head2 new

 my $def = FFI::C::UnionDef->new(%opts);
 my $def = FFI::C::UnionDef->new($ffi, %opts);

For standard def options, see L<FFI::C::Def>.

=over 4

=item members

This should be an array reference containing name, type pairs.
For a union, the order doesn't matter.

=back

=head1 METHODS

=head2 create

 my $instance = $def->create;
 my $instance = $def->class->new;          # if class was specified
 my $instance = $def->create(\%init);
 my $instance = $def->class->new(\%init);  # if class was specified

This creates an instance of the C<union>, returns a L<FFI::C::Union>.

You can optionally initialize member values using C<%init>.

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

1;
