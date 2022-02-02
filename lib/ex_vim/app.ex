defmodule ExVim.App do
  @behaviour Ratatouille.App

  import Ratatouille.View

  alias ExVim.Buffer

  def init(_context), do: %Buffer{}

  @key_up Ratatouille.Constants.key(:arrow_up)
  @key_down Ratatouille.Constants.key(:arrow_down)
  @key_left Ratatouille.Constants.key(:arrow_left)
  @key_right Ratatouille.Constants.key(:arrow_right)
  @enter Ratatouille.Constants.key(:enter)

  @backspace Ratatouille.Constants.key(:backspace)
  @backspace2 Ratatouille.Constants.key(:backspace2)
  @delete Ratatouille.Constants.key(:delete)

  def update(buffer, msg) do
    case msg do
      {:event, %{key: key}} when key in [@backspace, @backspace2] ->
        Buffer.backspace(buffer, buffer.row, buffer.col)

      {:event, %{key: @delete}} ->
        Buffer.delete(buffer, buffer.row, buffer.col)

      {:event, %{key: @key_up}} ->
        Buffer.direction(buffer, :up)

      {:event, %{key: @key_down}} ->
        Buffer.direction(buffer, :down)

      {:event, %{key: @key_left}} ->
        Buffer.direction(buffer, :left)

      {:event, %{key: @key_right}} ->
        Buffer.direction(buffer, :right)

      {:event, %{key: @enter}} ->
        Buffer.newline(buffer, buffer.row)

      {:event, %{ch: char}} ->
        Buffer.add_substring(buffer, buffer.row, buffer.col, <<char::utf8>>)

      _ ->
        buffer
    end
  end

  def render(buffer) do
    {before_cursor, at_cursor, after_cursor} = Buffer.content(buffer)

    cursor = if(rem(System.system_time(:millisecond), 1000) > 500, do: "|", else: " ")

    view do
      panel title: Buffer.title(buffer) do
        label(
          content:
            before_cursor <>
              cursor <>
              at_cursor <>
              after_cursor
        )
      end
    end
  end
end
