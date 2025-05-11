defmodule Computer.DslTest do
  use ExUnit.Case
  require Computer.Dsl
  import Computer.Dsl

  describe "DSL" do
    test "creates a computer with inputs and values" do
      pace_computer =
        computer "Pace computer" do
          input("time",
            type: :number,
            description: "Your running time in minutes",
            initial: 30
          )

          input("distance",
            type: :number,
            description: "Your running distance in km",
            initial: 10
          )

          val("pace",
            description: "Your running pace in minutes per km",
            type: :number,
            fun: fn %{"time" => time, "distance" => distance} -> time / distance end,
            depends_on: ["time", "distance"]
          )
        end

      assert pace_computer.name == "Pace computer"
      assert length(pace_computer.inputs) == 2
      assert length(pace_computer.vals) == 1

      time_input = Enum.find(pace_computer.inputs, &(&1.name == "time"))
      assert time_input.type == :number
      assert time_input.description == "Your running time in minutes"

      distance_input = Enum.find(pace_computer.inputs, &(&1.name == "distance"))
      assert distance_input.type == :number
      assert distance_input.description == "Your running distance in km"

      pace_val = Enum.find(pace_computer.vals, &(&1.name == "pace"))
      assert pace_val.type == :number
      assert pace_val.description == "Your running pace in minutes per km"

      assert pace_computer.values["pace"] == 3.0

      updated_computer = Computer.handle_input(pace_computer, "time", 40)
      assert updated_computer.values["pace"] == 4.0

      updated_computer = Computer.handle_input(updated_computer, "distance", 5)
      assert updated_computer.values["pace"] == 8.0
    end

    test "can create a more complex computer with multiple values" do
      calculator =
        computer "Running calculator" do
          input("time",
            type: :number,
            description: "Your running time in minutes",
            initial: 30
          )

          input("distance",
            type: :number,
            description: "Your running distance in km",
            initial: 5
          )

          val("pace",
            description: "Your running pace in minutes per km",
            type: :number,
            fun: fn %{"time" => time, "distance" => distance} -> time / distance end,
            depends_on: ["time", "distance"]
          )

          val("speed",
            description: "Your running speed in km/h",
            type: :number,
            fun: fn %{"time" => time, "distance" => distance} -> distance / (time / 60) end,
            depends_on: ["time", "distance"]
          )

          val("calories",
            description: "Estimated calories burned",
            type: :number,
            fun: fn %{"time" => time, "speed" => speed} -> time / 60 * (450 * speed / 12) end,
            depends_on: ["time", "speed"]
          )
        end

      assert calculator.values["pace"] == 6.0
      assert calculator.values["speed"] == 10.0
      assert calculator.values["calories"] == 187.5

      updated = Computer.handle_input(calculator, "time", 60)
      assert updated.values["pace"] == 12.0
      assert updated.values["speed"] == 5.0
      assert updated.values["calories"] == 187.5
    end
  end
end
