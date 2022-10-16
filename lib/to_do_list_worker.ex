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
    {:via, Registry, {@to_do_list_registry, name}}
    tasks = ToDoList.Items.Agent.get(name) || %{}
    { :ok, { name, tasks } }
  end

  @impl true
  def handle_cast({ :mark_task, task_id }, { name, tasks }) do
    new_tasks = change_task_mark(task_id, @marked_task, { name, tasks })
    { :noreply, { name, new_tasks } }
  end

  @impl true
  def handle_cast({ :unmark_task, task_id }, { name, tasks }) do
    new_tasks = change_task_mark(task_id, @unmarked_task, { name, tasks })
    { :noreply, { name, new_tasks } }
  end

  @impl true
  def handle_cast({ :edit_task, task_id, text }, { name, tasks }) do
    on_found = fn task ->
      new_tasks = put_task({ task_id, elem(task, 0), text }, { name, tasks })
      { :noreply, { name, new_tasks } }
    end
    do_action_on_task(tasks, task_id, on_found)
  end

  @impl true
  def handle_cast({ :remove_task, task_id }, { name, tasks }) do
    new_tasks = Map.delete(tasks, task_id)
    ToDoList.Items.Agent.put(name, new_tasks)
    { :noreply, { name, new_tasks } }
  end

  @impl true
  def handle_cast({ :swap_task, to_list, task_id }, { name, tasks }) do
    to_list_pid = ToDoList.where_is(to_list)
    on_found = fn (task) ->
      GenServer.call(to_list_pid, { :add_task, elem(task, 0), elem(task, 1) })
      handle_cast({ :remove_task, task_id }, {name, tasks})
    end
    do_action_on_task(tasks, task_id, on_found)
  end

  @impl true
  def handle_call({ :add_task, mark, text }, _from, { name, tasks }) do
    id = UUID.uuid4()
    new_tasks = put_task({ id, mark, text }, { name, tasks })
    { :reply, id, { name, new_tasks } }
  end

  @impl true
  def handle_call({ :get_task, task_id }, _from, { name, tasks }) do
    { :reply, Map.get(tasks, task_id), { name, tasks } }
  end

  @impl true
  def handle_call(:list_tasks, _from, { name, tasks }) do
    { :reply, tasks, { name, tasks } }
  end

  def change_task_mark(task_id, mark, {name, tasks}) do
    on_found = fn task ->
      put_task({ task_id, mark, elem(task, 1) }, { name, tasks})
    end
    do_action_on_task(tasks, task_id, on_found)
  end

  def put_task({ id, mark, text }, {name, tasks}) do
    new_tasks = Map.put(tasks, id, { mark, text })
    ToDoList.Items.Agent.put(name, new_tasks)
    new_tasks
  end

  def do_action_on_task(tasks, id, on_found) do
    task = Map.get(tasks, id)
    case task do
      nil -> tasks
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
