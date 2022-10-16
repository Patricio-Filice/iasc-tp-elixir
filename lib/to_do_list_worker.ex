defmodule ToDoList.Worker do
  use GenServer

  @unmarked_task :unchecked
  @marked_task :checked
  @to_do_list_registry :to_do_list_registry

  def start_link(name) do
    GenServer.start_link(__MODULE__, { name }, name: via_tuple(name))
  end

  @impl true
  def init({ name }) do
    { :ok, { name } }
  end

  @impl true
  def handle_cast({ :mark_task, task_id }, { name }) do
    change_task_mark(task_id, @marked_task, { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :unmark_task, task_id }, { name }) do
    change_task_mark(task_id, @unmarked_task, { name })
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :edit_task, task_id, text }, { name }) do
    on_found = fn task ->
      put_task({ name, elem(task, 0), text }, { name })
      { :noreply, { name } }
    end
    do_action_on_task(name, task_id, on_found)
  end

  @impl true
  def handle_cast({ :remove_task, task_id }, { name }) do
    new_tasks = Map.delete(ToDoList.Items.Agent.get(name), task_id)
    ToDoList.Items.Agent.put(name, new_tasks)
    { :noreply, { name } }
  end

  @impl true
  def handle_cast({ :swap_task, to_list, task_id }, { name }) do
    to_list_pid = ToDoList.where_is(to_list)
    on_found = fn (task) ->
      GenServer.call(to_list_pid, { :add_task, elem(task, 0), elem(task, 1) })
      handle_cast({ :remove_task, task_id }, { name })
    end
    do_action_on_task(name, task_id, on_found)
  end

  @impl true
  def handle_call({ :add_task, mark, text }, _from, { name }) do
    id = UUID.uuid4()
    put_task({ id, mark, text }, { name })
    { :reply, id, { name } }
  end

  @impl true
  def handle_call(:list_tasks, _from, { name }) do
    { :reply, ToDoList.Items.Agent.get(name), { name } }
  end

  def change_task_mark(task_id, mark, { name }) do
    on_found = fn task ->
      put_task({ task_id, mark, elem(task, 1) }, { name })
    end
    do_action_on_task(name, task_id, on_found)
  end

  def put_task({ id, mark, text }, { name }) do
    tasks_map = ToDoList.Items.Agent.get(name)
    new_tasks = Map.put(tasks_map, id, { mark, text })
    ToDoList.Items.Agent.put(name, new_tasks)
  end

  def do_action_on_task(name, id, on_found) do
    tasks_map = ToDoList.Items.Agent.get(name)
    task = Map.get(tasks_map, id)
    case task do
      nil -> { :task_not_found, "The requested task couldn't be found" }
      _ ->  on_found.(task)
    end
  end

  def child_spec(name) do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, name }
    }
  end

  defp via_tuple(name), do: { :via, Registry, { @to_do_list_registry, name } }
end
