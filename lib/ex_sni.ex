defmodule ExSni do
  use Supervisor

  alias ExSni.Bus
  alias ExSni.{Icon, Menu, MenuDiff}

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
      router = %ExSni.Router{
        icon: icon,
        menu: {:via, Registry, {ExSniRegistry, "menu_server"}}
      }

      children = [
        {Registry, keys: :unique, name: ExSniRegistry},
        %{
          id: ExDBus.Service,
          start:
            {ExDBus.Service, :start_link,
             [
               [name: service_name, schema: ExSni.Schema, router: router],
               [name: {:via, Registry, {ExSniRegistry, "dbus_service"}}]
             ]},
          restart: :transient
        },
        # Menu versions server
        %{
          id: Menu.Server,
          start:
            {Menu.Server, :start_link,
             [[menu], [name: {:via, Registry, {ExSniRegistry, "menu_server"}}]]},
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

  @spec get_menu(pid() | {:router, ExSni.Router.t()} | {:server, pid() | atom() | tuple()}) ::
          {:ok, nil | Menu.t()} | {:error, any()}
  def get_menu(sni_pid) when is_pid(sni_pid) or is_atom(sni_pid) do
    case get_menu_handle(sni_pid) do
      {:ok, handle} ->
        get_menu(handle)

      error ->
        error
    end
  end

  def get_menu({:server, menu_server}) do
    Menu.Server.get_menu(menu_server)
  end

  def get_menu({:router, %ExSni.Router{menu: menu}}) do
    {:ok, menu}
  end

  @spec set_menu(pid(), Menu.t() | nil) :: {:ok, Menu.t() | nil} | {:error, any()}
  def set_menu(sni_pid, menu) do
    # with {:ok, router} <- get_router(sni_pid) do
    #   set_router_menu(sni_pid, router, menu)
    # end
    case get_menu_handle(sni_pid) do
      {:ok, handle} -> set_menu(sni_pid, handle, menu)
      error -> error
    end
  end

  @spec set_menu(pid(), {:server | :router, any()}, Menu.t() | nil) ::
          {:ok, Menu.t() | nil} | {:error, any()}
  def set_menu(sni_pid, {:router, router}, menu) do
    set_router_menu(sni_pid, router, menu)
  end

  def set_menu(_sni_pid, {:server, menu_server}, menu) do
    Menu.Server.set_menu(menu_server, menu)
  end

  @spec update_menu(sni_pid :: pid(), parentId :: nil | integer(), menu :: nil | %Menu{}) :: any()
  def update_menu(sni_pid, nil, menu) do
    IO.inspect("", label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu]")

    with {:ok, menu_handle} <- get_menu_handle(sni_pid),
         {:ok, old_menu} <- get_menu(menu_handle),
         {layout_update_id, ids_to_update, replace_menu} <- MenuDiff.diff(menu, old_menu),
         {:ok, %{version: v} = menu} <- set_menu(sni_pid, menu_handle, replace_menu) do
      IO.inspect(v,
        label: "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] Entering update_menu"
      )

      IO.inspect(is_menu_pending_reset?(menu_handle), label: "Is menu resetting?")

      reset_menu(sni_pid, menu_handle, 5, fn ret ->
        # Once the menu has been fully reset over dbus
        # Assign the new menu
        set_menu(sni_pid, menu_handle, menu)
        send_menu_signal(sni_pid, "LayoutUpdated", [6, 0])
      end)

      reset_menu(sni_pid, menu_handle, 7, fn ret ->
        IO.inspect(ret, label: "MENU AFTER RESET 2")
      end)

      unless layout_update_id == -1 do
        send_menu_signal(sni_pid, "LayoutUpdated", [v, layout_update_id])
      end

      unless ids_to_update == [] do
        IO.inspect("",
          label:
            "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] get_group_properties :all"
        )

        # TODO: get properties that have changed only!
        result = ExSni.Menu.get_group_properties(menu, ids_to_update, [])

        IO.inspect(result,
          label:
            "[#{System.os_time(:millisecond)}] [ExSNI][update_menu] send ItemsPropertiesUpdated"
        )

        send_menu_signal(sni_pid, "ItemsPropertiesUpdated", [
          # Array of item properties and values that changed (all, for all items)
          result,
          # No properties removed (empty array)
          []
        ])
      end

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

  defp get_menu_handle(sni_pid) do
    case get_router(sni_pid) do
      {:ok, %ExSni.Router{menu: {:via, _, _} = server_via}} ->
        {:ok, {:server, server_via}}

      {:ok, %ExSni.Router{menu: server_pid}} when is_pid(server_pid) ->
        {:ok, {:server, server_pid}}

      {:ok, %ExSni.Router{} = router} ->
        {:ok, {:router, router}}

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

  defp set_router_menu(sni_pid, %{menu: %Menu{version: version}} = router, menu) do
    router = %{router | menu: %{menu | version: version + 1}}

    case set_router(sni_pid, router) do
      {:ok, %{menu: menu}} -> {:ok, menu}
      error -> error
    end
  end

  defp set_router_menu(_, %{menu: {:via, _, _} = server_via}, menu) do
    Menu.Server.set_menu(server_via, menu)
  end

  defp set_router_menu(_, %{menu: server_pid}, menu) when is_pid(server_pid) do
    Menu.Server.set_menu(server_pid, menu)
  end

  defp set_router_menu(sni_pid, %{menu: _} = router, menu) do
    router =
      case menu do
        %Menu{} = menu -> %{router | menu: %{menu | version: 1}}
        other -> %{router | menu: other}
      end

    case set_router(sni_pid, router) do
      {:ok, %{menu: menu}} -> {:ok, menu}
      error -> error
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
    # get_child_pid(sni_pid, ExDBus.Service)
    {:ok, {:via, Registry, {ExSniRegistry, "dbus_service"}}}
  end

  # defp get_child_pid(sni_pid, id) do
  #   sni_pid
  #   |> Supervisor.which_children()
  #   |> Enum.filter(&(elem(&1, 0) == id))
  #   |> Enum.map(&elem(&1, 1))
  #   |> List.first()
  #   |> case do
  #     nil -> {:error, "Child #{id} not found"}
  #     child_pid -> {:ok, child_pid}
  #   end
  # end

  defp is_menu_pending_reset?({:server, menu_server}) do
    case Menu.Server.get_option(menu_server, :resetting, false) do
      true -> true
      _ -> false
    end
  end

  defp reset_menu(sni_pid, handle, version, callback \\ nil)

  defp reset_menu(sni_pid, {:server, menu_server}, version, callback) do
    if is_menu_pending_reset?({:server, menu_server}) do
      # Menu is still resetting. Await for `GetLayout` or timeout
      on_menu_method(
        :after,
        menu_server,
        "GetLayout",
        nil,
        nil,
        fn result ->
          if is_function(callback) do
            callback.(result)
          end
        end
      )
    else
      # Mark menu as in reset state
      Menu.Server.set_option(menu_server, :resetting, true)

      queue_menu_signal(
        sni_pid,
        {:server, menu_server},
        {"LayoutUpdated", [version, 0]},
        "GetLayout",
        fn _, _ ->
          # Set the menu to nil, so that the next GetLayout call gets an empty menu
          Menu.Server.set_menu(menu_server, nil)

          # Set menu out of reset state
          Menu.Server.set_option(menu_server, :resetting, false)
        end,
        callback
      )
    end
  end

  defp queue_menu_signal(
         sni_pid,
         {:server, menu_server},
         {signal_name, signal_args},
         method_name,
         fn_method,
         fn_finish
       ) do
    on_menu_method(
      :before,
      menu_server,
      method_name,
      fn ->
        send_menu_signal(sni_pid, signal_name, signal_args)
      end,
      fn_method,
      fn_finish
    )
  end

  defp on_menu_method(:before, menu_server, method_name, fn_init, fn_method, fn_finish) do
    on_menu_method_task(
      method_name,
      fn task_pid ->
        Menu.Server.register_before_method(menu_server, method_name, task_pid)

        if is_function(fn_init) do
          fn_init.()
        end
      end,
      fn_method,
      fn_finish
    )
  end

  defp on_menu_method(:after, menu_server, method_name, fn_init, fn_method, fn_finish) do
    on_menu_method_task(
      method_name,
      fn task_pid ->
        Menu.Server.register_after_method(menu_server, method_name, task_pid)

        if is_function(fn_init) do
          fn_init.()
        end
      end,
      fn_method,
      fn_finish
    )
  end

  defp on_menu_method_task(method_name, fn_init, fn_method, fn_finish) do
    Task.Supervisor.start_child(ExSni.Task.Supervisor, fn ->
      if is_function(fn_init) do
        fn_init.(self())
      end

      ret_value =
        receive do
          {{:method, ^method_name, arguments}, pid} ->
            if is_function(fn_method) do
              fn_method.(arguments, pid)
            else
              :ok
            end

          _ ->
            :error
        after
          5000 -> :timeout
        end

      if is_function(fn_finish) do
        fn_finish.(ret_value)
      end
    end)
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
      IO.inspect(service_pid, label: "Sending signal over ExDBus.Service")

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
