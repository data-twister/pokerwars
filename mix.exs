defmodule Pokerwars.Mixfile do
  use Mix.Project

  @default_version "1.0.0-default"
  @default_codename "Don Lemonparty"

  def project do
    [
      app: :pokerwars,
      version: version(),
      codename: codename(),
      elixir: "~> 1.8",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:mix_test_watch, "~> 0.5", only: :dev}
    ]
  end

  # Ensures `test/support/*.ex` files are read during tests
  def elixirc_paths(:test), do: ["lib"]
  def elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      # Ensures database is reset before tests are run
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  def version do
    # Build the version number from Git.
    # It will be something like 1.0.0-beta1 when built against a tag, and
    # 1.0.0-beta1+18.ga9f2f1ee when built against something after a tag.
    with {:ok, string} <- get_version(),
         [_, version, commit] <-
           Regex.run(~r/(v[\d\.]+(?:\-[a-zA-Z]+\d*)?)(.*)/, String.trim(string)) do
      String.replace(version, ~r/^v/, "") <>
        (commit |> String.replace(~r/^-/, "+") |> String.replace("-", "."))
    else
      _ ->
        @default_version
    end
  end

  def get_version do
    case File.read("VERSION") do
      {:error, _} ->
        case System.cmd("git", ["describe"]) do
          {string, 0} ->
            case string do
              "fatal: No names found, cannot describe anything." ->
                {:error, "Could not get version. error: No Tags Found"}

              _ ->
                {:ok, string}
            end

          {error, errno} ->
            {:error, "Could not get version. errno: #{inspect(errno)}, error: #{inspect(error)}"}
        end

      ok ->
        ok
    end
  end

  def codename do
    case File.read("CODENAME") do
      {:error, _} ->
        {status, version} = get_version()

        case status do
          :error ->
            @default_codename

          :ok ->
            result = String.split(version, "-")

            case Enum.count(result) do
              1 ->
                @default_codename

              _ ->
                {_, r} = Enum.fetch(result, 1)
                split = String.split(r, ".")
                List.first(split)
            end
        end

      {:ok, data} ->
        data
    end
  end
end
