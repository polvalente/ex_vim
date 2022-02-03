defmodule ExVim.State do
  defstruct buffers: [%ExVim.Buffer{}], current_buffer_index: 0, mode: :normal, input: ""

  alias ExVim.Buffer
  alias ExVim.State.CommandParser

  def current_buffer(state), do: Enum.at(state.buffers, state.current_buffer_index)

  def update_current_buffer(state, buffer) do
    put_in(state, [Access.key(:buffers), Access.at(state.current_buffer_index)], buffer)
  end

  # to-do: use a pseudo buffer for the input
  def append_input(state, str), do: %{state | input: state.input <> str}

  def execute_input(state) do
    File.write("log.txt", inspect(state))
    cmd = CommandParser.parse_command(state.input)

    case cmd do
      {:ok, {:find_and_replace_single, to_find, to_replace, opts}} ->
        state
        |> current_buffer()
        |> Buffer.find_and_replace_single(to_find, to_replace, opts)
        |> then(&update_current_buffer(state, &1))
        |> then(&%{&1 | input: "", mode: :normal})

      {:ok, {:find_and_replace_global, to_find, to_replace, opts}} ->
        state
        |> current_buffer()
        |> Buffer.find_and_replace_global(to_find, to_replace, opts)
        |> then(&update_current_buffer(state, &1))
        |> then(&%{&1 | input: "", mode: :normal})

      {:ok, :exit} ->
        %{state | input: "", mode: :exit}

      {:ok, :bnext} ->
        %{
          state
          | current_buffer_index: rem(state.current_buffer_index + 1, length(state.buffers)),
            input: "",
            mode: :normal
        }

      {:ok, {:save, filename}} ->
        File.write!(filename, current_buffer(state).content)
        set_current_buffer_name(%{state | input: "", mode: :normal}, filename)

      {:ok, {:save_and_exit, filename}} ->
        filename = filename || current_buffer(state).name
        File.write!(filename, current_buffer(state).content)
        set_current_buffer_name(%{state | input: "", mode: :exit}, filename)

      {:ok, {:edit, filename}} ->
        contents = filename |> File.read!() |> String.split("\n")
        buffer = %Buffer{content: contents, name: filename}

        %{
          state
          | buffers: [buffer | state.buffers],
            current_buffer_index: 0,
            input: "",
            mode: :normal
        }

      _ ->
        state
        |> then(&%{&1 | input: "", mode: :normal})
    end
  end

  defp set_current_buffer_name(state, name) do
    buffer = state |> current_buffer() |> Buffer.set_name(name)

    update_current_buffer(state, buffer)
  end
end
