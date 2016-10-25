defmodule Schemata.App do
  @moduledoc ""

  use Application
  use Schemata.CQErl
  require Logger

  @cluster_defaults [
    username: 'cassandra',
    password: 'cassandra',
    seed_hosts: ['127.0.0.1']
  ]

  @keyspace_defaults [
    strategy: :simple,
    factor: 1,
    clients: 1
  ]

  def start(_type, _args) do
    :ok = configure_cqerl
    :ok = get_cluster |> configure_db
    Schemata.Supervisor.start_link()
  end

  @spec get_cluster :: Keyword.t
  def get_cluster do
    cluster = Application.fetch_env!(:schemata, :cluster)
    Keyword.merge(@cluster_defaults, cluster)
  end

  @spec get_keyspace(atom) :: {:ok, Keyword.t} | {:error, :unknown_keyspace}
  def get_keyspace(ks) do
    Enum.reduce_while(
      get_cluster[:keyspaces],
      {:error, :unknown_keyspace},
      fn ^ks, _ -> {:halt, {:ok, ks_config([])}}
         {^ks, config}, _ -> {:halt, {:ok, ks_config(config)}}
         _, acc -> {:cont, acc}
      end
    )
  end

  defp ks_config(config), do: Keyword.merge(@keyspace_defaults, config)

  defp configure_cqerl do
    # Set a few things that we depend on in cqerl
    Application.put_env(:cqerl, :maps, true, persistent: true)
    Application.put_env(:cqerl, :mode, :hash, persistent: true)
    Application.put_env(:cqerl, :text_uuids, true, persistent: true)
  end

  defp configure_db(cluster) do
    :ok = Logger.debug("Starting cqerl clients")
    {hosts, opts} = extract_defaults(cluster)
    _ = start_default_client(hosts, opts)
    _ = start_keyspace_clients(hosts, opts, cluster[:keyspaces])
    :ok
  end

  defp extract_defaults(cluster) do
    opts = [
      auth: {:cqerl_auth_plain_handler, [
        {cluster[:username], cluster[:password]}
      ]}
    ]
    {cluster[:seed_hosts], opts}
  end

  defp start_default_client(hosts, opts) do
    :ok = Logger.debug("Starting default client")
    CQErl.add_group(hosts, opts, 1)
  end

  defp start_keyspace_clients(hosts, opts, keyspaces) do
    for ks <- keyspaces, do: start_keyspace_client(hosts, opts, ks)
  end

  defp start_keyspace_client(hosts, opts, {name, config}) do
    :ok = Logger.debug("Starting client for keyspace #{name}")
    config = ks_config(config)

    ensure_keyspace!(name, config)
    opts = Keyword.put(opts, :keyspace, name)
    CQErl.add_group(hosts, opts, config[:clients])
  end
  defp start_keyspace_client(hosts, opts, name),
    do: start_keyspace_client(hosts, opts, {name, []})

  defp ensure_keyspace!(name, config) do
    Schemata.create_keyspace name,
      strategy: config[:strategy],
      factor: config[:factor]
  end
end
