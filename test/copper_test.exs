defmodule CopperTest do
  use ExUnit.Case
  # doctest Copper

  use Copper

  test "mocks a dog" do
    {Dog, pid} =
      C.double(Dog)
      |> CM.give(walk, fn -> "walking!" end)
      |> CM.give(bark(), "ruff")
      |> CM.give(count(a), a+1)
      |> C.build

    assert Dog.walk() == "walking!"
    assert Dog.bark() == "ruff"
    assert Dog.count(1) == 2
    assert GenServer.call(pid, {:callcount, :walk}) == 1
    assert GenServer.call(pid, {:callcount, :bark}) == 1
    assert GenServer.call(pid, {:callcount, :count}) == 1

    CM.verify(Dog.walk())
    CM.verify(Dog.bark())
    CM.verify(Dog.count(1))
  end

end
