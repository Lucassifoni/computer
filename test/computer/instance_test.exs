defmodule Computer.InstanceTest do
  use ExUnit.Case

  describe "Computer Instance" do
    test "handles input via GenServer" do
      pace_computer = Computer.Samples.Pace.sample()

      {:ok, pid} =
        GenServer.start_link(Computer.Instance, pace_computer, name: Computer.Instance)

      {:ok, values} = Computer.Instance.handle_input(pid, "time", 40)
      assert values["pace"] == 4.0

      {:ok, values} = Computer.Instance.handle_input(pid, "distance", 5)
      assert values["pace"] == 8.0

      GenServer.stop(Computer.Instance)
    end

    test "processes multiple inputs" do
      calculator = Computer.Samples.RunCalc.sample()

      {:ok, pid} = GenServer.start_link(Computer.Instance, calculator, name: Computer.Instance)

      {:ok, values} = Computer.Instance.handle_input(pid, "time", 60)
      assert values["pace"] == 12.0
      assert values["speed"] == 5.0
      assert values["calories"] == 187.5

      {:ok, _values} = Computer.Instance.handle_input(pid, "distance", 10)

      GenServer.stop(Computer.Instance)
    end
  end
end
