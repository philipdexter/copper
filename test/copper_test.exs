defmodule CopperTest do
  use ExUnit.Case
  # doctest Copper

  use Copper

  test "mocks a dog" do
    {Dog, pid} =
      C.double(Dog)
      |> CM.give(walk, fn -> "walking!" end)
      |> CM.give(bark(), "ruff")
      |> CM.give(count, fn a -> a + 1 end)
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

  test "mocks game of life" do
    world1 = :world1
    world2 = :world2

    {BoardReplacer, _} =
      C.double(BoardReplacer)
      |> CM.give(first_world(), world1)
      |> CM.give(next_world(world), world2)
      |> C.build

    {Simulator, _} =
      C.double(Simulator)
      |> CM.give(one_round, fn -> BoardReplacer.next_world(BoardReplacer.first_world()) end)
      |> C.build

    assert BoardReplacer.first_world() == world1
    assert BoardReplacer.next_world(:blah) == world2

    assert Simulator.one_round() == world2

    CM.verify(BoardReplacer.first_world())
    CM.verify(BoardReplacer.next_world(world1))
  end
end
