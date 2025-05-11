defmodule Computer.PrivateTest do
  use ExUnit.Case
  alias Computer.Private
  alias Computer.Input
  alias Computer.Val

  test "creates a new private state" do
    private = Private.new()
    assert private.inputs == %{}
    assert private.vals == %{}
    assert private.dependencies == []
  end

  test "registers an input" do
    input = Input.new("test", "Test description", :number, 5)

    private =
      Private.new()
      |> Private.register_input(input)

    assert private.inputs["test"] == 5
    assert private.names["test"] == :input
  end

  test "registers an val" do
    fun = fn args -> args.value * 2 end
    val = Val.new("test", "Test description", :number, fun)

    private =
      Private.new()
      |> Private.register_val(val)

    assert private.vals["test"] == nil
    assert private.funs["test"] == fun
  end

  test "computes dependency maps" do
    private =
      Private.new()
      |> Map.put(:dependencies, [{"val1", "input1"}, {"val2", "val1"}])
      |> Private.compute_dependency_maps()

    assert private.depended_bys["input1"] == ["val1"]
    assert private.depended_bys["val1"] == ["val2"]
    assert private.depended_ons["val1"] == ["input1"]
    assert private.depended_ons["val2"] == ["val1"]
  end
end
