defmodule Computer.Val do
  defstruct ~w(name description type fun)a

  @doc """
  Creates a new val with the given name, description and type.
  """
  def new(name, description, type, fun) do
    %__MODULE__{
      name: name,
      description: description,
      type: type,
      fun: fun
    }
  end
end
