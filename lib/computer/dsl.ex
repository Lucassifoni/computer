defmodule Computer.Dsl do
  @doc """
  Creates a new computer with a DSL.

  ## Examples

      computer "Pace computer" do
        input "time",
          type: :number,
          description: "Your running time in minutes",
          initial: 30

        input "distance",
          type: :number,
          description: "Your running distance in km",
          initial: 10

        val "pace",
          description: "Your running pace in minutes per km",
          type: :number,
          fun: fn %{"time" => time, "distance" => distance} -> time / distance end,
      end
  """
  defmacro computer(name, do: block) do
    quote do
      require Computer.Dsl

      computer = Computer.new(unquote(name))
      var!(current_computer) = computer

      unquote(block)

      var!(current_computer)
    end
  end

  @doc """
  Creates a new computer with a DSL.

  ## Examples

      stateful_computer "Pace computer" do
        input "time",
          type: :number,
          description: "Your running time in minutes",
          initial: 30

        input "distance",
          type: :number,
          description: "Your running distance in km",
          initial: 10

        val "pace",
          description: "Your running pace in minutes per km",
          type: :number,
          fun: fn %{"time" => time, "distance" => distance} -> time / distance end,
      end
  """
  defmacro stateful_computer(name, do: block) do
    quote do
      require Computer.Dsl

      computer = Computer.new_stateful(unquote(name))
      var!(current_computer) = computer

      unquote(block)

      var!(current_computer)
    end
  end

  @doc """
  Defines an input for a computer.

  ## Examples

      input "time",
        type: :number,
        description: "Your running time in minutes",
        initial: 30
  """
  defmacro input(name, opts \\ []) do
    quote do
      input_type = Keyword.get(unquote(opts), :type)
      input_description = Keyword.get(unquote(opts), :description)
      input_initial = Keyword.get(unquote(opts), :initial)
      input_options = Keyword.get(unquote(opts), :options)

      input =
        Computer.Input.new(
          unquote(name),
          input_description,
          input_type,
          input_initial,
          input_options
        )

      var!(current_computer) = Computer.add_input(var!(current_computer), input)
    end
  end

  @doc """
  Defines a computed value for a computer.

  ## Examples

      val "pace",
        description: "Your running pace in minutes per km",
        type: :number,
        fun: fn %{"time" => time, "distance" => distance} -> time / distance end
  """
  defmacro val(name, opts \\ []) do
    fun_ast = Keyword.get(opts, :fun)

    val_deps =
      case fun_ast do
        {:fn, _,
         [
           {:->, _,
            [
              [
                {:%{}, _, matches}
              ],
              _
            ]}
         ]} ->
          matches |> Enum.map(&elem(&1, 0))

        {:fn, _,
         [
           {:->, _,
            [
              [
                {:%{}, _, matches},
                _
              ],
              _
            ]}
         ]} ->
          matches |> Enum.map(&elem(&1, 0))

        _ ->
          :error
      end

    quote do
      val_type = Keyword.get(unquote(opts), :type)
      val_description = Keyword.get(unquote(opts), :description)
      val_fun = Keyword.get(unquote(opts), :fun)
      val_dependencies = unquote(val_deps)

      val =
        Computer.Val.new(
          unquote(name),
          val_description,
          val_type,
          val_fun
        )

      var!(current_computer) =
        Computer.add_val(
          var!(current_computer),
          val,
          val_dependencies
        )
    end
  end
end
