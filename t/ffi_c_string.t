use utf8;
use Test2::V0 -no_srand => 1;
use FFI::C::String;
use Encode qw( encode find_encoding );

subtest 'ctor errors' => sub {

  is dies { FFI::C::String->new }, match qr/No encoding provided for this class \/ object/;
  is dies { FFI::C::String->new({ buffer_size => 1024 }) }, match qr/encoding_name is required/;
  is dies { FFI::C::String->new({ encoding_name => 'invalid', buffer_size => 1024 }) }, match qr/Unknown encoding: invalid/;
  is dies { FFI::C::String->new({ encoding_name => 'ascii' }) }, match qr/buffer_size or string are required/;
  
};

subtest 'with encoding ascii' => sub {

  is(
    FFI::C::String->new({
      encoding_name => 'ascii',
      buffer_size   => 1024,
      string => 'foobar',
    }),
    object {
      call [ isa => 'FFI::C::String' ] => T();
      call [ isa => 'FFI::C::Buffer' ] => T();

      call encoding_name  => 'ascii';
      call encoding_width => U();
      call buffer_size    => 1024;
      call to_perl        => 'foobar';
    },
  );

  is(
    FFI::C::String->new({
      encoding_name => 'ascii',
      string        => "foobar\0xx\nroger\0",
      buffer_size   => 1024,
    }),
    object {
      call to_perl => 'foobar';
    },
  );
    

};

subtest 'with encoding koi8-r' => sub {

  skip_all 'test requires koi8-r encoding'
    unless find_encoding('koi8-r');

  my $str;
  is(
    $str = FFI::C::String->new({
      encoding_name  => 'kOI8-r',
      encoding_width => 1,
      buffer_size    => 512,
      strings        => 'Привет, мир',
    }),
    object {
      call [ isa => 'FFI::C::String' ] => T();
      call [ isa => 'FFI::C::Buffer' ] => T();

      call encoding_name  => 'koi8-r';
      call encoding_width => 1;
      call buffer_size    => 512;
      call to_perl        => 'Привет, мир';
    },
  );

  my $win;
  $str->window($win);
  my $raw = "$win";
  $raw =~ s/\0.*$//;

  is($raw, encode('koi8-r', $raw));

};

done_testing;
