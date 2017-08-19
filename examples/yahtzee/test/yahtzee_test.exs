defmodule YahtzeeTest do
  use ExUnit.Case
  # doctest Yahtzee

  use Copper

  test "plays one round" do
    C.double(Dice)
    |> CM.give(roll(), [1,2,3,4,5])
    |> C.build()

    C.double(Player)
    |> CM.give(decide(dice), {:choose, :smallstraight})
    |> C.build()

    Yahtzee.round()

    CM.verify(Dice.roll())
    CM.verify(Player.decide([1,2,3,4,5]))
  end

end
