defmodule Computer.Samples.Stateful do
  import Computer.Dsl

  def activity() do
    stateful_computer "activity_tracker" do
      input("distance",
        type: :number,
        description: "Distance (km)",
        initial: 0
      )

      input("time",
        type: :number,
        description: "Time (minutes)",
        initial: 0
      )

      input("log_workout",
        type: :boolean,
        description: "Log Workout",
        initial: false
      )

      input("reset_stats",
        type: :boolean,
        description: "Reset Stats",
        initial: false
      )

      val("pace",
        description: "Current Pace (min/km)",
        type: :number,
        fun: fn %{"time" => time, "distance" => distance}, _previous ->
          if distance > 0, do: time / distance, else: 0
        end
      )

      val("speed",
        description: "Current Speed (km/h)",
        type: :number,
        fun: fn %{"time" => time, "distance" => distance}, _previous ->
          if time > 0, do: distance / (time / 60), else: 0
        end
      )

      val("calories",
        description: "Current Calories",
        type: :number,
        fun: fn %{"time" => time, "speed" => speed}, _previous ->
          if time > 0 and speed > 0, do: time / 60 * (450 * speed / 12), else: 0
        end
      )

      val("workout_count",
        description: "Total Workouts",
        type: :number,
        fun: fn %{"reset_stats" => reset_stats, "log_workout" => log_workout}, previous_values ->
          previous_count = previous_values["workout_count"] || 0

          cond do
            reset_stats -> 0
            log_workout -> previous_count + 1
            true -> previous_count
          end
        end
      )

      val("total_distance",
        description: "Total Distance (km)",
        type: :number,
        fun: fn %{
                  "reset_stats" => reset_stats,
                  "log_workout" => log_workout,
                  "distance" => distance
                },
                previous_values ->
          previous_total = previous_values["total_distance"] || 0

          cond do
            reset_stats -> 0
            log_workout -> previous_total + distance
            true -> previous_total
          end
        end
      )

      val("total_time",
        description: "Total Time (min)",
        type: :number,
        fun: fn %{"reset_stats" => reset_stats, "log_workout" => log_workout, "time" => time},
                previous_values ->
          previous_total = previous_values["total_time"] || 0

          cond do
            reset_stats -> 0
            log_workout -> previous_total + time
            true -> previous_total
          end
        end
      )

      val("total_calories",
        description: "Total Calories",
        type: :number,
        fun: fn %{"reset_stats" => reset_stats, "log_workout" => log_workout}, previous_values ->
          previous_total = previous_values["total_calories"] || 0
          current_calories = previous_values["calories"] || 0

          cond do
            reset_stats -> 0
            log_workout -> previous_total + current_calories
            true -> previous_total
          end
        end
      )

      val("average_pace",
        description: "Average Pace (min/km)",
        type: :number,
        fun: fn %{"log_workout" => _log_workout}, previous_values ->
          total_distance = previous_values["total_distance"] || 0
          total_time = previous_values["total_time"] || 0

          if total_distance > 0, do: total_time / total_distance, else: 0
        end
      )
    end
  end

  def latch() do
    stateful_computer "latch" do
      input("set",
        type: :boolean,
        description: "Set the latch",
        initial: false
      )

      input("reset",
        type: :boolean,
        description: "Reset the latch",
        initial: false
      )

      val("value",
        description: "Current latch value",
        type: :boolean,
        fun: fn %{"set" => set, "reset" => reset}, previous_values ->
          previous_value = previous_values["value"] || false

          cond do
            reset -> false
            set -> true
            true -> previous_value
          end
        end
      )
    end
  end

  def oscillator() do
    stateful_computer "oscillator" do
      input("enabled",
        type: :boolean,
        description: "Enable the oscillator",
        initial: false
      )

      input("frequency",
        type: :number,
        description: "Oscillation frequency (Hz)",
        initial: 1.0
      )

      val("tick_count",
        description: "Number of ticks",
        type: :number,
        fun: fn %{"enabled" => enabled}, previous_values ->
          previous_count = previous_values["tick_count"] || 0

          if enabled do
            previous_count + 1
          else
            previous_count
          end
        end
      )

      val("value",
        description: "Oscillator output",
        type: :boolean,
        fun: fn %{"enabled" => enabled, "frequency" => frequency, "tick_count" => tick_count},
                _previous ->
          if enabled do
            rem(floor(tick_count * frequency), 2) == 0
          else
            false
          end
        end
      )
    end
  end

  def averages() do
    stateful_computer "average_calculator" do
      input("value",
        type: :number,
        description: "Current Value",
        initial: 0
      )

      input("add",
        type: :boolean,
        description: "Add to Dataset",
        initial: false
      )

      input("reset",
        type: :boolean,
        description: "Reset Dataset",
        initial: false
      )

      val("count",
        description: "Count of Values",
        type: :number,
        fun: fn %{"reset" => reset, "add" => add}, previous_values ->
          previous_count = previous_values["count"] || 0

          cond do
            reset -> 0
            add -> previous_count + 1
            true -> previous_count
          end
        end
      )

      val("sum",
        description: "Sum of Values",
        type: :number,
        fun: fn %{"reset" => reset, "add" => add, "value" => value}, previous_values ->
          previous_sum = previous_values["sum"] || 0

          cond do
            reset -> 0
            add -> previous_sum + value
            true -> previous_sum
          end
        end
      )

      val("average",
        description: "Average Value",
        type: :number,
        fun: fn %{"reset" => reset, "add" => _add}, previous_values ->
          count = previous_values["count"] || 0
          sum = previous_values["sum"] || 0

          cond do
            reset -> 0
            count > 0 -> sum / count
            true -> 0
          end
        end
      )
    end
  end

  def runningtotal() do
    stateful_computer "running_total" do
      input("value",
        type: :number,
        description: "Current Value",
        initial: 0
      )

      input("add",
        type: :boolean,
        description: "Add to Total",
        initial: false
      )

      input("reset",
        type: :boolean,
        description: "Reset Total",
        initial: false
      )

      val("total",
        description: "Running Total",
        type: :number,
        fun: fn %{"reset" => reset, "add" => add, "value" => value}, previous_values ->
          previous_total = previous_values["total"] || 0

          cond do
            reset -> 0
            add -> previous_total + value
            true -> previous_total
          end
        end
      )
    end
  end

  def loan() do
    stateful_computer "loan_calculator" do
      input("loan_amount",
        type: :number,
        description: "Loan amount ($)",
        initial: 300_000
      )

      input("interest_rate",
        type: :number,
        description: "Annual interest rate (%)",
        initial: 4.5
      )

      input("loan_term",
        type: :number,
        description: "Loan term (years)",
        initial: 30
      )

      input("make_payment",
        type: :boolean,
        description: "Make Payment",
        initial: false
      )

      input("reset_loan",
        type: :boolean,
        description: "Reset Loan",
        initial: false
      )

      val("monthly_payment",
        description: "Monthly Payment ($)",
        type: :number,
        fun: fn %{"loan_amount" => amount, "interest_rate" => rate, "loan_term" => years},
                _previous ->
          monthly_rate = rate / 100 / 12
          num_payments = years * 12

          if monthly_rate > 0 do
            amount * monthly_rate * :math.pow(1 + monthly_rate, num_payments) /
              (:math.pow(1 + monthly_rate, num_payments) - 1)
          else
            amount / num_payments
          end
        end
      )

      val("remaining_balance",
        description: "Remaining Balance ($)",
        type: :number,
        fun: fn %{
                  "reset_loan" => reset_loan,
                  "make_payment" => make_payment,
                  "loan_amount" => loan_amount,
                  "interest_rate" => interest_rate
                },
                previous_values ->
          previous_balance = previous_values["remaining_balance"] || loan_amount
          monthly_payment = previous_values["monthly_payment"] || 0
          monthly_rate = interest_rate / 100 / 12

          cond do
            reset_loan ->
              loan_amount

            make_payment ->
              interest_payment = previous_balance * monthly_rate
              principal_payment = monthly_payment - interest_payment
              max(previous_balance - principal_payment, 0)

            true ->
              previous_balance
          end
        end
      )

      val("total_interest",
        description: "Total Interest Paid ($)",
        type: :number,
        fun: fn %{
                  "reset_loan" => reset_loan,
                  "make_payment" => make_payment,
                  "loan_amount" => loan_amount,
                  "interest_rate" => interest_rate
                },
                previous_values ->
          previous_total = previous_values["total_interest"] || 0
          previous_balance = previous_values["remaining_balance"] || loan_amount
          monthly_rate = interest_rate / 100 / 12

          cond do
            reset_loan ->
              0

            make_payment ->
              interest_payment = previous_balance * monthly_rate
              previous_total + interest_payment

            true ->
              previous_total
          end
        end
      )

      val("payment_number",
        description: "Payment Number",
        type: :number,
        fun: fn %{"reset_loan" => reset_loan, "make_payment" => make_payment}, previous_values ->
          previous_number = previous_values["payment_number"] || 0

          cond do
            reset_loan -> 0
            make_payment -> previous_number + 1
            true -> previous_number
          end
        end
      )
    end
  end
end
