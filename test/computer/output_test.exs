defmodule Computer.OutputTest do
  use ExUnit.Case
  alias Computer.Output

  test "creates a new output" do
    fun = fn args -> args.value * 2 end
    output = Output.new("test", "Test description", :number, fun)
    assert output.name == "test"
    assert output.description == "Test description"
    assert output.type == :number
    assert output.fun == fun
  end
end
