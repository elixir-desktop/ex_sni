defmodule ExSni.MixProject do
  use Mix.Project

  @source_url "https://github.com/elixir-desktop/ex_sni"

  def project do
    [
      app: :ex_sni,
      name: "ExSNI",
      source_url: @source_url,
      version: "0.2.4",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: "Elixir implementation of D-Bus StatusNotifierItem and com.canonical.dbusmenu",
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "examples"]
  defp elixirc_paths(:test), do: ["lib", "examples", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_dbus, "~> 0.1.1"},
      {:xdiff_plus, "~> 0.1"},

      # XML utility - ex_dbus already requires it
      {:saxy, "~> 1.4.0"},

      # Development dialyzer
      {:dialyxir, "~> 1.1.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
    ]
  end

  def package do
    [
      name: :ex_sni,
      files: ~w(lib LICENSE mix.exs README.md),
      maintainers: ["Mihai Potra"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end
end
