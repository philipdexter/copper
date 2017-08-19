# todo matchers (digits, etc.)

defmodule Copper.Macros do
  defmacro give(double, {func, _, _}, {:fn, _, [{:->, _, [args, body]}]}) do
    quote do
      Copper.add_handle(unquote(double), unquote(Macro.escape(func)), unquote(Macro.escape(args)), unquote(Macro.escape(body)))
    end
  end

  defmacro give(double, {func, _, args}, return) do
    quote do
      Copper.add_handle(unquote(double), unquote(func), unquote(args), unquote(return))
    end
  end

  defmacro verify({{:., _, [{:__aliases__, _, [module]}, func]}, _, args}) do
    quote do
      Copper.verify(unquote(module), unquote(func), unquote(args))
    end
  end
end
