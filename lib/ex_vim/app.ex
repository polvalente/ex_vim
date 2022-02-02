defmodule ExVim.App do
  @behaviour Ratatouille.App

  import Ratatouille.View

  alias ExVim.Buffer

  def init(_context), do: %Buffer{content: ~w(a123 s4 d789 f245667)}

  @key_up Ratatouille.Constants.key(:arrow_up)
  @key_down Ratatouille.Constants.key(:arrow_down)
  @key_left Ratatouille.Constants.key(:arrow_left)
  @key_right Ratatouille.Constants.key(:arrow_right)
  @enter Ratatouille.Constants.key(:enter)

  def update(buffer, msg) do
    case msg do
      {:event, %{key: @key_up}} -> Buffer.direction(buffer, :up)
      {:event, %{key: @key_down}} -> Buffer.direction(buffer, :down)
      {:event, %{key: @key_left}} -> Buffer.direction(buffer, :left)
      {:event, %{key: @key_right}} -> Buffer.direction(buffer, :right)
      {:event, %{key: @enter}} -> Buffer.newline(buffer, buffer.row)
      _ -> buffer
    end
  end

  def render(buffer) do
    {before_cursor, at_cursor, after_cursor} = Buffer.content(buffer)

    view do
      panel title: Buffer.title(buffer) do
        label(
          content:
            before_cursor <>
              "|" <>
              at_cursor <>
              after_cursor
        )

        # label do
        #   text(content: "a123\ns4\nd")

        #   text(
        #
        #       do: [content: "7", attributes: [:underline]],
        #       else: [content: "7"]
        #     )
        #   )

        #   text(content: "89\nf245667")
        # end
      end
    end
  end
end
