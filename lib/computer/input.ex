defmodule Computer.Input do
  defstruct ~w(name description type initial_val options)a

  @doc """
  Creates a new input with the given name, description, type and initial value.
  """
  def new(name, description, type, initial_val, options \\ []) do
    %__MODULE__{
      name: name,
      description: description,
      type: type,
      initial_val: initial_val,
      options: options
    }
  end
end
