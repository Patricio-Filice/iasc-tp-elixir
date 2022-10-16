defmodule ToDoList.Worker.Supervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end


  def child_spec do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link }
    }
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(name) do
    toDoListWorkerSpec = { ToDoList.Worker, [name] }
    DynamicSupervisor.start_child(__MODULE__, toDoListWorkerSpec)
  end
end
