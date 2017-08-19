defmodule Yahtzee do
  @moduledoc """
  Documentation for Yahtzee.
  """

  def round() do
    dice = Dice.roll()
    Player.decide(dice)
  end

end
