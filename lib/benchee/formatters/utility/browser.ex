defmodule Benchee.Formatters.Utility.Browser do
  @moduledoc """
    Utility for starting default system browser.
  """

  @doc """
    Opens default system browser for given url.

    ## Examples
      iex> Benchee.Utils.Browser.open("https://github.com/PragTob/benchee_html")
      {"", 0}
  """
  def open(url) do
    start_browser(:os.type, url)
  end

  defp start_browser({:win32, _}, url), do: System.cmd("cmd", ["/c", "start", url])
  defp start_browser({:unix, :darwin}, url), do: System.cmd("open", [url])
  defp start_browser({:unix, _}, url), do: System.cmd("xdg-open", [url])
end
