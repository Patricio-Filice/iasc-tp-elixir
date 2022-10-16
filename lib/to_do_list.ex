
defmodule ToDoList do
  use Application

  @unmarked_task :unchecked
  @to_do_list_registry :to_do_list_registry

  def start(_type, _args) do
    ToDoList.GeneralSupervisor.start_link()
  end

  def where_is(list_name) do
    case Registry.lookup(@to_do_list_registry, list_name) do
      [{ pid, _ }] -> pid
      [] -> { :to_do_list_not_found, "The requested list couldn't be found" }
    end
  end

  def all() do
    Registry.select(@to_do_list_registry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end

  def create(name) do
    ToDoList.Worker.Supervisor.start_child(name)
  end

  def add_task(list, text) do
    GenServer.call(ToDoList.where_is(list), { :add_task, @unmarked_task, text })
  end

  def mark_task(list, task_id) do
    GenServer.cast(ToDoList.where_is(list), { :mark_task,  task_id })
  end

  def unmark_task(list, task_id) do
    GenServer.cast(ToDoList.where_is(list), { :unmark_task,  task_id })
  end

  def edit_task(list, task_id, text) do
    GenServer.cast(ToDoList.where_is(list), { :edit_task, task_id, text })
  end

  def remove_task(list, task_id) do
    GenServer.cast(ToDoList.where_is(list), { :remove_task, task_id })
  end

  def swap_task(from_list, to_list, task_id) do
    GenServer.cast(ToDoList.where_is(from_list), { :swap_task, to_list, task_id })
  end

  def get_task(list, task_id) do
    GenServer.call(ToDoList.where_is(list), { :get_task, task_id })
  end

  def list_tasks(list) do
    GenServer.call(ToDoList.where_is(list), :list_tasks)
  end
end
