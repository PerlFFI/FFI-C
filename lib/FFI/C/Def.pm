package FFI::C::Def;

use strict;
use warnings;
use 5.008001;

# ABSTRACT: Data definition for FFI
# VERSION

=head1 METHODS

=head2 ffi

=head2 name

=head2 size

=head2 align

=cut

sub name { shift->{name} }
sub ffi  { shift->{ffi} }
sub size { shift->{size} }
sub align { shift->{align} }

1;
