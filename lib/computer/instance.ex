defmodule Computer.Instance do
  alias Computer

  use GenServer

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  def handle_input(pid, name, value) do
    GenServer.call(pid, {:handle_input, name, value})
  end

  @impl true
  def handle_call({:handle_input, name, value}, _from, state) do
    updated = Computer.handle_input(state, name, value)
    {:reply, {:ok, updated.values}, updated}
  end
end
