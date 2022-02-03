defmodule ExVim.State.CommandParser do
  import NimbleParsec

  no_slash_string = utf8_string([{:not, ?/}], min: 1)

  find_and_replace_block =
    no_slash_string
    |> tag(:to_find)
    |> concat(ignore(string("/")))
    |> choice([
      no_slash_string
      |> tag(:to_replace)
      |> concat(
        optional(
          string("/")
          |> ignore()
          |> optional(no_slash_string)
          |> tag(:options)
        )
      ),
      ignore(string("/"))
      |> optional(no_slash_string)
      |> tag(:options)
    ])

  find_and_replace_single =
    string("s/")
    |> ignore()
    |> concat(find_and_replace_block)
    |> tag(:find_and_replace_single)

  find_and_replace_global =
    string("%s/")
    |> ignore()
    |> concat(find_and_replace_block)
    |> tag(:find_and_replace_global)

  exit_cmd = ignore(string("q")) |> tag(:exit)

  save_cmd =
    ignore(string("w "))
    |> concat(tag(utf8_string([], min: 1), :filename))
    |> tag(:save)

  save_and_exit_cmd =
    ignore(string("wq "))
    |> concat(tag(utf8_string([], min: 1), :filename))
    |> tag(:save_and_exit)

  command =
    choice([
      exit_cmd,
      save_cmd,
      save_and_exit_cmd,
      find_and_replace_global,
      find_and_replace_single
    ])

  defparsec(:command, command)

  def parse_command(":" <> str) do
    case command(str) do
      {:ok, [{:exit, _}], _, _, _, _} ->
        {:ok, :exit}

      {:ok, [{:save, args}], _, _, _, _} ->
        {:ok, {:save, Enum.at(args[:filename], 0)}}

      {:ok, [{:save_and_exit, args}], _, _, _, _} ->
        {:ok, {:save_and_exit, Enum.at(args[:filename], 0)}}

      {:ok, [{:find_and_replace_global, args}], _, _, _, _} ->
        {to_find_regex, opts} =
          parse_find_and_replace_opts(args[:to_find], args[:options] || [""])

        {:ok,
         {:find_and_replace_global, to_find_regex, Enum.at(args[:to_replace] || [], 0, ""), opts}}

      {:ok, [{:find_and_replace_single, args}], _, _, _, _} ->
        {to_find_regex, opts} =
          parse_find_and_replace_opts(args[:to_find], args[:options] || [""])

        {:ok,
         {:find_and_replace_single, to_find_regex, Enum.at(args[:to_replace] || [], 0, ""), opts}}

      _ ->
        {:error, :invablid_command}
    end
  end

  def parse_command(_), do: {:error, :invalid_command}

  defp parse_find_and_replace_opts([to_find], [opts_str]) do
    {to_find, [global: String.contains?(opts_str, "g")]}
  end
end
