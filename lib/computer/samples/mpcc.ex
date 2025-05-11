defmodule Computer.Samples.MpccCalc do
  import Computer.Dsl

  def sample() do
    computer "Baader MPCC Conic calculator" do
      input("d", type: :number, description: "Diameter (mm)", initial: 300)
      input("f", type: :number, description: "Focal length (mm)", initial: 1200)

      val("ratio",
        description: "Focal ratio",
        type: :number,
        fun: fn %{"f" => f, "d" => d} -> f / d end,
        depends_on: ["f", "d"]
      )

      val("correction",
        description: "Parabola correction (waves @550nm)",
        type: :number,
        fun: fn %{"d" => d, "ratio" => ratio} -> d / (1.1264 * (ratio * ratio * ratio)) end,
        depends_on: ["d", "ratio"]
      )

      val("undercorrection",
        description: "MPCC S.A. undercorrection (waves @550nm)",
        type: :number,
        fun: fn %{"ratio" => ratio} ->
          c = 4 / ratio
          c * c * c * c * 0.81
        end,
        depends_on: ["ratio"]
      )

      val("target",
        description: "Target conic",
        type: :number,
        fun: fn %{"undercorrection" => under, "correction" => corr} -> -1 - under / corr end,
        depends_on: ["undercorrection", "correction"]
      )
    end
  end
end
