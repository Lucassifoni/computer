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
          depends_on: ["time", "distance"]
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

      input =
        Computer.Input.new(
          unquote(name),
          input_description,
          input_type,
          input_initial
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
        fun: fn %{"time" => time, "distance" => distance} -> time / distance end,
        depends_on: ["time", "distance"]
  """
  defmacro val(name, opts \\ []) do
    quote do
      val_type = Keyword.get(unquote(opts), :type)
      val_description = Keyword.get(unquote(opts), :description)
      val_fun = Keyword.get(unquote(opts), :fun)
      val_dependencies = Keyword.get(unquote(opts), :depends_on, [])

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

  # These macros are no longer needed since we're using keyword lists
  # but kept for backward compatibility

  @doc """
  Sets the type for an input.
  """
  defmacro type(type) do
    quote do
      var!(current_input_type) = unquote(type)
    end
  end

  @doc """
  Sets the description for an input or value.
  """
  defmacro description(description) do
    quote do
      var!(current_input_description) = unquote(description)
    end
  end

  @doc """
  Sets the initial value for an input.
  """
  defmacro initial(initial) do
    quote do
      var!(current_input_initial) = unquote(initial)
    end
  end

  @doc """
  Sets the computation function for a value.
  """
  defmacro fun(fun) do
    quote do
      var!(current_val_fun) = unquote(fun)
    end
  end

  @doc """
  Sets the dependencies for a value.
  """
  defmacro depends_on(dependencies) do
    quote do
      var!(current_val_dependencies) = unquote(dependencies)
    end
  end
end
