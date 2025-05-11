defmodule Computer.Samples.RunCalc do
  import Computer.Dsl

  def sample() do
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
  end
end
