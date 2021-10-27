defmodule ExSni do
  use Supervisor

  alias ExSni.Bus
  alias ExSni.{Icon, Menu}

  # def start_link(opts \\ []) do
  #   with {:ok, service_name} <- get_required_name(opts),
  #        {:ok, icon} <- get_required_icon(opts),
  #        {:ok, menu} <- get_optional_menu(opts),
  #        router <- %ExSni.Router{icon: icon, menu: menu},
  #        {:ok, supervisor_pid} <- start_supervisor(service_name, router) do
  #     {:ok, supervisor_pid}
  #   end
  # end
  def start_link(init_opts \\ [], start_opts \\ []) do
    Supervisor.start_link(__MODULE__, init_opts, start_opts)
  end

  @impl true
  def init(opts) do
    with {:ok, service_name} <- get_optional_name(opts),
         {:ok, icon} <- get_optional_icon(opts),
         {:ok, menu} <- get_optional_menu(opts) do
      router = %ExSni.Router{icon: icon, menu: menu}

      children = [
        %{
          id: ExDBus.Service,
          start:
            {ExDBus.Service, :start_link,
             [
               [name: service_name, schema: ExSni.Schema, router: router],
               []
             ]},
          restart: :transient
        }
      ]

      Supervisor.init(children, strategy: :rest_for_one)
    end
  end

  @doc """
  Returns true if there is a StatusNotifierWatcher available
  on the Session Bus.
  """
  @spec is_supported?() :: boolean()
  def is_supported?() do
    Bus.is_supported?()
  end

  @doc """
  Returns true if there is a StatusNotifierWatcher available
  on the Session Bus.
  - sni_pid - The pid of the ExSni Supervisor
  """
  @spec is_supported?(pid()) :: boolean()
  def is_supported?(sni_pid) do
    case get_bus(sni_pid) do
      {:ok, nil} -> {:error, "Service has no DBUS connection"}
      {:ok, bus_pid} -> Bus.is_supported?(bus_pid)
      error -> error
    end
  end

  @spec close(pid()) :: :ok
  def close(sni_pid) do
    Supervisor.stop(sni_pid)
  end

  @spec get_menu(pid()) :: {:ok, nil | Menu.t()} | {:error, any()}
  def get_menu(sni_pid) do
    case get_router(sni_pid) do
      {:ok, %ExSni.Router{menu: menu}} -> {:ok, menu}
      error -> error
    end
  end

  @spec set_menu(pid(), Menu.t() | nil) :: {:ok, Menu.t() | nil} | {:error, any()}
  def set_menu(sni_pid, menu) do
    with {:ok, router} <- get_router(sni_pid) do
      version =
        case router do
          %{menu: %{version: version}} -> version + 1
          _ -> 1
        end

      # Set menu with version in router
      router = %{router | menu: %{menu | version: version}}

      case set_router(sni_pid, router) do
        {:ok, %{menu: menu}} -> {:ok, menu}
        error -> error
      end
    end
  end

  @spec update_menu(sni_pid :: pid(), parentId :: nil | integer(), menu :: nil | %Menu{}) :: any()
  def update_menu(sni_pid, nil, menu) do
    IO.inspect("", label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu]")
    with {:ok, old_menu} <- get_menu(sni_pid),
         {:ok, %{version: v} = menu} <- set_menu(sni_pid, menu) do
      IO.inspect(v, label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] Sending LayoutUpdated")

      ExSni.MenuDiff.diff(menu, old_menu)

      send_menu_signal(sni_pid, "LayoutUpdated", [v, 0])

      # Signaling `LayoutUpdated/2` is not enough here.
      # The host service also expects `ItemsPropertiesUpdates/2` signal,
      # with the list of changes and the list of removed properties.

      # Because we're reusing menu item IDs (e.g. when removing and adding an item)
      # right now just send the whole list of properties for all items.
      # TODO: Optimize to only send the properties that have changed
      IO.inspect("", label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] get_group_properties :all")
      result = ExSni.Menu.get_group_properties(menu, :all, [])
      IO.inspect(result, label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] send ItemsPropertiesUpdated")
      # send_menu_signal(sni_pid, "ItemsPropertiesUpdated", [
      #   # Array of item properties and values that changed (all, for all items)
      #   result,
      #   # No properties removed (empty array)
      #   []
      # ])

      IO.inspect("", label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] done.")
      {:ok, menu}
    end
  end

  @spec get_icon(pid()) :: {:ok, nil | Icon.t()} | {:error, any()}
  def get_icon(sni_pid) do
    case get_router(sni_pid) do
      {:ok, %ExSni.Router{icon: icon}} -> {:ok, icon}
      error -> error
    end
  end

  @spec set_icon(pid, Icon.t() | nil, keyword()) :: {:ok, Icon.t() | nil} | {:error, any()}
  def set_icon(sni_pid, icon, opts \\ []) do
    with {:ok, service_pid} <- get_service_pid(sni_pid),
         {:ok, router} <- get_service_router(service_pid),
         {:ok, %{icon: icon} = router} <- set_service_router(service_pid, %{router | icon: icon}) do
      if Keyword.get(opts, :register, true) == true and icon != nil do
        register_router_icon(service_pid, router)
      else
        {:ok, icon}
      end
    end
  end

  @spec update_icon(sni_pid :: pid(), icon :: nil | %Icon{}) :: any()
  def update_icon(sni_pid, icon) do
    with {:ok, icon} <- set_icon(sni_pid, icon) do
      send_icon_signal(sni_pid, "NewIcon")
      {:ok, icon}
    end
  end

  @spec register_icon(pid) :: :ok | {:error, any()}
  def register_icon(sni_pid) do
    with {:ok, service_pid} <- get_service_pid(sni_pid),
         {:ok, router} <- get_service_router(service_pid),
         {:ok, _} <- register_router_icon(service_pid, router) do
      :ok
    end
  end

  defp register_router_icon(_, %{icon: %Icon{} = icon, icon_registered: true}) do
    {:ok, icon}
  end

  defp register_router_icon(service_pid, %{icon: %Icon{}, icon_registered: false} = router) do
    with {:ok, _} <- register_icon_on_service(service_pid),
         {:ok, %{icon: icon}} <-
           set_service_router(service_pid, %{router | icon_registered: true}) do
      {:ok, icon}
    end
  end

  defp register_router_icon(_, _) do
    {:error, "Cannot register nil icon"}
  end

  defp register_icon_on_service(service_pid) do
    case ExDBus.Service.get_name(service_pid) do
      nil -> service_register_icon(service_pid, nil)
      name when is_binary(name) -> service_register_icon(service_pid, name)
    end
  end

  defp get_bus(sni_pid) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      ExDBus.Service.get_bus(service_pid)
    end
  end

  defp get_router(sni_pid) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      get_service_router(service_pid)
    end
  end

  defp get_service_router(service_pid) do
    case ExDBus.Service.get_router(service_pid) do
      {:ok, nil} -> {:ok, %ExSni.Router{}}
      ret -> ret
    end
  end

  defp set_router(sni_pid, router) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      set_service_router(service_pid, router)
    end
  end

  defp set_service_router(service_pid, router) do
    ExDBus.Service.set_router(service_pid, router)
  end

  defp service_register_icon(service_pid, nil) do
    with {:ok, dbus_pid} <- ExDBus.Service.get_dbus_pid(service_pid) do
      service_register_icon(service_pid, dbus_pid)
    end
  end

  defp service_register_icon(service_pid, service_name) when is_pid(service_pid) do
    GenServer.call(service_pid, {
      :call_method,
      "org.kde.StatusNotifierWatcher",
      "/StatusNotifierWatcher",
      "org.kde.StatusNotifierWatcher",
      "RegisterStatusNotifierItem",
      {"s", [:string], [service_name]}
    })
  end

  defp get_service_pid(sni_pid) do
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

  defp send_menu_signal(sni_pid, "LayoutUpdated" = signal, args) do
    send_signal(sni_pid, :menu, signal, {"ui", [:uint32, :int32], args})
  end

  defp send_menu_signal(sni_pid, "ItemsPropertiesUpdated" = signal, args) do
    send_signal(sni_pid, :menu, signal, {
      "a(ia{sv})a(ias)",
      [
        {:array, {:struct, [:int32, {:dict, :string, :variant}]}},
        {:array, {:struct, [:int32, {:array, :string}]}}
      ],
      args
    })
  end

  defp send_icon_signal(sni_pid, signal)
       when signal in ["NewTitle", "NewIcon", "NewAttentionIcon", "NewOverlayIcon", "NewToolTip"] do
    send_signal(sni_pid, :icon, signal, {"", [], []})
  end

  defp send_signal(sni_pid, :menu, signal, args) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      ExDBus.Service.send_signal(
        service_pid,
        "/MenuBar",
        "com.canonical.dbusmenu",
        signal,
        args
      )
    end
  end

  defp send_signal(sni_pid, :icon, signal, args) do
    with {:ok, service_pid} <- get_service_pid(sni_pid) do
      ExDBus.Service.send_signal(
        service_pid,
        "/StatusNotifierItem",
        "org.kde.StatusNotifierItem",
        signal,
        args
      )
    end
  end

  defp get_optional_name(opts) when is_list(opts) do
    version = Keyword.get(opts, :version, 1)

    case Keyword.get(opts, :name, nil) do
      nil -> {:ok, nil}
      "" -> {:ok, nil}
      name when is_binary(name) -> {:ok, "#{name}-#{:os.getpid()}-#{version}"}
      _ -> {:stop, "Given DBus name is not a valid string"}
    end
  end

  defp get_optional_name(_) do
    {:ok, nil}
  end

  defp get_optional_icon(opts) when is_list(opts) do
    case Keyword.get(opts, :icon, nil) do
      nil -> {:ok, nil}
      %Icon{} = icon -> {:ok, icon}
      _ -> {:stop, "Invalid \"icon\" option. Not a Icon struct"}
    end
  end

  defp get_optional_icon(_) do
    {:ok, nil}
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
