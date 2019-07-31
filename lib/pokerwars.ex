defmodule Pokerwars do
  @moduledoc """
  Documentation for Pokerwars.
  """

  @version Mix.Project.config()[:version]
  @codename Mix.Project.config()[:codename]


  def codename, do: @codename
  def version, do: @version

end
