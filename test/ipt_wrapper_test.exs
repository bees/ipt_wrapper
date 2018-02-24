defmodule IPTWrapperTest do
  use ExUnit.Case
  doctest IPTWrapper

  test "greets the world" do
    assert IPTWrapper.hello() == :world
  end
end
