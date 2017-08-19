defmodule YahtzeeTest do
  use ExUnit.Case
  # doctest Yahtzee

  use Copper

  test "plays one round" do
    C.double(Dice)
    |> CM.give_multiple(roll(amt), [[1,2,3,4,1],[2],[5]])
    |> C.build()

    C.double(Player)
    |> CM.give_multiple(decide(dice), [{:reroll, [4]}, {:reroll, [4]}, {:choose, :smallstraight}])
    |> C.build()

    Yahtzee.play_round()

    CM.verify(Dice.roll(5))
    CM.verify(Dice.roll(1))
    CM.verify(Dice.roll(1))
    CM.verify(Player.decide([1,2,3,4,1]))
    CM.verify(Player.decide([1,2,3,4,2]))
    CM.verify(Player.decide([1,2,3,4,5]))
  end

end
