defmodule ExVim.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Ratatouille.Runtime.Supervisor, runtime: [app: ExVim.App]}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: ExVim.Supervisor
    )
  end
end
