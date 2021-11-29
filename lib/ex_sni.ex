defmodule ExSni do
  use Supervisor

  alias ExSni.Bus
  alias ExSni.{Icon, Menu}

  def start_link(init_opts \\ [], start_opts \\ []) do
    Supervisor.start_link(__MODULE__, init_opts, start_opts)
  end

  @impl true
  def init(opts) do
    with {:ok, service_name} <- get_optional_name(opts),
         {:ok, icon} <- get_optional_icon(opts),
         {:ok, menu} <- get_optional_menu(opts) do
      menu_server_pid = {:via, Registry, {ExSniRegistry, "menu_server"}}
      dbus_service_pid = {:via, Registry, {ExSniRegistry, "dbus_service"}}
      backup_store_pid = {:via, Registry, {ExSniRegistry, "menu_store"}}

      router = %ExSni.Router{
        icon: icon,
        menu: menu_server_pid
      }

      children = [
        {Registry, keys: :unique, name: ExSniRegistry},
        %{
          id: ExDBus.Service,
          start:
            {ExDBus.Service, :start_link,
             [
               [name: service_name, schema: ExSni.Schema, router: router],
               [name: dbus_service_pid]
             ]},
          restart: :transient
        },
        %{
          id: Menu.BackupStore,
          start: {Menu.BackupStore, :start_link, [[], [name: backup_store_pid]]},
          restart: :transient
        },
        # Menu versions server
        %{
          id: Menu.Server,
          start:
            {Menu.Server, :start_link,
             [
               [
                 menu: menu,
                 dbus_service: dbus_service_pid,
                 backup_server: backup_store_pid
               ],
               [name: menu_server_pid]
             ]},
          restart: :transient
        },
        {Task.Supervisor, name: ExSni.Task.Supervisor}
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
  @spec is_supported?(GenServer.server()) :: boolean()
  def is_supported?(sni_pid) do
    case get_bus(sni_pid) do
      {:ok, nil} -> {:error, "Service has no DBUS connection"}
      {:ok, bus_pid} -> Bus.is_supported?(bus_pid)
      error -> error
    end
  end

  @spec close(GenServer.server()) :: :ok
  def close(sni_pid) do
    Supervisor.stop(sni_pid)
  end

  @spec get_menu(
          GenServer.server()
          | {:router, ExSni.Router.t()}
          | {:server, GenServer.server() | atom() | tuple()}
        ) ::
          {:ok, nil | Menu.t()} | {:error, any()}
  def get_menu(sni_pid) when is_pid(sni_pid) or is_atom(sni_pid) do
    case get_menu_handle(sni_pid) do
      {:ok, handle} ->
        Menu.Server.get(handle)

      error ->
        error
    end
  end

  @spec set_menu(GenServer.server(), Menu.t() | nil) :: {:ok, Menu.t() | nil} | {:error, any()}
  def set_menu(sni_pid, menu) do
    case get_menu_handle(sni_pid) do
      {:ok, handle} -> Menu.Server.set(handle, menu)
      error -> error
    end
  end

  @spec update_menu(
          sni_pid :: GenServer.server(),
          parentId :: nil | integer(),
          menu :: nil | %Menu{}
        ) :: any()
  def update_menu(sni_pid, nil, menu) do
    set_menu(sni_pid, menu)
  end

  @spec get_icon(GenServer.server()) :: {:ok, nil | Icon.t()} | {:error, any()}
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

  @spec update_icon(sni_pid :: GenServer.server(), icon :: nil | %Icon{}) :: any()
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

  defp get_menu_handle(sni_pid) do
    case get_router(sni_pid) do
      {:ok, %ExSni.Router{menu: {:via, _, _} = server_via}} ->
        {:ok, server_via}

      {:ok, %ExSni.Router{menu: server_pid}} when is_pid(server_pid) ->
        {:ok, server_pid}

      error ->
        error
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

  defp set_service_router(service_pid, router) do
    ExDBus.Service.set_router(service_pid, router)
  end

  defp service_register_icon(service_pid, nil) do
    with {:ok, dbus_pid} <- ExDBus.Service.get_dbus_pid(service_pid) do
      service_register_icon(service_pid, dbus_pid)
    end
  end

  defp service_register_icon(service_pid, service_name) do
    GenServer.call(service_pid, {
      :call_method,
      "org.kde.StatusNotifierWatcher",
      "/StatusNotifierWatcher",
      "org.kde.StatusNotifierWatcher",
      "RegisterStatusNotifierItem",
      {"s", [:string], [service_name]}
    })
  end

  defp get_service_pid(_sni_pid) do
    {:ok, {:via, Registry, {ExSniRegistry, "dbus_service"}}}
  end

  defp send_icon_signal(sni_pid, signal)
       when signal in ["NewTitle", "NewIcon", "NewAttentionIcon", "NewOverlayIcon", "NewToolTip"] do
    send_signal(sni_pid, :icon, signal, {"", [], []})
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
