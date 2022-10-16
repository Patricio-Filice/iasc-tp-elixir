defmodule ToDoList.GeneralSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      ToDoList.Worker.Supervisor,
      ToDoList.Items.Agent,
      %{
        id: Registry,
        start: { Registry, :start_link, [:unique, :to_do_list_registry] }
      }
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end
