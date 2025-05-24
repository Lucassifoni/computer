defmodule Computer do
  @moduledoc """
  A module for creating and managing computer instances with inputs, values, and dependencies.

  This module provides functionality to create computers, add inputs and values with dependencies,
  handle input updates, and create stateful instances.
  """

  alias Computer.Private
  alias Computer.Instance

  defstruct ~w(name inputs vals private values log pending stateful)a

  @doc """
  Creates a new computer with the given name.

  ## Parameters
    * `name` - The name for the new computer

  ## Returns
    A new Computer struct with initialized fields
  """
  def new(name) do
    %__MODULE__{
      name: name,
      inputs: [],
      vals: [],
      private: Computer.Private.new(),
      values: %{},
      pending: nil,
      log: [],
      stateful: false
    }
  end

  def new_stateful(name) do
    %__MODULE__{
      name: name,
      inputs: [],
      vals: [],
      private: Computer.Private.new(),
      values: %{},
      pending: nil,
      log: [],
      stateful: true
    }
  end

  @doc """
  Replays a log of events on a computer to recreate its state.

  ## Parameters
    * `computer` - The computer to replay events on
    * `log` - A list of events to replay

  ## Returns
    A computer with the state after all events have been applied
  """
  def replay(computer, log) do
    log
    |> Enum.reverse()
    |> Enum.reduce(new(computer.name), fn event, cpu ->
      register(cpu, event)
    end)
  end

  defp log(computer, event) do
    %{
      computer
      | pending: nil,
        log: [event | computer.log]
    }
  end

  defp register(computer, ev) do
    Map.put(computer, :pending, ev) |> process
  end

  defp with_log(computer, event, fun) do
    computer
    |> log(event)
    |> then(fun)
  end

  defp process(%{pending: {:add_input, input} = ev} = computer),
    do: with_log(computer, ev, fn c -> do_add_input(c, input) end)

  defp process(%{pending: {:add_val, val, deps} = ev} = computer),
    do: with_log(computer, ev, fn c -> do_add_val(c, val, deps) end)

  defp process(%{pending: {:input, input_name, value} = ev} = computer),
    do: with_log(computer, ev, fn c -> do_handle_input(c, input_name, value) end)

  defp do_add_input(computer, input) do
    computer
    |> Map.put(:inputs, [input | computer.inputs])
    |> Map.put(:private, Private.register_input(computer.private, input))
  end

  defp prev(computer) do
    if computer.stateful, do: computer.values, else: nil
  end

  defp do_add_val(computer, val, depends_on) do
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
      |> Private.refresh(prev(computer))

    computer
    |> Map.put(:vals, [val | computer.vals])
    |> Map.put(:private, updated_private)
    |> update_values()
  end

  defp do_handle_input(computer, input_name, value) do
    updated_private =
      computer.private
      |> Private.update_input(input_name, value)
      |> Private.compute_dependents(input_name, prev(computer))

    %{
      computer
      | private: updated_private
    }
    |> update_values()
  end

  @doc """
  Adds an input to the computer.

  ## Parameters
    * `computer` - The computer to add the input to
    * `input` - The input to add

  ## Returns
    The updated computer with the new input
  """
  def add_input(computer, input), do: computer |> register({:add_input, input})

  @doc """
  Adds a val to the computer with dependencies.

  ## Parameters
    * `computer` - The computer to add the val to
    * `val` - The val to add
    * `depends_on` - A single dependency or list of dependencies

  ## Returns
    The updated computer with the new val and its dependencies
  """
  def add_val(computer, val, depends_on),
    do: computer |> register({:add_val, val, depends_on})

  @doc """
  Creates a GenServer instance of the computer.

  ## Parameters
    * `computer` - The computer to create an instance of
    * `options` - Options to pass to GenServer.start_link/3

  ## Returns
    The result of GenServer.start_link/3
  """
  def make_instance(computer, options \\ []) do
    GenServer.start_link(Instance, computer, options)
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

  ## Returns
    The updated computer with recalculated values.
  """
  def handle_input(computer, input_name, value),
    do: computer |> register({:input, input_name, value})
end
