defmodule Copper do
  import Copper.Operators

  def double(name \\ Test, options \\ []) do
    %{name: name, funcs: [], options: options, partial: false}
    |> handle_partiality
    |> give
  end

  def handle_partiality(%{name: name, options: options} = double) do
    case Keyword.get(options, :partial, false) do
      false ->
        {:ok, double}
      true ->
        case Code.ensure_loaded(name) do
          {:error, _} ->
            {:error, "module #{name} is not loaded"}
          {:module, _} ->
            existing_funcs = name.__info__(:functions)
            backup_name = Module.concat(Backup, name)

            # backup original
            # todo: extract this to a function
            Copper.Modules.create_a_copy(name, backup_name)

            {:ok, %{double | partial: {backup_name, existing_funcs}}}
        end
    end
  end

  def add_handle(double, func, args, return) do
    %{double | funcs: [{func, args, return}|Map.get(double, :funcs)]}
  end

  def rename(double, new_name) do
    %{double | name: new_name}
  end

  def build(%{name: name, funcs: funcs, partial: partial, options: options}) do

    # create the mock (router)
    {:ok, pid} = Copper.Mock.start_link(name)
    IO.inspect pid

    built_functions = Enum.map(funcs, &gen_function/1)
    router_functions = Enum.map(funcs, &gen_router_function(pid, &1))

    all_functions = built_functions ++ router_functions

    code = module_from_functions(name, all_functions)
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
      def unquote(:"#{func}_func")(unquote_splicing(args)) do
        unquote(return)
      end
    end
  end

  def gen_router_function(pid, {func, args, _return}) do
    quote do
      def unquote(func)(unquote_splicing(args)) do
        GenServer.call(unquote(pid), {:call, unquote(func), unquote(args)})
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
