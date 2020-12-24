defmodule LetsChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      LetsChat.Repo,
      # Start the Telemetry supervisor
      LetsChatWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LetsChat.PubSub},
      # Start the Endpoint (http/https)
      LetsChatWeb.Endpoint
      # Start a worker by calling: LetsChat.Worker.start_link(arg)
      # {LetsChat.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LetsChat.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LetsChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
