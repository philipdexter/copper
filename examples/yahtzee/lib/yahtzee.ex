defmodule Yahtzee do
  @moduledoc """
  Documentation for Yahtzee.
  """

  def play_round() do
    play_round([])
  end
  defp play_round(saved_dice) do
    dice = Dice.roll(5-length(saved_dice))
    case react(saved_dice, dice, Player.decide(saved_dice++dice)) do
      {:continue, new_saved_dice} -> play_round(new_saved_dice)
      {:end, match} -> match
    end
  end

  defp react(saved_dice, rolled_dice, {:reroll, to_reroll}) do
    all_dice = saved_dice ++ rolled_dice
    new_saved_dice = Enum.map(Enum.filter(Enum.with_index(all_dice), fn {_die, idx} -> idx not in to_reroll end), fn {die, _idx} -> die end)
    {:continue, new_saved_dice}
  end
  defp react(_saved_dice, _rolled_dice, {:choose, match}) do
    # todo check if the dice really make the chosen match
    {:end, match}
  end
end
