use Test2::V0 -no_srand => 1;
use FFI::C::ASCIIString;

subtest 'very basic' => sub {

  my $str = FFI::C::ASCIIString->new(\"foobar");

  is(
    $str,
    object {
      call [ isa => 'FFI::C::Buffer'      ] => T();
      call [ isa => 'FFI::C::String'      ] => T();
      call [ isa => 'FFI::C::ASCIIString' ] => T();

      call to_perl => 'foobar';
      call buffer_size => 7;
      call strlen => 6;
    },
  );

  my $win;
  $str->window($win);

  is $win, "foobar\0";

  $str->from_perl('baz');

  is $win, "baz\0ar\0";

  $str->strcat("xx");

  is $win, "bazxx\0\0";

};

done_testing;
