defmodule ComputerTest do
  use ExUnit.Case
  alias Computer
  alias Computer.Input
  alias Computer.Output

  describe "Computer" do
    test "creates a new computer" do
      computer = Computer.new("test")
      assert computer.name == "test"
      assert computer.inputs == []
      assert computer.outputs == []
    end

    test "adds input to computer" do
      input = Input.new("input1", "Test input", :number, 5)

      computer =
        Computer.new("test")
        |> Computer.add_input(input)

      assert length(computer.inputs) == 1
      assert hd(computer.inputs).name == "input1"
      assert computer.private.inputs["input1"] == 5
    end

    test "adds output to computer" do
      fun = fn %{"input1" => val} -> val * 2 end
      output = Output.new("output1", "Test output", :number, true, fun)
      input = Input.new("input1", "Test input", :number, 5)

      computer =
        Computer.new("test")
        |> Computer.add_input(input)
        |> Computer.add_output(output, "input1")

      assert length(computer.outputs) == 1
      assert hd(computer.outputs).name == "output1"
    end

    test "computes dependent values" do
      input = Input.new("input1", "Test input", :number, 5)
      output_fun = fn %{"input1" => val} -> val * 2 end
      output = Output.new("output1", "Test output", :number, true, output_fun)

      nested_output_fun = fn %{"output1" => val} -> val + 10 end
      nested_output = Output.new("output2", "Nested output", :number, false, nested_output_fun)

      computer =
        Computer.new("test")
        |> Computer.add_input(input)
        |> Computer.add_output(output, "input1")
        |> Computer.add_output(nested_output, "output1")

      updated_computer = Computer.handle_input(computer, "input1", 10)

      assert updated_computer.values["output1"] == 20
      assert updated_computer.values["output2"] == 30
    end
  end

  describe "Pace Calculator" do
    test "calculates pace, speed, and calories" do
      time_input = Input.new("time", "Time (minutes)", :number, 30)
      distance_input = Input.new("distance", "Distance (km)", :number, 5)

      pace_fun = fn %{"time" => time, "distance" => distance} ->
        time / distance
      end

      pace_output = Output.new("pace", "Pace (min/km)", :number, true, pace_fun)

      speed_fun = fn %{"time" => time, "distance" => distance} ->
        distance / (time / 60)
      end

      speed_output = Output.new("speed", "Speed (km/h)", :number, true, speed_fun)

      calories_fun = fn %{"time" => time, "speed" => speed} ->
        time / 60 * (450 * speed / 12)
      end

      calories_output = Output.new("calories", "Calories burned", :number, false, calories_fun)

      computer =
        Computer.new("pace_calculator")
        |> Computer.add_input(time_input)
        |> Computer.add_input(distance_input)
        |> Computer.add_output(pace_output, ["time", "distance"])
        |> Computer.add_output(speed_output, ["time", "distance"])
        |> Computer.add_output(calories_output, ["time", "speed"])

      assert computer.private.inputs["time"] == 30
      assert computer.private.inputs["distance"] == 5
      assert computer.values["pace"] == 6.0
      assert computer.values["speed"] == 10.0
      assert computer.values["calories"] == 187.5

      updated_computer = Computer.handle_input(computer, "time", 60)
      assert updated_computer.private.inputs["time"] == 60
      assert updated_computer.private.inputs["distance"] == 5
      assert updated_computer.values["pace"] == 12.0
      assert updated_computer.values["speed"] == 5.0
      assert updated_computer.values["calories"] == 187.5

      updated_computer = Computer.handle_input(updated_computer, "distance", 10)
      assert updated_computer.private.inputs["time"] == 60
      assert updated_computer.private.inputs["distance"] == 10
      assert updated_computer.values["pace"] == 6.0
      assert updated_computer.values["speed"] == 10.0
      assert updated_computer.values["calories"] == 375.0
    end
  end

  describe "Recipe Scaling Calculator" do
    test "calculates ingredient amounts, servings, and nutritional info" do
      servings_input = Input.new("servings", "Number of servings", :number, 4)
      base_flour_input = Input.new("base_flour", "Base flour amount (g)", :number, 500)

      flour_fun = fn %{"servings" => servings, "base_flour" => base_flour} ->
        base_flour * (servings / 4)
      end

      flour_output = Output.new("flour", "Flour amount (g)", :number, true, flour_fun)

      water_fun = fn %{"flour" => flour} ->
        flour * 0.65
      end

      water_output = Output.new("water", "Water amount (ml)", :number, false, water_fun)

      salt_fun = fn %{"flour" => flour} ->
        flour * 0.02
      end

      salt_output = Output.new("salt", "Salt amount (g)", :number, false, salt_fun)

      calories_fun = fn %{"flour" => flour, "servings" => servings} ->
        flour * 4 / servings
      end

      calories_output =
        Output.new("calories", "Calories per serving", :number, false, calories_fun)

      computer =
        Computer.new("recipe_calculator")
        |> Computer.add_input(servings_input)
        |> Computer.add_input(base_flour_input)
        |> Computer.add_output(flour_output, ["servings", "base_flour"])
        |> Computer.add_output(water_output, "flour")
        |> Computer.add_output(salt_output, "flour")
        |> Computer.add_output(calories_output, ["flour", "servings"])

      assert computer.values["flour"] == 500
      assert computer.values["water"] == 325
      assert computer.values["salt"] == 10
      assert computer.values["calories"] == 500

      updated_computer = Computer.handle_input(computer, "servings", 8)
      assert updated_computer.values["flour"] == 1000
      assert updated_computer.values["water"] == 650
      assert updated_computer.values["salt"] == 20
      assert updated_computer.values["calories"] == 500
    end
  end

  describe "Bike Tire Wear Calculator" do
    test "calculates tire life, replacement date, and cost" do
      daily_distance_input = Input.new("daily_distance", "Daily distance (km)", :number, 20)
      tire_lifespan_input = Input.new("tire_lifespan", "Tire lifespan (km)", :number, 3000)
      tire_cost_input = Input.new("tire_cost", "Tire cost ($)", :number, 50)

      days_until_replacement_fun = fn %{"daily_distance" => daily, "tire_lifespan" => lifespan} ->
        lifespan / daily
      end

      days_output =
        Output.new(
          "days_until_replacement",
          "Days until replacement",
          :number,
          true,
          days_until_replacement_fun
        )

      monthly_cost_fun = fn %{
                              "daily_distance" => daily,
                              "tire_cost" => cost,
                              "tire_lifespan" => lifespan
                            } ->
        daily * 30 / lifespan * cost
      end

      monthly_cost_output =
        Output.new("monthly_cost", "Monthly tire cost ($)", :number, false, monthly_cost_fun)

      wear_percentage_fun = fn %{"daily_distance" => daily, "tire_lifespan" => lifespan} ->
        daily / lifespan * 100
      end

      wear_output =
        Output.new(
          "wear_percentage",
          "Daily wear percentage",
          :number,
          false,
          wear_percentage_fun
        )

      computer =
        Computer.new("tire_calculator")
        |> Computer.add_input(daily_distance_input)
        |> Computer.add_input(tire_lifespan_input)
        |> Computer.add_input(tire_cost_input)
        |> Computer.add_output(days_output, ["daily_distance", "tire_lifespan"])
        |> Computer.add_output(monthly_cost_output, [
          "daily_distance",
          "tire_cost",
          "tire_lifespan"
        ])
        |> Computer.add_output(wear_output, ["daily_distance", "tire_lifespan"])

      assert computer.values["days_until_replacement"] == 150
      assert computer.values["monthly_cost"] == 10
      assert computer.values["wear_percentage"] == 0.6666666666666667
    end
  end

  describe "Solar Panel Calculator" do
    test "calculates energy production, cost savings, and ROI" do
      panel_power_input = Input.new("panel_power", "Panel power (W)", :number, 300)
      panel_count_input = Input.new("panel_count", "Number of panels", :number, 10)
      sun_hours_input = Input.new("sun_hours", "Daily sun hours", :number, 5)

      electricity_cost_input =
        Input.new("electricity_cost", "Electricity cost ($/kWh)", :number, 0.15)

      system_cost_input = Input.new("system_cost", "System cost ($)", :number, 10000)

      daily_energy_fun = fn %{
                              "panel_power" => power,
                              "panel_count" => count,
                              "sun_hours" => hours
                            } ->
        power * count * hours / 1000
      end

      daily_energy_output =
        Output.new("daily_energy", "Daily energy (kWh)", :number, true, daily_energy_fun)

      annual_energy_fun = fn %{"daily_energy" => daily} ->
        daily * 365
      end

      annual_energy_output =
        Output.new("annual_energy", "Annual energy (kWh)", :number, false, annual_energy_fun)

      annual_savings_fun = fn %{"annual_energy" => annual, "electricity_cost" => cost} ->
        annual * cost
      end

      annual_savings_output =
        Output.new("annual_savings", "Annual savings ($)", :number, false, annual_savings_fun)

      roi_years_fun = fn %{"system_cost" => cost, "annual_savings" => savings} ->
        cost / savings
      end

      roi_output = Output.new("roi_years", "ROI (years)", :number, false, roi_years_fun)

      computer =
        Computer.new("solar_calculator")
        |> Computer.add_input(panel_power_input)
        |> Computer.add_input(panel_count_input)
        |> Computer.add_input(sun_hours_input)
        |> Computer.add_input(electricity_cost_input)
        |> Computer.add_input(system_cost_input)
        |> Computer.add_output(daily_energy_output, ["panel_power", "panel_count", "sun_hours"])
        |> Computer.add_output(annual_energy_output, "daily_energy")
        |> Computer.add_output(annual_savings_output, ["annual_energy", "electricity_cost"])
        |> Computer.add_output(roi_output, ["system_cost", "annual_savings"])

      assert computer.values["daily_energy"] == 15
      assert computer.values["annual_energy"] == 5475
      assert computer.values["annual_savings"] == 821.25
      assert computer.values["roi_years"] == 12.1765601217656
    end
  end

  describe "Mortgage Calculator" do
    test "calculates monthly payment, total interest, and amortization" do
      loan_amount_input = Input.new("loan_amount", "Loan amount ($)", :number, 300_000)
      interest_rate_input = Input.new("interest_rate", "Annual interest rate (%)", :number, 4.5)
      loan_term_input = Input.new("loan_term", "Loan term (years)", :number, 30)

      monthly_payment_fun = fn %{
                                 "loan_amount" => amount,
                                 "interest_rate" => rate,
                                 "loan_term" => years
                               } ->
        monthly_rate = rate / 100 / 12
        num_payments = years * 12

        amount * monthly_rate * :math.pow(1 + monthly_rate, num_payments) /
          (:math.pow(1 + monthly_rate, num_payments) - 1)
      end

      monthly_payment_output =
        Output.new("monthly_payment", "Monthly payment ($)", :number, true, monthly_payment_fun)

      total_payments_fun = fn %{"monthly_payment" => payment, "loan_term" => years} ->
        payment * years * 12
      end

      total_payments_output =
        Output.new("total_payments", "Total payments ($)", :number, false, total_payments_fun)

      total_interest_fun = fn %{"total_payments" => total, "loan_amount" => amount} ->
        total - amount
      end

      total_interest_output =
        Output.new("total_interest", "Total interest ($)", :number, false, total_interest_fun)

      computer =
        Computer.new("mortgage_calculator")
        |> Computer.add_input(loan_amount_input)
        |> Computer.add_input(interest_rate_input)
        |> Computer.add_input(loan_term_input)
        |> Computer.add_output(monthly_payment_output, [
          "loan_amount",
          "interest_rate",
          "loan_term"
        ])
        |> Computer.add_output(total_payments_output, ["monthly_payment", "loan_term"])
        |> Computer.add_output(total_interest_output, ["total_payments", "loan_amount"])

      assert Float.round(computer.values["monthly_payment"], 2) == 1520.06
      assert Float.round(computer.values["total_payments"], 2) == 547_220.13
      assert Float.round(computer.values["total_interest"], 2) == 247_220.13
    end
  end
end
