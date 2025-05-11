# Computer

Declarative dependency-free reactive computations. Not bound to liveview or any specific framework.<br/>
Goal is a spreadsheet-like experience and view helpers / event ingestion helpers to quickly spin up UIs for internal calculator tools.

## Usage

### 1 : define a computer

```elixir
import Computer.Dsl
pace_cpu = computer "Pace computer" do
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
```

### 2 : update its inputs

```elixir
pace_cpu = Computer.handle_input(pace_cpu, "time", 40)
```

### 3 : read back values

```elixir
> pace_cpu.values["pace"]
> 4.0
```

### 4 : manage it yourself through a process, or spawn a Computer.Instance
```elixir
pace_cpu = Computer.Samples.Pace.sample()
{:ok, pid} = Computer.make_instance(pace_cpu)
{:ok, values} = Computer.Instance.handle_input(pid, "time", 40)
assert values["pace"] == 4.0
```

## Samples

```elixir
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
```
