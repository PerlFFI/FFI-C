package FFI::C::UnionDef;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus 1.11;
use constant _is_union => 1;
use base qw( FFI::C::StructDef );

# ABSTRACT: Union data types for FFI
# VERSION

package FFI::C::Union;

use base qw( FFI::C::Struct );

1;
