package FFI::Union;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus 1.11;
use constant _is_union => 1;
use base qw( FFI::Struct );

# ABSTRACT: Union data types for FFI
# VERSION

package FFI::Union::Instance;

use base qw( FFI::Struct::Instance );

1;
