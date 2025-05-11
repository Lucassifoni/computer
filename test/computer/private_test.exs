defmodule Computer.PrivateTest do
  use ExUnit.Case
  alias Computer.Private
  alias Computer.Input
  alias Computer.Output

  test "creates a new private state" do
    private = Private.new()
    assert private.inputs == %{}
    assert private.outputs == %{}
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

  test "registers an output" do
    fun = fn args -> args.value * 2 end
    output = Output.new("test", "Test description", :number, true, fun)

    private =
      Private.new()
      |> Private.register_output(output)

    assert private.outputs["test"] == nil
    assert private.funs["test"] == fun
  end

  test "computes dependency maps" do
    private =
      Private.new()
      |> Map.put(:dependencies, [{"output1", "input1"}, {"output2", "output1"}])
      |> Private.compute_dependency_maps()

    assert private.depended_bys["input1"] == ["output1"]
    assert private.depended_bys["output1"] == ["output2"]
    assert private.depended_ons["output1"] == ["input1"]
    assert private.depended_ons["output2"] == ["output1"]
  end
end
