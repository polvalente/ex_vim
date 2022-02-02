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
end
