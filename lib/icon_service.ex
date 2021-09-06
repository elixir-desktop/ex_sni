defmodule ExSni.IconService do
  use GenServer

  def register_icon(pid \\ __MODULE__) do
    GenServer.call(pid, :register_icon)
  end

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      [],
      opts
    )
  end

  @impl true
  def init(_opts) do
    name = "org.example.MyIcon-#{:os.getpid()}-1"

    {:ok, service} =
      ExDBus.Service.start_link(
        name,
        DBusTrayIcon.IconSchema
      )

    bus = ExDBus.Service.get_bus(service)
    :ok = can_register(bus)

    # pixdata = gen_icon(128, 128)

    {:ok, icon} =
      GenServer.start_link(MyIcon.Config, %{
        "Category" => "ApplicationStatus",
        "Id" => "1",
        "Title" => "test_icon",
        "Menu" => "/MenuBar",
        "Status" => "Active",
        "IconName" => "applications-development",
        "OverlayIconName" => "",
        "AttentionIconName" => "",
        "AttentionMovieName" => "",
        "ToolTip" => [
          {:dbus_variant, :string, "applications-development"},
          [],
          {:dbus_variant, :string, "test tooltip"},
          {:dbus_variant, :string, "some tooltip description here"}
        ],
        "ItemIsMenu" => false,
        "IconPixmap" => [],
        "OverlayIconPixmap" => [],
        "AttentionIconPixmap" => [],
        "WindowId" => 0
      })

    :ok = setup_interface({"/StatusNotifierItem", "org.kde.StatusNotifierItem"}, service, icon)

    {:ok, menu} =
      GenServer.start_link(MyIcon.Config, %{
        "Version" => 3,
        "TextDirection" => "ltr",
        "Status" => "normal",
        "IconThemePath" => []
      })

    :ok = setup_interface({"/MenuBar", "com.canonical.dbusmenu"}, service, menu)

    state = %{service: service, name: name, menu: menu, icon: icon}

    {:ok, state}
  end

  # Gen server implementation

  @impl true

  def handle_call(:register_icon, from, %{service: service, name: service_name} = state) do
    reply =
      GenServer.call(service, {
        :call_method,
        "org.kde.StatusNotifierWatcher",
        "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher",
        "RegisterStatusNotifierItem",
        {"s", [:string], [service_name]}
      })
      |> IO.inspect(label: "REGISTER ICON CALL")

    {:reply, reply, state}
  end

  def handle_call(request, from, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(request, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(message, state) do
    {:noreply, state}
  end

  defp can_register(bus) do
    with :ok <- has_status_notifier(bus) do
      :ok
    end
  end

  defp has_status_notifier(bus) do
    owner_result =
      GenServer.call(
        bus,
        {:call_method, "org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus",
         "GetNameOwner", {"s", [:string], ["org.kde.StatusNotifierWatcher"]}}
      )

    iface_result =
      GenServer.call(
        bus,
        {:has_interface, "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
         "org.kde.StatusNotifierWatcher"}
      )

    with {:ok, _} <- owner_result,
         {:ok, true} <- iface_result do
      :ok
    else
      {:ok, _} -> {:error, "Could not find valid StatusNotifierWatcher"}
      error -> error
    end
  end

  defp setup_interface({path, interface_name}, service, handle) do
    {:ok, {:interface, _, children}} =
      GenServer.call(
        service,
        {:get_interface, path, interface_name}
      )

    prop_getter = {:call, handle, :get_property}
    prop_setter = {:call, handle, :set_property}
    method_callback = {:call, handle, :method}

    children =
      children
      |> Enum.map(fn child ->
        case ExDBus.Tree.get_tag(child) do
          :property ->
            child
            |> ExDBus.Tree.set_property_setter(prop_setter)
            |> ExDBus.Tree.set_property_getter(prop_getter)

          :method ->
            child
            |> ExDBus.Tree.set_method_callback(method_callback)

          _ ->
            child
        end
      end)

    :ok =
      GenServer.call(
        service,
        {:replace_interface, path, {:interface, interface_name, children}}
      )

    :ok
  end

  # def __register_icon(pid) do
  #       service_name = "org.example.MyIcon"

  #       {:ok, bus} =
  #         :dbus_bus_reg.get_bus(:session)
  #         |> IO.inspect(label: ":dbus_bus_reg.get_bus(:session)")

  #       {:ok, service} =
  #         :dbus_bus.get_service(bus, "org.kde.StatusNotifierWatcher")
  #         |> IO.inspect(label: ":dbus_bus.get_service")

  #       {:ok, object} =
  #         :dbus_remote_service.get_object(service, "/StatusNotifierWatcher")
  #         |> IO.inspect(label: ":dbus_remote_service.get_object")

  #       {:ok, interface} =
  #         :dbus_proxy.interface(object, "org.kde.StatusNotifierWatcher")
  #         |> IO.inspect(label: ":dbus_proxy.interface")

  #       :ok =
  #         :dbus_proxy.call(
  #           interface,
  #           "RegisterStatusNotifierItem",
  #           [service_name]
  #         )
  #         |> IO.inspect(label: ":dbus_proxy.call")

  #       IO.inspect(:os.getpid(), label: "[REGISTER ICON]")

  #       # :ok = :dbus_remote_service.release_object(service, object)
  #       # :ok = :dbus_bus.release_service(bus, service)
  #     end
end
