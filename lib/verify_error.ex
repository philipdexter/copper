defmodule Copper.VerifyError do
  defexception [:message]

  def exception(value) do
    msg = "got: #{value}"
    %Copper.VerifyError{message: msg}
  end
end
