defmodule ExSni.IconRegistration do
  use GenServer

  def start_link(opts, gen_opts \\ []) do
    GenServer.start_link(__MODULE__, opts, gen_opts)
  end

  def init(opts) do
    service_name = Keyword.get(opts, :service_name, nil)

    case Process.whereis(:dbus_icon_service) do
      service when is_pid(service) -> register_icon(service, service_name)
      nil -> {:stop, ":icon_service is not running"}
    end
  end

  defp register_icon(service, service_name) do
    service
    |> GenServer.call({
      :call_method,
      "org.kde.StatusNotifierWatcher",
      "/StatusNotifierWatcher",
      "org.kde.StatusNotifierWatcher",
      "RegisterStatusNotifierItem",
      {"s", [:string], [service_name]}
    })
    |> case do
      {:ok, pid} -> {:ok, pid}
      {:error, error} -> {:stop, error}
      _ -> {:stop, "RegisterStatusNotifierItem failed for \"#{service_name}\" "}
    end
  end
end
