# todo matchers (digits, etc.)
# todo make 'unquote' below an option

defmodule Copper.Macros do
  defmacro give(double, {func, _, _}, {:fn, _, [{:->, _, [args, body]}]}) do
    quote do
      Copper.add_handle(unquote(double), unquote(func), unquote(Macro.escape(args)), unquote(Macro.escape(body, unquote: true)))
    end
  end

  defmacro give(double, {func, _, args}, return) do
    quote do
      Copper.add_handle(unquote(double), unquote(func), unquote(Macro.escape(args)), unquote(return))
    end
  end

  defmacro give_multiple(double, {func, _, args}, returns) do
    quote do
      Copper.add_special_handle(unquote(double), unquote(func), unquote(Macro.escape(args)), unquote({:multiple, returns}))
    end
  end

  defmacro verify({{:., _, [{:__aliases__, _, [module]}, func]}, _, args}) do
    quote do
      Copper.verify(unquote(module), unquote(func), unquote(args))
    end
  end
end
