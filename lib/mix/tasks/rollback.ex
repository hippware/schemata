defmodule Mix.Tasks.Schemata.Rollback do
  use Mix.Task
  import Mix.Schemata

  def run(_args, migrator \\ &Schemata.Migrator.run/3) do
    {:ok, _} = Application.ensure_all_started(:cqerl)
    opts = [log: true, n: 1]
    migrator.(migrations_path, :down, opts)
  end
end
