defmodule VDF.MixProject do
  use Mix.Project

  def project do
    [
      app: :vdf,
      version: "1.0.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: []
    ]
  end

  def application, do: []
end
