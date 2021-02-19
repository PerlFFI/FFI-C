use Test2::V0 -no_srand => 1;
use FFI::C::String;

subtest 'basic round trip ASCII' => sub {

  foreach my $type (qw( ASCII Wide UTF8 ))
  {
    subtest "$type" => sub {

      skip_all 'TODO' if $type eq 'Wide';

      my $cstr = FFI::C::String->new(["Frooble", undef, $type]);
      isa_ok $cstr, 'FFI::C::String';
      isa_ok $cstr, "FFI::C::${type}String";
      is $cstr->to_string, 'Frooble';
    };
  }

};

done_testing;
