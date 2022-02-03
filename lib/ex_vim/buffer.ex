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
      List.insert_at(content, row + 1, "")
    end)
    |> put_in([Access.key(:row)], row + 1)
    |> put_in([Access.key(:col)], 0)
  end

  def delete_row(buffer, row) do
    %{buffer | content: List.delete_at(buffer.content, row), row: if(row == 1, do: 0, else: row)}
  end

  def find_and_replace_single(buffer, to_find, to_replace, opts) do
    find_and_replace(buffer, to_find, to_replace, opts, buffer.row)
  end

  def find_and_replace_global(buffer, to_find, to_replace, opts) do
    for row <- 0..max(length(buffer.content) - 1, 0), reduce: buffer do
      buffer -> find_and_replace(buffer, to_find, to_replace, opts, row)
    end
  end

  defp find_and_replace(buffer, to_find, to_replace, opts, row) do
    update_in(
      buffer,
      [Access.key(:content), Access.at(row)],
      &String.replace(&1, to_find, to_replace, opts)
    )
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

      line ->
        line
        |> String.codepoints()
        |> List.delete_at(col - 1)
        |> Enum.join()
    end)
    |> Map.update(:col, 0, &(&1 - 1))
    |> cursor_bounding_box()
  end

  def delete(buffer, row, col) do
    buffer
    |> update_in([Access.key(:content), Access.at(row)], fn
      "" ->
        ""

      line ->
        line
        |> String.codepoints()
        |> List.delete_at(col)
        |> Enum.join()
    end)
    |> cursor_bounding_box()
  end

  ### Navigation

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
      max_col = max_col(buffer, buffer.row) + 1
      %{buffer | col: min(max(0, buffer.col), max_col)}
    end)
  end

  defp max_col(buffer, row) do
    buffer.content
    |> Enum.at(row)
    |> String.length()
    |> then(&(&1 - 1))
  end

  ### Rendering

  def title(buffer) do
    name = buffer.name || "[No Name]"

    name <> " - (#{buffer.row}, #{buffer.col})"
  end

  def content(buffer) do
    {before, at} = Enum.split(buffer.content, buffer.row)
    {at_cursor, after_cursor} = Enum.split(at, 1)

    {prefix, infix} = String.split_at(Enum.at(at_cursor, 0) || "", buffer.col)
    {at_cursor, suffix} = String.split_at(infix, 1)

    before_cursor =
      if before == [] do
        prefix
      else
        Enum.join(before, "\n") <> "\n" <> prefix
      end

    {before_cursor, at_cursor, Enum.join([suffix | after_cursor], "\n")}
  end
end
