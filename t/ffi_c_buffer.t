use Test2::V0 -no_srand => 1;
use FFI::C::Util qw( take owned );
use FFI::C::Buffer;

subtest 'very basic' => sub {

  my $buf = FFI::C::Buffer->new(100);

  is(
    $buf,
    object {
      call [ isa => 'FFI::C::Buffer' ] => T();
      call ptr                         => match qr/^[0-9]+$/;
      call buffer_size                 => 100;
    },
  );

  is owned $buf, T();

  undef $buf;

  # appears to free without crashing!
  ok 1;

};

subtest 'take and reconstitute' => sub {

  my $buf1 = FFI::C::Buffer->new(100);
  isa_ok $buf1, 'FFI::C::Buffer';
  is owned $buf1, T();

  my $ptr = take $buf1;
  like $ptr, qr/^[0-9]+$/;

  my $buf2 = FFI::C::Buffer->new($ptr, \{});
  isa_ok $buf2, 'FFI::C::Buffer';
  is $buf2->buffer_size, U();
  is owned $buf2, F();

  my $buf3 = FFI::C::Buffer->new($ptr, undef);
  isa_ok $buf3, 'FFI::C::Buffer';
  is $buf3->buffer_size, U();
  is owned $buf3, T();

  $buf3->buffer_size(50);
  is $buf3->buffer_size, 50;

};

done_testing;
