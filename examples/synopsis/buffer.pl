use strict;
use warnings;
use FFI::Platypus;
use FFI::C::Buffer;

my $ffi = FFI::Platypus->new( api => 1, lib => [undef]);
my $open  = $ffi->function( 'open'  => [ 'string', 'int', 'mode_t' ] => 'int' );
my $read  = $ffi->function( 'read'  => [ 'int','opaque','size_t'   ] => 'ssize_t' );
my $write = $ffi->function( 'write' => [ 'int','opaque','size_t'   ] => 'ssize_t' );

my $buf1 = FFI::C::Buffer->new(\"Hello World!\n");

# send a buffer to C land as a const char * for it to read from
$write->call(1, $buf1->ptr, $buf1->buffer_size);

# open this script for read
my $fd = $open->call(__FILE__, 0, 0);  # O_RDONLY

# allocate an uninitzlized buffer of 1024 bytes.
# we can reuse this over and over to avoid having
# to reallocate the memory.
my $buf2 = FFI::C::Buffer->new(1024);

while(1)
{
  # send a buffer to C land as a const char * fro it to write to
  my $count = $read->call($fd, $buf2->ptr, $buf2->buffer_size);

  die "error reading into buffer" if $count < 0;

  last if $count == 0;

  $write->call(1, $buf2->ptr, $count);
}
