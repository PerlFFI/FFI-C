use Test2::V0 -no_srand => 1;
use FFI::C;

my $ffi = FFI::C->ffi;

{ package MyEnum1;
  FFI::C->enum(['foo','bar',[baz=>12]]);
  package MyStruct1;
  FFI::C->struct([foo => 'my_enum1_t']);
}

is(MyEnum1::FOO(), 0);
is(MyEnum1::BAR(), 1);
is(MyEnum1::BAZ(), 12);

{
  my $m = MyStruct1->new;
  is($m->foo, 'foo');
  is($ffi->cast('my_struct1_t' => 'enum*', $m), \0);

  is($m->foo('bar'), 'bar');
  is($m->foo, 'bar');
  is($ffi->cast('my_struct1_t' => 'enum*', $m), \1);

  is($m->foo(12), 'baz');
  is($m->foo, 'baz');
  is($ffi->cast('my_struct1_t' => 'enum*', $m), \12);
}

{ package MyEnum2;
  FFI::C->enum(['foo','bar',[baz=>12]], { rev => 'int' });
  package MyStruct2;
  FFI::C->struct([foo => 'my_enum2_t']);
}

is(MyEnum2::FOO(), 0);
is(MyEnum2::BAR(), 1);
is(MyEnum2::BAZ(), 12);

{
  my $m = MyStruct2->new;
  is($m->foo, 0);
  is($ffi->cast('my_struct2_t' => 'enum*', $m), \0);

  is($m->foo('bar'), 1);
  is($m->foo, 1);
  is($ffi->cast('my_struct2_t' => 'enum*', $m), \1);

  is($m->foo(12), 12);
  is($m->foo, 12);
  is($ffi->cast('my_struct2_t' => 'enum*', $m), \12);
}

done_testing;
