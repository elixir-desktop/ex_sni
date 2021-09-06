defmodule ExSniTest do
  use ExUnit.Case
  doctest ExSni

  test "greets the world" do
    assert ExSni.hello() == :world
  end
end
