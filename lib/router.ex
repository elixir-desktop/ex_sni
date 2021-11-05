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
    Menu.Server.method(server_via, method_name, arguments)
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
    ExSni.DbusProtocol.get_property(icon, property)
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
    Menu.Server.get_property(server_pid, property)
  end

  def get_property(
        %{menu: {:via, _, _} = server_via},
        "/MenuBar",
        "com.canonical.dbusmenu",
        property,
        _context
      ) do
    Menu.Server.get_property(server_via, property)
  end

  def get_property(_router, _path, _interface, _property, _context) do
    :skip
  end

  # SNI properties are all read-only
  def set_property(_router, _path, _interface, _property, _value, _context) do
    :skip
  end
end
