defmodule ToDoList.Items.Agent do
  use Agent

  def start_link(_init_arg) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def child_spec do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, [%{}] }
    }
  end

  def get(key) do
    Agent.get(__MODULE__, &Map.get(&1, key, %{}))
  end

  def put(key, value) do
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end
end
