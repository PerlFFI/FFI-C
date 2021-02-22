use Test2::V0 -no_srand => 1;
use FFI::C::Util qw( take );
use FFI::C::Buffer;

subtest 'very basic' => sub {

  my $buf = FFI::C::Buffer->new(100);
  isa_ok $buf, 'FFI::C::Buffer';
  is $buf->buffer_size, 100;

  undef $buf;

  ok 1;

};

subtest 'take and reconstitute' => sub {

  my $buf1 = FFI::C::Buffer->new(100);
  isa_ok $buf1, 'FFI::C::Buffer';

  my $ptr = take $buf1;
  like $ptr, qr/^[0-9]+$/;

  my $buf2 = FFI::C::Buffer->new($ptr, undef);
  isa_ok $buf2, 'FFI::C::Buffer';
  is $buf2->buffer_size, U();

  $buf2->buffer_size(50);
  is $buf2->buffer_size, 50;

};

done_testing;
