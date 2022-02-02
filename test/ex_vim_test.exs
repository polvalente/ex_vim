defmodule ExVimTest do
  use ExUnit.Case
  doctest ExVim

  test "greets the world" do
    assert ExVim.hello() == :world
  end
end
