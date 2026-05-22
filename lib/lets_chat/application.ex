defmodule LetsChat.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias LiveVue.SSR.QuickBEAM

  @impl true
  def start(_type, _args) do
    children = [
      LetsChatWeb.Telemetry,
      LetsChat.Repo,
      {DNSCluster, query: Application.get_env(:lets_chat, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: LetsChat.PubSub},
      # Start a worker by calling: LetsChat.Worker.start_link(arg)
      # {LetsChat.Worker, arg},
      # Start to serve requests, typically the last entry
      LetsChatWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :lets_chat]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LetsChat.Supervisor]

    children =
      children ++
        if(Application.get_env(:live_vue, :ssr_module) == QuickBEAM,
          do: [QuickBEAM],
          else: []
        )

    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    LetsChatWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
