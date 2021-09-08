defmodule ExSni do
  alias ExDBus.Bus
  alias ExSni.{Icon, Menu}

  def start_link(opts \\ []) do
    with {:ok, service_name} <- get_required_name(opts),
         {:ok, icon} <- get_required_icon(opts),
         {:ok, menu} <- get_optional_menu(opts),
         router <- %ExSni.Router{icon: icon, menu: menu},
         {:ok, supervisor_pid} <- start_supervisor(service_name, router) do
      {:ok, supervisor_pid}
    end
  end

  @doc """
  Returns true if there is a StatusNotifierWatcher available
  on the Session Bus.
  """
  @spec is_supported?() :: boolean()
  def is_supported?() do
    with {:ok, bus} <- Bus.start_link(:session),
         :ok <- Bus.connect(bus) do
      result = is_supported?(bus)
      Bus.close(bus)
      result
    else
      _ ->
        false
    end
  end

  @doc """
  Returns true if there is a StatusNotifierWatcher available
  on the Session Bus.
  - bus_pid - The pid of the ExDBus.Bus GenServer
  """
  @spec is_supported?(pid()) :: boolean()
  def is_supported?(bus_pid) do
    if Bus.name_has_owner(bus_pid, "org.kde.StatusNotifierWatcher") do
      Bus.has_interface?(
        bus_pid,
        "org.kde.StatusNotifierWatcher",
        "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher"
      )
    else
      false
    end
  end

  defp start_supervisor(service_name, router) do
    children = [
      %{
        id: ExDBus.Service,
        start:
          {ExDBus.Service, :start_link,
           [
             [name: service_name, schema: ExSni.IconSchema, router: router],
             [name: :dbus_icon_service]
           ]},
        restart: :transient
      },
      %{
        id: ExSni.IconRegistration,
        start:
          {ExSni.IconRegistration, :start_link,
           [[service_name: service_name], [name: :dbus_icon_registration]]},
        restart: :transient
      }
    ]

    case Supervisor.start_link(children, strategy: :rest_for_one) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, error} -> {:stop, error}
    end
  end

  defp get_required_name(opts) when is_list(opts) do
    version = Keyword.get(opts, :version, 1)

    case Keyword.get(opts, :name, nil) do
      nil -> {:stop, "No DBus service name given"}
      "" -> {:stop, "DBus service name cannot be empty"}
      name when is_binary(name) -> {:ok, "#{name}-#{:os.getpid()}-#{version}"}
      _ -> {:stop, "Given DBus name is not a string"}
    end
  end

  defp get_required_name(_) do
    {:stop, "Missing required \"name\" option"}
  end

  defp get_required_icon(opts) when is_list(opts) do
    case Keyword.get(opts, :icon, nil) do
      %Icon{} = icon -> {:ok, icon}
      _ -> {:stop, "Required \"icon\" option must be an Icon struct"}
    end
  end

  defp get_required_icon(_) do
    {:stop, "Missing required \"icon\" option"}
  end

  defp get_optional_menu(opts) when is_list(opts) do
    case Keyword.get(opts, :menu, nil) do
      nil -> {:ok, nil}
      %Menu{} = menu -> {:ok, menu}
      _ -> {:stop, "Invalid \"menu\" option. Not a Menu struct"}
    end
  end

  defp get_optional_menu(_) do
    {:ok, nil}
  end
end
