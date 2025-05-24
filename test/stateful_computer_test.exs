defmodule StatefulComputerTest do
  use ExUnit.Case
  alias Computer
  import Computer.Dsl

  describe "Computer" do
    test "creates a new stateful computer" do
      computer =
        stateful_computer "test" do
        end

      assert computer.name == "test"
      assert computer.inputs == []
      assert computer.vals == []
    end

    test "adds input to stateful computer" do
      computer =
        stateful_computer "test" do
          input("input1",
            type: :number,
            description: "Test input",
            initial: 5
          )
        end

      assert length(computer.inputs) == 1
      assert hd(computer.inputs).name == "input1"
      assert computer.private.inputs["input1"] == 5
    end

    test "adds val to stateful computer" do
      computer =
        stateful_computer "test" do
          input("input1",
            type: :number,
            description: "Test input",
            initial: 5
          )

          val("val1",
            description: "Test val",
            type: :number,
            fun: fn %{"input1" => val}, _previous -> val * 2 end
          )
        end

      assert length(computer.vals) == 1
      assert hd(computer.vals).name == "val1"
    end

    test "computes dependent values with stateful computer" do
      computer =
        stateful_computer "test" do
          input("input1",
            type: :number,
            description: "Test input",
            initial: 5
          )

          val("val1",
            description: "Test val",
            type: :number,
            fun: fn %{"input1" => val}, _previous -> val * 2 end
          )

          val("val2",
            description: "Nested val",
            type: :number,
            fun: fn %{"val1" => val}, _previous -> val + 10 end
          )
        end

      updated_computer = Computer.handle_input(computer, "input1", 10)

      assert updated_computer.values["val1"] == 20
      assert updated_computer.values["val2"] == 30
    end
  end

  describe "Counter with Stateful Computer" do
    test "implements a counter that increments on each update" do
      computer =
        stateful_computer "counter" do
          input("reset",
            type: :boolean,
            description: "Reset Counter",
            initial: false
          )

          input("increment",
            type: :boolean,
            description: "Increment Counter",
            initial: false
          )

          val("counter",
            description: "Counter Value",
            type: :number,
            fun: fn %{"reset" => reset, "increment" => increment}, previous_values ->
              previous_count = previous_values["counter"] || 0

              cond do
                reset -> 0
                increment -> previous_count + 1
                true -> previous_count
              end
            end
          )
        end

      assert computer.values["counter"] == 0

      computer = Computer.handle_input(computer, "increment", true)
      assert computer.values["counter"] == 1

      computer = Computer.handle_input(computer, "increment", false)
      assert computer.values["counter"] == 1

      computer = Computer.handle_input(computer, "increment", true)
      assert computer.values["counter"] == 2

      computer = Computer.handle_input(computer, "increment", false)

      computer = Computer.handle_input(computer, "reset", true)
      assert computer.values["counter"] == 0

      computer = Computer.handle_input(computer, "reset", false)
      assert computer.values["counter"] == 0
    end
  end

  describe "Running Total Calculator" do
    test "calculates running total of values" do
      computer = Computer.Samples.Stateful.runningtotal()

      assert computer.values["total"] == 0
      computer = Computer.handle_input(computer, "value", 10)
      assert computer.values["total"] == 0
      computer = Computer.handle_input(computer, "add", true)
      assert computer.values["total"] == 10
      computer = Computer.handle_input(computer, "add", false)
      assert computer.values["total"] == 10
      computer = Computer.handle_input(computer, "value", 5)
      computer = Computer.handle_input(computer, "add", true)
      assert computer.values["total"] == 15
      computer = Computer.handle_input(computer, "reset", true)
      assert computer.values["total"] == 0
    end
  end

  describe "Average Calculator" do
    test "calculates rolling average of values" do
      computer = Computer.Samples.Stateful.averages()

      assert computer.values["count"] == 0
      assert computer.values["sum"] == 0
      assert computer.values["average"] == 0

      computer = Computer.handle_input(computer, "value", 10)
      computer = Computer.handle_input(computer, "add", true)
      computer = Computer.handle_input(computer, "add", false)
      assert computer.values["count"] == 1
      assert computer.values["sum"] == 10
      assert computer.values["average"] == 10

      computer = Computer.handle_input(computer, "value", 20)
      computer = Computer.handle_input(computer, "add", true)
      computer = Computer.handle_input(computer, "add", false)
      assert computer.values["count"] == 2
      assert computer.values["sum"] == 30
      assert computer.values["average"] == 15

      computer = Computer.handle_input(computer, "value", 30)
      computer = Computer.handle_input(computer, "add", true)
      computer = Computer.handle_input(computer, "add", false)
      assert computer.values["count"] == 3
      assert computer.values["sum"] == 60
      assert computer.values["average"] == 20

      computer = Computer.handle_input(computer, "reset", true)
      assert computer.values["count"] == 0
      assert computer.values["sum"] == 0
      assert computer.values["average"] == 0
    end
  end

  describe "Activity Tracker with Stateful Computer" do
    test "tracks cumulative distance, calories, and workout history" do
      computer = Computer.Samples.Stateful.activity()

      assert computer.values["workout_count"] == 0
      assert computer.values["total_distance"] == 0
      assert computer.values["total_calories"] == 0

      computer = Computer.handle_input(computer, "distance", 5)
      computer = Computer.handle_input(computer, "time", 30)
      assert computer.values["pace"] == 6.0
      assert computer.values["speed"] == 10.0
      assert computer.values["calories"] == 187.5

      computer = Computer.handle_input(computer, "log_workout", true)
      computer = Computer.handle_input(computer, "log_workout", false)
      assert computer.values["workout_count"] == 1
      assert computer.values["total_distance"] == 5
      assert computer.values["total_time"] == 30
      assert computer.values["total_calories"] == 187.5
      assert computer.values["average_pace"] == 6.0

      computer = Computer.handle_input(computer, "distance", 10)
      computer = Computer.handle_input(computer, "time", 60)
      assert computer.values["pace"] == 6.0
      assert computer.values["speed"] == 10.0
      assert computer.values["calories"] == 375.0

      computer = Computer.handle_input(computer, "log_workout", true)
      computer = Computer.handle_input(computer, "log_workout", false)
      assert computer.values["workout_count"] == 2
      assert computer.values["total_distance"] == 15
      assert computer.values["total_time"] == 90
      assert computer.values["total_calories"] == 562.5
      assert computer.values["average_pace"] == 6.0

      computer = Computer.handle_input(computer, "reset_stats", true)
      assert computer.values["workout_count"] == 0
      assert computer.values["total_distance"] == 0
      assert computer.values["total_time"] == 0
      assert computer.values["total_calories"] == 0
    end
  end

  describe "Loan Amortization with Stateful Computer" do
    test "calculates remaining balance and interest payments over time" do
      computer = Computer.Samples.Stateful.loan()

      assert computer.values["monthly_payment"] > 0
      assert computer.values["remaining_balance"] == 300_000
      assert computer.values["total_interest"] == 0
      assert computer.values["payment_number"] == 0

      computer = Computer.handle_input(computer, "make_payment", true)
      computer = Computer.handle_input(computer, "make_payment", false)

      assert computer.values["payment_number"] == 1
      assert computer.values["remaining_balance"] < 300_000
      assert computer.values["total_interest"] > 0

      computer = Computer.handle_input(computer, "make_payment", true)
      computer = Computer.handle_input(computer, "make_payment", false)

      assert computer.values["payment_number"] == 2

      computer = Computer.handle_input(computer, "reset_loan", true)
      computer = Computer.handle_input(computer, "reset_loan", false)

      assert computer.values["payment_number"] == 0
      assert computer.values["remaining_balance"] == 300_000
      assert computer.values["total_interest"] == 0
    end
  end

  describe "Latch with Stateful Computer" do
    test "manipulates a latch with set and reset actions" do
      computer = Computer.Samples.Stateful.latch()

      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "set", true)
      assert computer.values["value"] == true

      computer = Computer.handle_input(computer, "set", false)
      assert computer.values["value"] == true

      computer = Computer.handle_input(computer, "reset", true)
      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "reset", false)
      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "set", true)
      assert computer.values["value"] == true

      computer = Computer.handle_input(computer, "reset", true)
      computer = Computer.handle_input(computer, "set", true)
      assert computer.values["value"] == false
    end
  end

  describe "Oscillator with Stateful Computer" do
    test "oscillates output based on tick count and frequency" do
      computer = Computer.Samples.Stateful.oscillator()
      assert computer.values["tick_count"] == 0
      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "enabled", true)
      assert computer.values["tick_count"] == 1
      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "enabled", true)
      assert computer.values["tick_count"] == 2
      assert computer.values["value"] == true

      computer = Computer.handle_input(computer, "enabled", false)
      assert computer.values["tick_count"] == 2
      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "enabled", true)
      assert computer.values["tick_count"] == 3
      assert computer.values["value"] == false

      computer = Computer.handle_input(computer, "frequency", 2.0)
      assert computer.values["value"] == true

      computer = Computer.handle_input(computer, "enabled", true)
      assert computer.values["tick_count"] == 4
      assert computer.values["value"] == true
    end
  end
end
