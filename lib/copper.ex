# todo verify
# todo restore old module

defmodule Copper do
  def double(name \\ Test, options \\ []) do
    %{name: name, funcs: [], special_funcs: [], options: options, partial: false}
    |> handle_partiality
    |> (fn {:ok, ok} -> ok
           other     -> other end).()
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
            partial_funcs = name.__info__(:functions)
            backup_name = Module.concat(Backup, name)

            # backup original
            Copper.Modules.create_a_copy(name, backup_name)

            {:ok, %{double | partial: {backup_name, partial_funcs}}}
        end
    end
  end

  def add_handle(double, func, args, return) do
    %{double | funcs: [{func, args, return}|Map.get(double, :funcs)]}
  end

  def add_special_handle(double, func, args, {:multiple, returns}) do
    %{double | special_funcs: [{func, args, {:multiple, returns}}|Map.get(double, :special_funcs)]}
  end

  def rename(double, new_name) do
    %{double | name: new_name}
  end

  def build(%{name: name, funcs: funcs, special_funcs: special_funcs, partial: partial, options: options}) do
    with {:ok, pid} <- create_mock_process(name, special_funcs) do
      built_functions = Enum.map(funcs++special_funcs, &gen_function/1)
      router_functions = Enum.map(funcs++special_funcs, &gen_router_function(pid, &1))
      # todo partial functions should also be spied upon
      # so create router functions for them
      partial_functions = case partial do
                            false ->
                              []
                            {backup_name, partial_funcs} ->
                              Enum.map(partial_funcs, &gen_partial_function(backup_name, &1))
                          end

      all_functions = built_functions ++ router_functions ++ partial_functions

      code = module_from_functions(name, all_functions)
      Code.compile_quoted(code)

      {name, pid}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp create_mock_process(name, special_funcs) do
    case Process.whereis(:"#{name}_proc") do
      nil ->
        Copper.Mock.start_link(name, special_funcs)
      _pid ->
        {:error, "mock process exists, already mocked?"}
    end
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

  def gen_function({func, args, {:multiple, _returns}}) do
    quote do
      def unquote(:"#{func}_func")(unquote_splicing(args)) do
        raise "calling multiple returning function, call the original to get correct behavior"
      end
    end
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

  def gen_partial_function(backup_name, {func, arg_count}) do
    quote do
      defdelegate unquote(func)(unquote_splicing(Macro.generate_arguments(arg_count, nil))), to: unquote(backup_name)
    end
  end

  def verify(module, func, args) do
    case Process.whereis(:'Elixir.#{module}_proc') do
      nil ->
        {:error, "error, mock process for module #{module} does not exist"}
      pid ->
        calls = GenServer.call(pid, {:callstats, func})
        case Enum.member?(calls, args) do
          true -> :ok
          # todo stop args from showing up as an array
          false -> {:error, "can not verify call #{module}.#{func}(#{inspect(args)})"}
        end
    end
    |> (fn :ok -> :ok
           {:error, message} -> raise Copper.VerifyError, message end).()
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
