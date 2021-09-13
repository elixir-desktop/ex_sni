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

  @spec get_menu(pid()) :: {:ok, nil | Menu.t()} | {:error, any()}
  def get_menu(sni_pid) do
    case get_router(sni_pid) do
      {:ok, nil} -> {:error, "Service has no router"}
      {:ok, %ExSni.Router{menu: menu}} -> {:ok, menu}
      error -> error
    end
  end

  @spec set_menu(pid(), Menu.t() | nil) :: {:ok, Menu.t() | nil} | {:error, any()}
  def set_menu(sni_pid, menu) do
    with {:ok, router} <- get_router(sni_pid) do
      router =
        router
        |> case do
          nil -> %ExSni.Router{menu: menu}
          router -> %{router | menu: menu}
        end

      set_router(sni_pid, router)
    end
  end

  @spec get_icon(pid()) :: {:ok, nil | Icon.t()} | {:error, any()}
  def get_icon(sni_pid) do
    case get_router(sni_pid) do
      {:ok, nil} -> {:error, "Service has no router"}
      {:ok, %ExSni.Router{icon: icon}} -> {:ok, icon}
      error -> error
    end
  end

  @spec set_icon(pid, Icon.t() | nil) :: {:ok, Icon.t() | nil} | {:error, any()}
  def set_icon(sni_pid, icon) do
    with {:ok, router} <- get_router(sni_pid) do
      router =
        router
        |> case do
          nil -> %ExSni.Router{icon: icon}
          router -> %{router | icon: icon}
        end

      set_router(sni_pid, router)
    end
  end

  defp get_router(sni_pid) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      ExDBus.Service.get_router(service_pid)
    end
  end

  defp set_router(sni_pid, router) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      ExDBus.Service.set_router(service_pid, router)
    end
  end

  def get_service_pid(sni_pid) do
    sni_pid
    |> Supervisor.which_children()
    |> Enum.filter(&(elem(&1, 0) == ExDBus.Service))
    |> Enum.map(&elem(&1, 1))
    |> List.first()
    |> case do
      nil -> {:error, "Service not found"}
      service_pid -> {:ok, service_pid}
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
