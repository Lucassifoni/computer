defmodule Computer do
  alias Computer.Private
  alias Computer.Instance

  defstruct ~w(name inputs vals private values)a

  @doc """
  Creates a new computer with the given name.
  """
  def new(name) do
    %__MODULE__{
      name: name,
      inputs: [],
      vals: [],
      private: Computer.Private.new(),
      values: %{}
    }
  end

  @doc """
  Adds an input to the computer.
  """
  def add_input(computer, input) do
    computer
    |> Map.put(:inputs, [input | computer.inputs])
    |> Map.put(:private, Private.register_input(computer.private, input))
  end

  def make_instance(computer, options \\ []) do
    GenServer.start_link(Instance, computer, options)
  end

  @doc """
  Adds an val to the computer with dependencies.
  """
  def add_val(computer, val, depends_on) do
    dependency_list =
      case depends_on do
        a when is_list(a) -> a
        b -> [b]
      end

    updated_private =
      computer.private
      |> Private.register_val(val)

    updated_private =
      Enum.reduce(dependency_list, updated_private, fn d, up ->
        up |> Private.register_dependency(val.name, d)
      end)
      |> Private.refresh()

    computer
    |> Map.put(:vals, [val | computer.vals])
    |> Map.put(:private, updated_private)
    |> update_values()
  end

  defp update_values(computer) do
    %{
      computer
      | values: Private.get_values(computer.private)
    }
  end

  @doc """
  Handles an input update by setting the new value and computing any dependent vals.

  ## Parameters
    * `computer` - The computer struct to update
    * `input_name` - The name of the input being updated
    * `value` - The new value for the input

  Returns the updated computer with recalculated values.
  """
  def handle_input(computer, input_name, value) do
    updated_private =
      computer.private
      |> Private.update_input(input_name, value)
      |> Private.compute_dependents(input_name)

    %{
      computer
      | private: updated_private
    }
    |> update_values()
  end
end
