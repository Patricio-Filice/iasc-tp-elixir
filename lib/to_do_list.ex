
defmodule ToDoList do
  use Application

  def start(_type, _args) do
    ToDoList.GeneralSupervisor.start_link()
  end

  def create_list(name) do
    ToDoList.Worker.Supervisor.start_child(name)
  end

  def add_task(list, text) do
    GenServer.cast(list, { :add_task,  text })
  end

  def mark_task(list, task_id) do
    GenServer.cast(list, { :mark_task,  task_id })
  end

  def unmark_task(list, task_id) do
    GenServer.cast(list, { :unmark_task,  task_id })
  end
end
