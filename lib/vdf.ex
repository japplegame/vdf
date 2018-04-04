defmodule VDF do
  defmodule Error do
    defexception [:message]
  end

  def decode(str) when is_binary(str) do
    str =
      case :unicode.bom_to_encoding(str) do
        {:latin1, 0} ->
          str

        {:utf8, bom_length} ->
          <<_::binary-size(bom_length), str::binary>> = str
          str

        {encoding, bom_length} ->
          <<_::binary-size(bom_length), str::binary>> = str
          :unicode.characters_to_binary(str, encoding)
      end

    {_, data} = skip_ws({str, 1, 1})
    decode(data, %{})
  end

  def decode({_, _, _} = data, result) do
    with {:key, key, data} <- decode_key(data),
         {:value, value, data} <- decode_value(data) do
      decode(data, Map.put(result, key, value))
    else
      {:close, {_, line, pos}} ->
        {:error, Error.exception("unexpected close bracket (#{line}:#{pos - 1})")}

      :eof ->
        {:ok, result}

      {:error, _} = error ->
        error
    end
  end

  def decode_key(data) do
    case decode_token(data) do
      {:key_value, key, data} ->
        {:key, key, data}

      {:open, {_, line, pos}} ->
        {:error, Error.exception("unexpected open bracket (#{line}:#{pos - 1})")}

      result ->
        result
    end
  end

  def decode_value(data) do
    case decode_token(data) do
      {:key_value, value, data} ->
        {:value, value, data}

      {:open, data} ->
        case decode_object(data) do
          {:value, _, _} = value -> value
          {:error, _} = error -> error
        end

      {:close, {_, line, pos}} ->
        {:error, Error.exception("unexpected close bracket (#{line}:#{pos - 1})")}

      :eof ->
        {:error, Error.exception("unexpected EOF while parsing value")}

      {:error, _} = error ->
        error
    end
  end

  def decode_object(data, result \\ %{}) do
    with {:key, key, data} <- decode_key(data),
         {:value, value, data} <- decode_value(data) do
      decode_object(data, Map.put(result, key, value))
    else
      {:close, data} ->
        {:value, result, data}

      :eof ->
        {:error, Error.exception("unexpected EOF while parsing object")}

      {:error, _} = error ->
        error
    end
  end

  def decode_token({str, line, pos} = data) do
    case str do
      "\"" <> str ->
        decode_quoted_token({str, line, pos + 1}, "")

      "{" <> str ->
        {_, data} = skip_ws({str, line, pos + 1})
        {:open, data}

      "}" <> str ->
        {_, data} = skip_ws({str, line, pos + 1})
        {:close, data}

      "#" <> _ ->
        {:error, Error.exception("macro is not supported (#{line}:#{pos - 1})")}

      _ ->
        decode_token(data, "")
    end
  end

  def decode_token({str, line, pos} = data, token) do
    case str do
      "\"" <> _ ->
        {:key_value, token, data}

      "{" <> _ ->
        {:key_value, token, data}

      "}" <> _ ->
        {:key_value, token, data}

      <<c::utf8, str::binary>> ->
        case skip_ws(data) do
          {true, data} ->
            {:key_value, token, data}

          {false, _} ->
            decode_token({str, line, pos + 1}, <<token::binary, c::utf8>>)
        end

      _ ->
        case token do
          <<>> -> :eof
          token -> {:key_value, token, data}
        end
    end
  end

  def decode_quoted_token({str, line, pos} = data, token) do
    case str do
      "\"" <> str ->
        {_, data} = skip_ws({str, line, pos + 1})
        {:key_value, token, data}

      "\\t" <> str ->
        decode_quoted_token({str, line, pos + 1}, <<token::binary, "\t">>)

      "\\n" <> str ->
        decode_quoted_token({str, line, pos + 1}, <<token::binary, "\n">>)

      "\\r" <> str ->
        decode_quoted_token({str, line, pos + 1}, <<token::binary, "\r">>)

      "\\\"" <> str ->
        decode_quoted_token({str, line, pos + 1}, <<token::binary, "\"">>)

      "\\\\" <> str ->
        decode_quoted_token({str, line, pos + 1}, <<token::binary, "\\">>)

      <<c::utf8, str::binary>> ->
        decode_quoted_token({str, line, pos + 1}, <<token::binary, c::utf8>>)

      _ ->
        {:error, Error.exception("unexpected EOF while parsing quoted token")}
    end
  end

  defp skip_ws({str, line, pos} = data, ws_found \\ false) do
    case str do
      "\n\r" <> str -> skip_ws({str, line + 1, 1}, true)
      "\n" <> str -> skip_ws({str, line + 1, 1}, true)
      "\r" <> str -> skip_ws({str, line + 1, 1}, true)
      "\t" <> str -> skip_ws({str, line, pos + 1}, true)
      " " <> str -> skip_ws({str, line, pos + 1}, true)
      "//" <> str -> skip_comment({str, line, pos + 2})
      _ -> {ws_found, data}
    end
  end

  defp skip_comment({str, line, pos} = data) do
    case str do
      "\r" <> _ -> skip_ws(data)
      "\n" <> _ -> skip_ws(data)
      <<_::utf8, str::binary>> -> skip_comment({str, line, pos + 1})
      _ -> {true, data}
    end
  end
end
