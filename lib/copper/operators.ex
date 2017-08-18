defmodule Copper.Operators do
  defmacro a ~> b do
    quote do
      case unquote(a) do
        {:ok, ok} -> unquote(b)(ok)
        {:error, error} -> {:error, error}
      end
    end
  end

  defmacro a ~>> b do
    quote do
      case unquote(a) ~> unquote(b) do
        {:ok, ok} -> ok
        {:error, error} -> {:error, error}
      end
    end
  end

  def give({:ok, ok}), do: ok
  def give({:error, error}), do: {:error, error}
end
