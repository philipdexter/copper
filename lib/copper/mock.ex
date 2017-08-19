defmodule Copper.Mock do
  use GenServer

  def start_link(mocking_module, special_funcs) do
    GenServer.start_link(__MODULE__, %{mocking: mocking_module, calls: %{}, special_funcs: special_funcs}, name: :"#{mocking_module}_proc")
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def handle_call({:call, func, args}, _from, %{mocking: module, calls: calls, special_funcs: special_funcs} = state) do
    case Enum.find(special_funcs, fn {name, _, _} -> name == func end) do
      nil ->
        res = apply(module, :"#{func}_func", args)
        updated_calls = Map.update(calls, func, [args], fn tl -> [args|tl] end)
        {:reply, res, %{state | calls: updated_calls}}
      {func, args, {:multiple, []}} ->
        updated_calls = Map.update(calls, func, [args], fn tl -> [args|tl] end)
        {:reply, nil, %{state | calls: updated_calls}}
      {func, _args, {:multiple, [res|returns]}} ->
        new_special_funcs = Enum.map(special_funcs, fn {^func, args, _} -> {func, args, {:multiple, returns}}
                                                       otherwise        -> otherwise end)
        updated_calls = Map.update(calls, func, [args], fn tl -> [args|tl] end)
        {:reply, res, %{state | special_funcs: new_special_funcs, calls: updated_calls}}
    end
  end
  def handle_call(:callstats, _from, %{calls: calls} = state) do
    {:reply, calls, state}
  end
  def handle_call({:callstats, func}, _from, %{calls: calls} = state) do
    func_calls = Map.get(calls, func, [])
    {:reply, func_calls, state}
  end
  def handle_call({:callcount, func}, _from, %{calls: calls} = state) do
    call_count =
      calls
      |> Map.get(func, [])
      |> length
    {:reply, call_count, state}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

end
