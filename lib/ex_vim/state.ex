defmodule ExVim.State do
  defstruct buffers: [%ExVim.Buffer{}], current_buffer_index: 0, mode: :normal

  def current_buffer(state), do: Enum.at(state.buffers, state.current_buffer_index)

  def update_current_buffer(state, buffer) do
    put_in(state, [Access.key(:buffers), Access.at(state.current_buffer_index)], buffer)
  end
end
