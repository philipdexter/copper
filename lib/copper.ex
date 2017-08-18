defmodule Copper do
  def double(name \\ Test, options \\ []) do
    original_funcs = case Code.ensure_loaded(name) do
                       {:error, _} -> []
                       {:module, _} -> name.__info__(:functions)
                     end
    if Keyword.get(options, :partial, false) do
      Copper.Modules.create_a_copy(name, Module.concat(Backup, name))
    end
    %{name: name, funcs: [], original_funcs: original_funcs, options: options}
  end

  def add_handle(double, func, args, return) do
    %{double | funcs: [{func, args, return}|Map.get(double, :funcs)]}
  end

  def rename(double, new_name) do
    %{double | name: new_name}
  end

  def build(%{name: name, funcs: funcs, original_funcs: original_funcs, options: options}) do
    built_functions = Enum.map(funcs, &gen_function/1)
    code = module_from_functions(name, built_functions)
    Code.compile_quoted(code)
  end

  defp module_from_functions(name, built_functions) do
    {:defmodule, [context: Copper, import: Kernel],
     [
       {:__aliases__, [alias: false], [name]},
       [do:
        {:__block__, [],
         built_functions
        }
       ]
     ]
    }
  end

  def gen_function({func, args, return}) do
    quote do
      def unquote(func)(unquote_splicing(args)) do
        unquote(return)
      end
    end
  end

  defmacro __using__(_) do
    quote do
      require Copper
      require Copper.Macros
      alias Copper, as: C
      alias Copper.Macros, as: CM
    end
  end
end
