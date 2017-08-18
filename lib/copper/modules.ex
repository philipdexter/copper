defmodule Copper.Modules do

  def create_a_copy(module, newname) do
    get_binary(module)
    |> get_chunks
    |> rename_module(newname)
    |> compile_and_load
  end

  def get_binary(module) do
    case :code.get_object_code(module) do
      {_, binary, _} -> binary
      # :error -> error, are you trying to mock a mock?
    end
  end

  def get_chunks(binary) do
      case :beam_lib.chunks(binary, [:abstract_code]) do
	  {:ok, {_, [{:abstract_code, {:raw_abstract_v1, forms}}]}} -> forms
      end
  end

  def compile_and_load(chunks) do
    case :compile.forms(chunks, [:return_errors]) do
      {:ok, modname, binary} ->
        :code.load_binary(modname, [], binary);
      {:ok, modname, binary, _Warnings} ->
        :code.load_binary(modname, [], binary)
    end
  end

  def rename_module([{:attribute, line, :module, oldattribute}|t], newname) do
    case oldattribute do
      {_oldname, variables} ->
        [{:attribute, line, :module, {newname, variables}}|t]
      _oldname ->
        [{:attribute, line, :module, newname}|t]
    end
  end
  def rename_module([h|t], newname) do
    [h|rename_module(t, newname)]
  end

end
