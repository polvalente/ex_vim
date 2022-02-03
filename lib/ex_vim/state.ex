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

      {:ok, {:save, filename}} ->
        File.write!(filename, current_buffer(state).content)
        %{state | input: "", mode: :normal}

      {:ok, {:save_and_exit, filename}} ->
        File.write!(filename, current_buffer(state).content)
        %{state | input: "", mode: :exit}

      _ ->
        state
        |> then(&%{&1 | input: "", mode: :normal})
    end
  end
end
