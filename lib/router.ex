defmodule ExSni.Router do
  defstruct icon: nil,
            icon_registered: false,
            menu: nil

  @type t() :: %__MODULE__{
    icon: nil | pid() | atom() | ExSni.Icon.t() | tuple(),
    icon_registered: boolean(),
    menu: nil | pid() | atom() | ExSni.Menu.t() | tuple()
  }
end

defimpl ExDBus.Router.Protocol, for: ExSni.Router do
  alias ExSni.{Icon, Menu}

  def method(
        %{menu: %Menu{} = menu},
        "/MenuBar",
        "com.canonical.dbusmenu",
        "GetLayout",
        _signature,
        {parentId, depth, properties},
        _context
      ) do
    IO.inspect({parentId, depth, properties},
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] GetLayout"
    )

    ret = Menu.get_layout(menu, parentId, depth, properties)

    IO.inspect(ret, label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] GetLayout")
    ret
  end

  def method(
        %{menu: %Menu{} = menu},
        "/MenuBar",
        "com.canonical.dbusmenu",
        "GetGroupProperties",
        _signature,
        {ids, properties},
        _context
      ) do
    IO.inspect({ids, properties},
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] GetGroupProperties"
    )

    result = Menu.get_group_properties(menu, ids, properties)

    IO.inspect(result,
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] GOT GetGroupProperties"
    )

    {:ok, [{:array, {:struct, [:int32, {:dict, :string, :variant}]}}], [result]}
  end

  # This is called by the applet to notify the application
  # that it is about to show the menu under the specified item.

  # Params:
  #   - id::uint32 - Which menu item represents
  #                 the parent of the item about to be shown.
  # Returns:
  #   - needUpdate::boolean() - Whether this AboutToShow event
  #                   should result in the menu being updated.
  def method(
        %{menu: %Menu{} = menu},
        "/MenuBar",
        "com.canonical.dbusmenu",
        "AboutToShow",
        _signature,
        id,
        _context
      ) do
    ret = Menu.onAboutToShow(menu, id)
    {:ok, [:boolean], [ret]}
  end

  # This is called by the applet to notify the application
  # an event happened on a menu item.

  # Params:
  #   - id::uint32      - the id of the item which received the event
  #   - eventId::string - the type of event
  #           ("clicked", "hovered", "opened", "closed")
  #   - data::variant   - event-specific data
  #   - timestamp::uint32 - The time that the event occured if available
  #         or the time the message was sent if not
  # Returns:
  #   - needUpdate::boolean() - Whether this AboutToShow event
  #                   should result in the menu being updated.
  def method(
        %{menu: %Menu{} = menu},
        "/MenuBar",
        "com.canonical.dbusmenu",
        "Event",
        _signature,
        {id, eventId, data, timestamp},
        _context
      ) do
    IO.inspect({id, eventId, data, timestamp},
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] Menu OnEvent"
    )

    Menu.onEvent(menu, eventId, id, data, timestamp)
    {:ok, [], []}
  end

  # Route Menu methods to server if any
  def method(
        %{menu: server_pid},
        "/MenuBar",
        "com.canonical.dbusmenu",
        method_name,
        _signature,
        arguments,
        _context
      )
      when is_pid(server_pid) do
    IO.inspect({method_name, arguments},
      label:
        "[#{System.os_time(:millisecond)}] [ExSNI][Router] Route Menu method to Menu.Server pid"
    )

    Menu.Server.method(server_pid, method_name, arguments)
  end

  def method(
        %{menu: {:via, _, _} = server_via},
        "/MenuBar",
        "com.canonical.dbusmenu",
        method_name,
        _signature,
        arguments,
        _context
      ) do
    IO.inspect({method_name, arguments},
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] Route Menu method via Menu.Server"
    )

    Menu.Server.method(server_via, method_name, arguments)
  end

  # Route Menu methods to server if any
  def method(
        %{menu: server_pid_resolver},
        "/MenuBar",
        "com.canonical.dbusmenu",
        method_name,
        _signature,
        arguments,
        _context
      )
      when is_function(server_pid_resolver) do
    IO.inspect({method_name, arguments},
      label:
        "[#{System.os_time(:millisecond)}] [ExSNI][Router] Route Menu method to resolved Menu.Server"
    )

    case resolve(server_pid_resolver) do
      {:ok, server_pid} ->
        Menu.Server.method(server_pid, method_name, arguments)

      {:error, _} ->
        :skip
    end
  end

  def method(
        %{icon: %Icon{}},
        "/StatusNotifierItem",
        "org.kde.StatusNotifierItem",
        "Activate",
        _signature,
        {_x, _y},
        _context
      ) do
    {:ok, [], []}
  end

  def method(
        %{icon: %Icon{}},
        "/StatusNotifierItem",
        "org.kde.StatusNotifierItem",
        "SecondaryActivate",
        _signature,
        {_x, _y},
        _context
      ) do
    {:ok, [], []}
  end

  def method(
        %{icon: %Icon{}},
        "/StatusNotifierItem",
        "org.kde.StatusNotifierItem",
        "Scroll",
        _signature,
        {_delta, _orientation},
        _context
      ) do
    {:ok, [], []}
  end

  def method(_router, _path, _interface, _method, _signature, _args, _context) do
    :skip
  end

  def get_property(
        %{icon: %Icon{} = icon},
        "/StatusNotifierItem",
        "org.kde.StatusNotifierItem",
        property,
        _context
      ) do
    IO.inspect(property,
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] Icon GetProperty"
    )

    ExSni.DbusProtocol.get_property(icon, property)
  end

  def get_property(
        %{menu: %Menu{} = menu},
        "/MenuBar",
        "com.canonical.dbusmenu",
        property,
        _context
      ) do
    IO.inspect(property,
      label: "[#{System.os_time(:millisecond)}] [ExSNI][Router] Menu GetProperty"
    )

    ExSni.DbusProtocol.get_property(menu, property)
  end

  # Route Menu property getters to menu server
  def get_property(
        %{menu: server_pid},
        "/MenuBar",
        "com.canonical.dbusmenu",
        property,
        _context
      )
      when is_pid(server_pid) do
    IO.inspect(property,
      label:
        "[#{System.os_time(:millisecond)}] [ExSNI][Router] Route Menu GetProperty to MenuServer pid"
    )

    Menu.Server.get_property(server_pid, property)
  end

  def get_property(
        %{menu: {:via, _, _} = server_via},
        "/MenuBar",
        "com.canonical.dbusmenu",
        property,
        _context
      ) do
    IO.inspect(property,
      label:
        "[#{System.os_time(:millisecond)}] [ExSNI][Router] Route Menu GetProperty via MenuServer"
    )

    Menu.Server.get_property(server_via, property)
  end

  def get_property(
        %{menu: server_pid_resolver},
        "/MenuBar",
        "com.canonical.dbusmenu",
        property,
        _context
      )
      when is_function(server_pid_resolver) do
    IO.inspect(property,
      label:
        "[#{System.os_time(:millisecond)}] [ExSNI][Router] Route Menu GetProperty to resolved MenuServer"
    )

    case resolve(server_pid_resolver) do
      {:ok, server_pid} -> Menu.Server.get_property(server_pid, property)
      {:error, _} -> :skip
    end
  end

  def get_property(_router, _path, _interface, _property, _context) do
    :skip
  end

  # SNI properties are all read-only
  def set_property(_router, _path, _interface, _property, _value, _context) do
    :skip
  end

  defp resolve(fn_resolver) do
    try do
      fn_resolver.()
    rescue
      e -> {:error, e}
    else
      {:ok, {:via, _, _} = via} -> {:ok, via}
      {:ok, pid} when is_pid(pid) -> {:ok, pid}
      pid when is_pid(pid) -> {:ok, pid}
      {:error, reason} -> {:error, reason}
      other -> {:error, other}
    end
  end
end
