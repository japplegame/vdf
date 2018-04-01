# Valve KeyValues Text File Format (.vdf) decoder
Pure Elixir [Valve KeyValues Text File Format](https://developer.valvesoftware.com/wiki/KeyValues_class) decoder.
## Using
```elixir
VDF.decode(~s/a b c {"d" {"e" "f"}}/)
# {:ok, %{"a" => "b", "c" => %{"d" => %{"e" => "f"}}}}
```
```elixir
VDF.decode("a b \n{c d}")
# {:error, %VDF.Error{message: "unexpected open bracket (2:1)"}}
```
