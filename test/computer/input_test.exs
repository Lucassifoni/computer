defmodule Computer.InputTest do
  use ExUnit.Case
  alias Computer.Input

  test "creates a new input" do
    input = Input.new("test", "Test description", :number, 5)
    assert input.name == "test"
    assert input.description == "Test description"
    assert input.type == :number
    assert input.initial_val == 5
  end
end
