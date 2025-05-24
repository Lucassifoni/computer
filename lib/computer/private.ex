defmodule Computer.Private do
  defstruct ~w(inputs vals funs dependencies names depended_ons depended_bys)a

  @doc """
  Creates a new private state with empty inputs, vals, dependencies and names.
  """
  def new() do
    %__MODULE__{
      inputs: %{},
      vals: %{},
      funs: %{},
      dependencies: [],
      names: %{},
      depended_ons: %{},
      depended_bys: %{}
    }
  end

  def update_input(private, input, value) do
    %__MODULE__{
      private
      | inputs: Map.put(private.inputs, input, value)
    }
  end

  @doc """
  Registers an input in the private state.
  """
  def register_input(private, input) do
    %__MODULE__{
      private
      | inputs: Map.put(private.inputs, input.name, input.initial_val),
        names: Map.put(private.names, input.name, :input)
    }
    |> compute_dependency_maps()
  end

  @doc """
  Retrieves all component values from the private state.

  Takes a private state and extracts all input and val values into a single map
  where keys are component names and values are their current values.

  Returns a map of all component names to their current values.
  """
  def get_values(private) do
    for {name, type} <- private.names do
      v =
        case type do
          :input -> private.inputs[name]
          :val -> private.vals[name]
        end

      {name, v}
    end
    |> Enum.into(%{})
  end

  @doc """
  Registers an val in the private state.
  """
  def register_val(private, val) do
    %__MODULE__{
      private
      | vals: Map.put(private.vals, val.name, nil),
        funs: Map.put(private.funs, val.name, val.fun),
        names: Map.put(private.names, val.name, :val)
    }
  end

  @doc """
  Registers a dependency between components.
  """
  def register_dependency(private, name, depends_on) do
    %__MODULE__{private | dependencies: [{name, depends_on} | private.dependencies]}
    |> compute_dependency_maps()
  end

  @doc """
  Computes the dependency graph for the computer's components.

  Takes a private state struct and processes its dependencies list to create two maps:
  - depended_bys: Maps components to lists of components that depend on them
  - depended_ons: Maps components to lists of components they depend on

  Returns updated private state with computed dependency maps.
  """
  def compute_dependency_maps(private) do
    dependency_list = private.dependencies

    depended_by_map =
      Enum.reduce(dependency_list, %{}, fn {name, d}, out ->
        case out[d] do
          nil -> Map.put(out, d, [name])
          a -> Map.put(out, d, [name | a])
        end
      end)

    depends_on_map =
      Enum.reduce(dependency_list, %{}, fn {name, d}, out ->
        case out[name] do
          nil -> Map.put(out, name, [d])
          a -> Map.put(out, name, [d | a])
        end
      end)

    %__MODULE__{private | depended_bys: depended_by_map, depended_ons: depends_on_map}
  end

  @doc """
  Recursively computes and updates all dependent values when an input changes.

  Takes a private state and a component name, finds all components that depend on it,
  computes their new values based on their dependencies, and recursively updates
  any components that depend on the updated components.

  Returns updated private state with all dependent values recomputed.
  """
  def compute_dependents(private, name, values) do
    dependents = private.depended_bys[name] || []

    with_updated_layer =
      Enum.reduce(dependents, private, fn dep, out ->
        deps = out.depended_ons[dep]
        args = Map.merge(Map.take(out.inputs, deps), Map.take(out.vals, deps))

        fun = out.funs[dep]

        res =
          case {values, :erlang.fun_info(fun)[:arity]} do
            {_, 1} -> fun.(args)
            {v, 2} -> fun.(args, v)
          end

        %{
          out
          | vals: Map.put(out.vals, dep, res)
        }
      end)

    Enum.reduce(dependents, with_updated_layer, fn dep, out ->
      compute_dependents(out, dep, values)
    end)
  end

  def refresh(private, values) do
    private.inputs
    |> Map.keys()
    |> Enum.reduce(private, fn input, acc ->
      compute_dependents(acc, input, values)
    end)
  end
end
