defmodule Computer.Output do
  defstruct ~w(name description type intermediate fun)a

  @doc """
  Creates a new output with the given name, description and type.
  """
  def new(name, description, type, intermediate, fun) do
    %__MODULE__{
      name: name,
      description: description,
      type: type,
      intermediate: intermediate,
      fun: fun
    }
  end
end
