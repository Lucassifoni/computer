defmodule Computer.ValTest do
  use ExUnit.Case
  alias Computer.Val

  test "creates a new val" do
    fun = fn args -> args.value * 2 end
    val = Val.new("test", "Test description", :number, fun)
    assert val.name == "test"
    assert val.description == "Test description"
    assert val.type == :number
    assert val.fun == fun
  end
end
