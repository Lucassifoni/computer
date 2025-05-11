defmodule ComputerTest do
  use ExUnit.Case
  alias Computer
  alias Computer.Input
  alias Computer.Val

  describe "Computer" do
    test "creates a new computer" do
      computer = Computer.new("test")
      assert computer.name == "test"
      assert computer.inputs == []
      assert computer.vals == []
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

    test "adds val to computer" do
      fun = fn %{"input1" => val} -> val * 2 end
      val = Val.new("val1", "Test val", :number, fun)
      input = Input.new("input1", "Test input", :number, 5)

      computer =
        Computer.new("test")
        |> Computer.add_input(input)
        |> Computer.add_val(val, "input1")

      assert length(computer.vals) == 1
      assert hd(computer.vals).name == "val1"
    end

    test "computes dependent values" do
      input = Input.new("input1", "Test input", :number, 5)
      val_fun = fn %{"input1" => val} -> val * 2 end
      val = Val.new("val1", "Test val", :number, val_fun)

      nested_val_fun = fn %{"val1" => val} -> val + 10 end
      nested_val = Val.new("val2", "Nested val", :number, nested_val_fun)

      computer =
        Computer.new("test")
        |> Computer.add_input(input)
        |> Computer.add_val(val, "input1")
        |> Computer.add_val(nested_val, "val1")

      updated_computer = Computer.handle_input(computer, "input1", 10)

      assert updated_computer.values["val1"] == 20
      assert updated_computer.values["val2"] == 30
    end
  end

  describe "Pace Calculator" do
    test "calculates pace, speed, and calories" do
      time_input = Input.new("time", "Time (minutes)", :number, 30)
      distance_input = Input.new("distance", "Distance (km)", :number, 5)

      pace_fun = fn %{"time" => time, "distance" => distance} ->
        time / distance
      end

      pace_val = Val.new("pace", "Pace (min/km)", :number, pace_fun)

      speed_fun = fn %{"time" => time, "distance" => distance} ->
        distance / (time / 60)
      end

      speed_val = Val.new("speed", "Speed (km/h)", :number, speed_fun)

      calories_fun = fn %{"time" => time, "speed" => speed} ->
        time / 60 * (450 * speed / 12)
      end

      calories_val = Val.new("calories", "Calories burned", :number, calories_fun)

      computer =
        Computer.new("pace_calculator")
        |> Computer.add_input(time_input)
        |> Computer.add_input(distance_input)
        |> Computer.add_val(pace_val, ["time", "distance"])
        |> Computer.add_val(speed_val, ["time", "distance"])
        |> Computer.add_val(calories_val, ["time", "speed"])

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

      flour_val = Val.new("flour", "Flour amount (g)", :number, flour_fun)

      water_fun = fn %{"flour" => flour} ->
        flour * 0.65
      end

      water_val = Val.new("water", "Water amount (ml)", :number, water_fun)

      salt_fun = fn %{"flour" => flour} ->
        flour * 0.02
      end

      salt_val = Val.new("salt", "Salt amount (g)", :number, salt_fun)

      calories_fun = fn %{"flour" => flour, "servings" => servings} ->
        flour * 4 / servings
      end

      calories_val =
        Val.new("calories", "Calories per serving", :number, calories_fun)

      computer =
        Computer.new("recipe_calculator")
        |> Computer.add_input(servings_input)
        |> Computer.add_input(base_flour_input)
        |> Computer.add_val(flour_val, ["servings", "base_flour"])
        |> Computer.add_val(water_val, "flour")
        |> Computer.add_val(salt_val, "flour")
        |> Computer.add_val(calories_val, ["flour", "servings"])

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

      days_val =
        Val.new(
          "days_until_replacement",
          "Days until replacement",
          :number,
          days_until_replacement_fun
        )

      monthly_cost_fun = fn %{
                              "daily_distance" => daily,
                              "tire_cost" => cost,
                              "tire_lifespan" => lifespan
                            } ->
        daily * 30 / lifespan * cost
      end

      monthly_cost_val =
        Val.new("monthly_cost", "Monthly tire cost ($)", :number, monthly_cost_fun)

      wear_percentage_fun = fn %{"daily_distance" => daily, "tire_lifespan" => lifespan} ->
        daily / lifespan * 100
      end

      wear_val =
        Val.new(
          "wear_percentage",
          "Daily wear percentage",
          :number,
          wear_percentage_fun
        )

      computer =
        Computer.new("tire_calculator")
        |> Computer.add_input(daily_distance_input)
        |> Computer.add_input(tire_lifespan_input)
        |> Computer.add_input(tire_cost_input)
        |> Computer.add_val(days_val, ["daily_distance", "tire_lifespan"])
        |> Computer.add_val(monthly_cost_val, [
          "daily_distance",
          "tire_cost",
          "tire_lifespan"
        ])
        |> Computer.add_val(wear_val, ["daily_distance", "tire_lifespan"])

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

      daily_energy_val =
        Val.new("daily_energy", "Daily energy (kWh)", :number, daily_energy_fun)

      annual_energy_fun = fn %{"daily_energy" => daily} ->
        daily * 365
      end

      annual_energy_val =
        Val.new("annual_energy", "Annual energy (kWh)", :number, annual_energy_fun)

      annual_savings_fun = fn %{"annual_energy" => annual, "electricity_cost" => cost} ->
        annual * cost
      end

      annual_savings_val =
        Val.new("annual_savings", "Annual savings ($)", :number, annual_savings_fun)

      roi_years_fun = fn %{"system_cost" => cost, "annual_savings" => savings} ->
        cost / savings
      end

      roi_val = Val.new("roi_years", "ROI (years)", :number, roi_years_fun)

      computer =
        Computer.new("solar_calculator")
        |> Computer.add_input(panel_power_input)
        |> Computer.add_input(panel_count_input)
        |> Computer.add_input(sun_hours_input)
        |> Computer.add_input(electricity_cost_input)
        |> Computer.add_input(system_cost_input)
        |> Computer.add_val(daily_energy_val, ["panel_power", "panel_count", "sun_hours"])
        |> Computer.add_val(annual_energy_val, "daily_energy")
        |> Computer.add_val(annual_savings_val, ["annual_energy", "electricity_cost"])
        |> Computer.add_val(roi_val, ["system_cost", "annual_savings"])

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

      monthly_payment_val =
        Val.new("monthly_payment", "Monthly payment ($)", :number, monthly_payment_fun)

      total_payments_fun = fn %{"monthly_payment" => payment, "loan_term" => years} ->
        payment * years * 12
      end

      total_payments_val =
        Val.new("total_payments", "Total payments ($)", :number, total_payments_fun)

      total_interest_fun = fn %{"total_payments" => total, "loan_amount" => amount} ->
        total - amount
      end

      total_interest_val =
        Val.new("total_interest", "Total interest ($)", :number, total_interest_fun)

      computer =
        Computer.new("mortgage_calculator")
        |> Computer.add_input(loan_amount_input)
        |> Computer.add_input(interest_rate_input)
        |> Computer.add_input(loan_term_input)
        |> Computer.add_val(monthly_payment_val, [
          "loan_amount",
          "interest_rate",
          "loan_term"
        ])
        |> Computer.add_val(total_payments_val, ["monthly_payment", "loan_term"])
        |> Computer.add_val(total_interest_val, ["total_payments", "loan_amount"])

      assert Float.round(computer.values["monthly_payment"], 2) == 1520.06
      assert Float.round(computer.values["total_payments"], 2) == 547_220.13
      assert Float.round(computer.values["total_interest"], 2) == 247_220.13
    end
  end
end
