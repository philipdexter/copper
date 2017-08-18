defmodule Copper.Mock do
  use GenServer

  def start_link(mocking_module) do
    GenServer.start_link(__MODULE__, %{mocking: mocking_module, calls: %{}}, name: :"#{mocking_module}_proc")
  end

  def stop(pid) do
    GenServer.cast(pid, :stop)
  end

  def handle_call({:call, func, args}, _from, %{mocking: module, calls: calls} = state) do
    res = apply(module, :"#{func}_func", args)
    updated_calls = Map.update(calls, func, [args], fn tl -> [args|tl] end)
    {:reply, res, %{state | calls: updated_calls}}
  end
  def handle_call(:fullstats, _from, %{calls: calls} = state) do
    {:reply, calls, state}
  end
  def handle_call({:fullstats, func}, _from, %{calls: calls} = state) do
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
