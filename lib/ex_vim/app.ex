defmodule ExVim.App do
  @behaviour Ratatouille.App

  import Ratatouille.View

  alias ExVim.{Buffer, State}

  def init(_context), do: %State{}

  @key_up Ratatouille.Constants.key(:arrow_up)
  @key_down Ratatouille.Constants.key(:arrow_down)
  @key_left Ratatouille.Constants.key(:arrow_left)
  @key_right Ratatouille.Constants.key(:arrow_right)
  @enter Ratatouille.Constants.key(:enter)
  @esc Ratatouille.Constants.key(:esc)

  @backspace Ratatouille.Constants.key(:backspace)
  @backspace2 Ratatouille.Constants.key(:backspace2)
  @delete Ratatouille.Constants.key(:delete)

  def update(state, msg) do
    case state.mode do
      :normal -> normal_mode(state, msg)
      :normal_command -> normal_command_mode(state, msg)
      :insert -> insert_mode(state, msg)
    end
  end

  defp normal_mode(state, msg) do
    case msg do
      {:event, %{ch: i}} when i in [?i, ?I] ->
        %{state | mode: :insert}

      {:event, %{ch: ?o}} ->
        state
        |> State.current_buffer()
        |> then(&Buffer.newline(&1, &1.row))
        |> then(&State.update_current_buffer(state, &1))
        |> then(&%{&1 | mode: :insert})

      {:event, %{ch: ?O}} ->
        state
        |> State.current_buffer()
        |> then(&Buffer.newline(&1, &1.row - 1))
        |> then(&State.update_current_buffer(state, &1))
        |> then(&%{&1 | mode: :insert})

      {:event, %{key: @delete}} ->
        state
        |> State.current_buffer()
        |> then(&Buffer.delete(&1, &1.row, &1.col))
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_up}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:up)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_down}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:down)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_left}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:left)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_right}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:right)
        |> then(&State.update_current_buffer(state, &1))

      _ ->
        state
    end
  end

  defp normal_command_mode(state, _msg) do
    state
  end

  defp insert_mode(state, msg) do
    case msg do
      {:event, %{key: @esc}} ->
        %{state | mode: :normal}

      {:event, %{key: key}} when key in [@backspace, @backspace2] ->
        state
        |> State.current_buffer()
        |> then(&Buffer.backspace(&1, &1.row, &1.col))
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @delete}} ->
        state
        |> State.current_buffer()
        |> then(&Buffer.delete(&1, &1.row, &1.col))
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_up}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:up)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_down}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:down)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_left}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:left)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @key_right}} ->
        state
        |> State.current_buffer()
        |> Buffer.direction(:right)
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{key: @enter}} ->
        state
        |> State.current_buffer()
        |> then(&Buffer.newline(&1, &1.row))
        |> then(&State.update_current_buffer(state, &1))

      {:event, %{ch: char}} ->
        state
        |> State.current_buffer()
        |> then(&Buffer.add_substring(&1, &1.row, &1.col, <<char::utf8>>))
        |> then(&State.update_current_buffer(state, &1))

      _ ->
        state
    end
  end

  def render(state) do
    buffer = State.current_buffer(state)
    {before_cursor, at_cursor, after_cursor} = Buffer.content(buffer)

    cursor = if(rem(System.system_time(:millisecond), 1000) > 500, do: "|", else: " ")

    view do
      panel title: String.upcase("[#{state.mode}] - ") <> Buffer.title(buffer) do
        label(
          content:
            before_cursor <>
              cursor <>
              at_cursor <>
              after_cursor
        )
      end

      if state.mode == :normal_command do
        label(content: state.input)
      end
    end
  end
end
