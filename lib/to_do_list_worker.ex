defmodule ToDoList.Worker do
  use GenServer

  @unmarked_task :unchecked
  @marked_task :checked

  def start_link(name) do
    GenServer.start_link(__MODULE__, { name }, name: name)
  end

  def init({ name }) do
    tasks = ToDoList.Items.Agent.get(name) || %{}
    { :ok, { name, tasks } }
  end

  def handle_cast({ :add_task, text }, { name, tasks }) do
    new_tasks = put_task({ UUID.uuid4(), @unmarked_task, text }, { name, tasks })
    { :noreply, { name, new_tasks } }
  end

  def handle_cast({ :mark_task, task_id }, { name, tasks }) do
    new_tasks = change_task_mark(task_id, @marked_task, { name, tasks })
    { :noreply, { name, new_tasks } }
  end

  def handle_cast({ :unmark_task, task_id }, { name, tasks }) do
    new_tasks = change_task_mark(task_id, @unmarked_task, { name, tasks })
    { :noreply, { name, new_tasks } }
  end

  def change_task_mark(task_id, mark, {name, tasks}) do
    { _, text } = get_task(task_id, tasks)
    put_task({ task_id, mark, text }, { name, tasks})
  end

  def put_task({ id, mark, text }, {name, tasks}) do
    new_tasks = Map.put(tasks, id, { mark, text })
    ToDoList.Items.Agent.put(name, new_tasks)
    new_tasks
  end

  def get_task(id, tasks) do
    Map.get(tasks, id)
  end

  def child_spec(name) do
    %{
      id: __MODULE__,
      start: { __MODULE__, :start_link, name }
    }
  end
end
