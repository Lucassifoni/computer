defmodule Computer.DslTest do
  use ExUnit.Case

  describe "DSL" do
    test "creates a computer with inputs and values" do
      pace_computer = Computer.Samples.Pace.sample()

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
      calculator = Computer.Samples.RunCalc.sample()

      assert calculator.values["pace"] == 6.0
      assert calculator.values["speed"] == 10.0
      assert calculator.values["calories"] == 187.5

      updated = Computer.handle_input(calculator, "time", 60)
      assert updated.values["pace"] == 12.0
      assert updated.values["speed"] == 5.0
      assert updated.values["calories"] == 187.5
    end

    test "creates a ROC calculator and computes correctly" do
      roc_calculator = Computer.Samples.RocCalculator.sample()

      assert roc_calculator.name == "ROC Calculator"
      assert length(roc_calculator.inputs) == 4
      assert length(roc_calculator.vals) == 1

      radius_input = Enum.find(roc_calculator.inputs, &(&1.name == "r"))
      assert radius_input.type == :number
      assert radius_input.description == "Radius of feet (in mm)"
      assert radius_input.initial_val == 40

      sagitta_input = Enum.find(roc_calculator.inputs, &(&1.name == "s"))
      assert sagitta_input.type == :number
      assert sagitta_input.description == "Sagitta (in mm)"
      assert sagitta_input.initial_val == 3

      ball_input = Enum.find(roc_calculator.inputs, &(&1.name == "b"))
      assert ball_input.type == :number
      assert ball_input.description == "Ball diameter (in mm)"
      assert ball_input.initial_val == 3

      curve_input = Enum.find(roc_calculator.inputs, &(&1.name == "curve"))
      assert curve_input.type == :select
      assert curve_input.description == "Curve type"
      assert curve_input.initial_val == "concave"
      assert curve_input.options == [{"concave", "Concave"}, {"convex", "Convex"}]

      roc_val = Enum.find(roc_calculator.vals, &(&1.name == "roc"))
      assert roc_val.type == :number
      assert roc_val.description == "ROC: (r² + s²) / 2s ± b/2"

      assert roc_calculator.values["r"] == 40
      assert roc_calculator.values["s"] == 3
      assert roc_calculator.values["b"] == 3
      assert roc_calculator.values["curve"] == "concave"

      expected_roc = (40 * 40 + 3 * 3) / (2 * 3) + 3 / 2
      assert_in_delta roc_calculator.values["roc"], expected_roc, 0.001

      updated = Computer.handle_input(roc_calculator, "r", 50)
      expected_roc = (50 * 50 + 3 * 3) / (2 * 3) + 3 / 2
      assert_in_delta updated.values["roc"], expected_roc, 0.001

      updated = Computer.handle_input(roc_calculator, "curve", "convex")
      expected_roc = (40 * 40 + 3 * 3) / (2 * 3) - 3 / 2
      assert_in_delta updated.values["roc"], expected_roc, 0.001
    end
  end

  describe "MPCC Calculator" do
    test "creates a telescope conic calculator and computes correctly" do
      mpcc_calc = Computer.Samples.MpccCalc.sample()

      assert mpcc_calc.name == "Baader MPCC Conic calculator"
      assert length(mpcc_calc.inputs) == 2
      assert length(mpcc_calc.vals) == 4

      diameter_input = Enum.find(mpcc_calc.inputs, &(&1.name == "d"))
      assert diameter_input.type == :number
      assert diameter_input.description == "Diameter (mm)"
      assert diameter_input.initial_val == 300

      focal_input = Enum.find(mpcc_calc.inputs, &(&1.name == "f"))
      assert focal_input.type == :number
      assert focal_input.description == "Focal length (mm)"
      assert focal_input.initial_val == 1200

      ratio_val = Enum.find(mpcc_calc.vals, &(&1.name == "ratio"))
      assert ratio_val.type == :number
      assert ratio_val.description == "Focal ratio"

      correction_val = Enum.find(mpcc_calc.vals, &(&1.name == "correction"))
      assert correction_val.type == :number
      assert correction_val.description == "Parabola correction (waves @550nm)"

      undercorrection_val = Enum.find(mpcc_calc.vals, &(&1.name == "undercorrection"))
      assert undercorrection_val.type == :number
      assert undercorrection_val.description == "MPCC S.A. undercorrection (waves @550nm)"

      target_val = Enum.find(mpcc_calc.vals, &(&1.name == "target"))
      assert target_val.type == :number
      assert target_val.description == "Target conic"

      f = 1200
      d = 300
      ratio = f / d
      correction = d / (1.1264 * (ratio * ratio * ratio))
      undercorrection = 4 / ratio

      undercorrection =
        undercorrection * undercorrection * undercorrection * undercorrection * 0.81

      target = -1 - undercorrection / correction

      assert_in_delta mpcc_calc.values["ratio"], ratio, 0.001
      assert_in_delta mpcc_calc.values["correction"], correction, 0.001
      assert_in_delta mpcc_calc.values["undercorrection"], undercorrection, 0.001
      assert_in_delta mpcc_calc.values["target"], target, 0.001

      updated = Computer.handle_input(mpcc_calc, "d", 400)
      new_ratio = 1200 / 400
      new_correction = 400 / (1.1264 * (new_ratio * new_ratio * new_ratio))
      new_undercorrection = 4 / new_ratio

      new_undercorrection =
        new_undercorrection * new_undercorrection * new_undercorrection * new_undercorrection *
          0.81

      new_target = -1 - new_undercorrection / new_correction

      assert_in_delta updated.values["ratio"], new_ratio, 0.001
      assert_in_delta updated.values["correction"], new_correction, 0.001
      assert_in_delta updated.values["undercorrection"], new_undercorrection, 0.001
      assert_in_delta updated.values["target"], new_target, 0.001

      updated = Computer.handle_input(mpcc_calc, "f", 2000)
      new_ratio = 2000 / 300
      new_correction = 300 / (1.1264 * (new_ratio * new_ratio * new_ratio))
      new_undercorrection = 4 / new_ratio

      new_undercorrection =
        new_undercorrection * new_undercorrection * new_undercorrection * new_undercorrection *
          0.81

      new_target = -1 - new_undercorrection / new_correction

      assert_in_delta updated.values["ratio"], new_ratio, 0.001
      assert_in_delta updated.values["correction"], new_correction, 0.001
      assert_in_delta updated.values["undercorrection"], new_undercorrection, 0.001
      assert_in_delta updated.values["target"], new_target, 0.001
    end
  end
end
