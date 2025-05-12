defmodule Computer.Samples.Pace do
  import Computer.Dsl

  def sample() do
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
        fun: fn %{"time" => time, "distance" => distance} -> time / distance end
      )
    end
  end
end
