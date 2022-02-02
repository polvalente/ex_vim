defmodule ExVim.App do
  @behaviour Ratatouille.App

  import Ratatouille.View

  alias ExVim.Buffer

  def init(_context), do: %Buffer{content: ~w(a123 s4 d789 f245667)}

  @key_up Ratatouille.Constants.key(:arrow_up)
  @key_down Ratatouille.Constants.key(:arrow_down)
  @key_left Ratatouille.Constants.key(:arrow_left)
  @key_right Ratatouille.Constants.key(:arrow_right)

  def update(buffer, msg) do
    case msg do
      {:event, %{key: @key_up}} -> Buffer.direction(buffer, :up)
      {:event, %{key: @key_down}} -> Buffer.direction(buffer, :down)
      {:event, %{key: @key_left}} -> Buffer.direction(buffer, :left)
      {:event, %{key: @key_right}} -> Buffer.direction(buffer, :right)
      _ -> buffer
    end
  end

  def render(buffer) do
    view do
      label(content: "(row, col): (#{buffer.row}, #{buffer.col})")
    end
  end
end
