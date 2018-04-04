defmodule VDFTest do
  use ExUnit.Case

  test "pair" do
    assert VDF.decode("\r\nhello \t\n\rworld\t") == {:ok, %{"hello" => "world"}}
    assert VDF.decode(~s/\r\n" hello " \t\n\r" world "\t/) == {:ok, %{" hello " => " world "}}
    assert VDF.decode("hello world") == {:ok, %{"hello" => "world"}}
    assert VDF.decode(~S/"he\tllo\\" "w\\or\n\rld"/) == {:ok, %{"he\tllo\\" => "w\\or\n\rld"}}
  end

  test "list" do
    assert VDF.decode("a b c d") == {:ok, %{"a" => "b", "c" => "d"}}
    assert VDF.decode(~S/a"b"c"d"/) == {:ok, %{"a" => "b", "c" => "d"}}
    assert VDF.decode(~S/"a"b"c"d/) == {:ok, %{"a" => "b", "c" => "d"}}
  end

  test "object" do
    assert VDF.decode(~s/a {b c d e} b\n{ "c " d e "f" \n}/) ==
             {:ok, %{"a" => %{"b" => "c", "d" => "e"}, "b" => %{"c " => "d", "e" => "f"}}}

    assert VDF.decode("a {b {c d} d e} b c") ==
             {:ok, %{"a" => %{"b" => %{"c" => "d"}, "d" => "e"}, "b" => "c"}}
  end

  test "unicode" do
    utf16_le_str =
      :unicode.encoding_to_bom({:utf16, :little}) <>
        :unicode.characters_to_binary(
          "привет {hello {a b} world {c d}}",
          :utf8,
          {:utf16, :little}
        )

    assert VDF.decode(utf16_le_str) ==
             {:ok, %{"привет" => %{"hello" => %{"a" => "b"}, "world" => %{"c" => "d"}}}}
  end
end
