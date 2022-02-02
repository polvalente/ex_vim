defmodule ExVim.Buffer do
  defstruct name: nil, row: 0, col: 0, content: [""]

  @doc """
  Adds a character to the given `buffer` at index (`row`, `col`)

  ### Examples

      iex>  (
      ...>    %ExVim.Buffer{}
      ...>    |> ExVim.Buffer.add_substring(0, 0, "a")
      ...>    |> ExVim.Buffer.add_substring(0, 1, "s")
      ...>    |> ExVim.Buffer.add_substring(0, 1, "dfgh")
      ...>  )
      %ExVim.Buffer{col: 5, content: ["adfghs"], name: nil, row: 0}
  """
  def add_substring(buffer, row, col, substring) do
    # TO-DO: deal with newline adding new row
    buffer
    |> update_in([Access.key(:content), Access.at(row)], fn
      <<prefix::binary-size(col), suffix::binary>> ->
        prefix <> substring <> suffix
    end)
    |> put_in([Access.key(:col)], col + String.length(substring))
  end

  @doc """
  Adds a new line at row `row`

  ### Examples

      iex> ExVim.Buffer.newline(%ExVim.Buffer{content: ["asdf", "ghjk", "1234"]}, 2)
      %ExVim.Buffer{content: ["asdf", "ghjk", "", "1234"], row: 3}
  """
  def newline(buffer, row) do
    buffer
    |> update_in([Access.key(:content)], fn content ->
      List.insert_at(content, row, "")
    end)
    |> put_in([Access.key(:row)], row + 1)
  end

  @doc """
  Erases the character at the cursor

  ### Examples

      iex> ExVim.Buffer.backspace(%ExVim.Buffer{content: ["asdf", "ghjk", "1234"]}, 0, 2)
      %ExVim.Buffer{content: ["asf", "ghjk", "1234"], col: 2}

      iex> ExVim.Buffer.backspace(%ExVim.Buffer{content: ["asf", "ghjk", "1234"]}, 0, 2)
      %ExVim.Buffer{content: ["as", "ghjk", "1234"], col: 1}

      iex> ExVim.Buffer.backspace(%ExVim.Buffer{content: ["as", "ghjk", "1234"]}, 0, 1)
      %ExVim.Buffer{content: ["a", "ghjk", "1234"], col: 0}

      iex> ExVim.Buffer.backspace(%ExVim.Buffer{content: ["a", "ghjk", "1234"]}, 0, 0)
      %ExVim.Buffer{content: ["", "ghjk", "1234"], col: 0}

      iex> ExVim.Buffer.backspace(%ExVim.Buffer{content: ["", "ghjk", "1234"]}, 0, 0)
      %ExVim.Buffer{content: ["", "ghjk", "1234"], col: 0}
  """
  def backspace(buffer, row, col) do
    buffer
    |> update_in([Access.key(:content), Access.at(row)], fn
      "" ->
        ""

      <<prefix::binary-size(col), _::binary-size(1), suffix::binary>> ->
        prefix <> suffix
    end)
    |> then(fn buffer ->
      max_col = max_col(buffer.content, row)

      put_in(buffer, [Access.key(:col)], max(min(col, max_col), 0))
    end)
  end

  def direction(buffer, :up) do
    buffer
    |> Map.update(:row, 0, &(&1 - 1))
    |> cursor_bounding_box()
  end

  def direction(buffer, :down) do
    buffer
    |> Map.update(:row, 0, &(&1 + 1))
    |> cursor_bounding_box()
  end

  def direction(buffer, :left) do
    buffer
    |> Map.update(:col, 0, &(&1 - 1))
    |> cursor_bounding_box()
  end

  def direction(buffer, :right) do
    buffer
    |> Map.update(:col, 0, &(&1 + 1))
    |> cursor_bounding_box()
  end

  defp cursor_bounding_box(buffer) do
    max_row = max(length(buffer.content) - 1, 0)

    buffer
    |> Map.put(:row, min(max(0, buffer.row), max_row))
    |> then(fn buffer ->
      max_col = max_col(buffer, buffer.row)
      %{buffer | col: min(max(0, buffer.col), max_col)}
    end)
  end

  defp max_col(buffer, row) do
    buffer.content
    |> Enum.at(row)
    |> String.length()
    |> then(&(&1 - 1))
  end
end
