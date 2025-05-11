defmodule Computer.Samples.RocCalculator do
  import Computer.Dsl

  def sample() do
    computer "ROC Calculator" do
      input("r",
        type: :number,
        description: "Radius of feet (in mm)",
        initial: 40
      )

      input("s",
        type: :number,
        description: "Sagitta (in mm)",
        initial: 3
      )

      input("b",
        type: :number,
        description: "Ball diameter (in mm)",
        initial: 3
      )

      input("curve",
        type: :select,
        description: "Curve type",
        initial: "concave",
        options: [
          {"concave", "Concave"},
          {"convex", "Convex"}
        ]
      )

      val("roc",
        description: "ROC: (r² + s²) / 2s ± b/2",
        type: :number,
        fun: fn %{"r" => r, "s" => s, "b" => b, "curve" => curve} ->
          b_value = if curve == "concave", do: b, else: -b
          (r * r + s * s) / (2 * s) + b_value / 2
        end,
        depends_on: ["r", "s", "b", "curve"]
      )
    end
  end
end
