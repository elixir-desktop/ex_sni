defmodule ExSni.Router do
  defstruct icon: nil,
            menu: nil
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
    Menu.get_layout(menu, parentId, depth, properties)
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
    result =
      ids
      |> Enum.map(&Menu.find_item(menu, &1))
      |> Enum.reject(&(&1 == nil))
      |> Enum.map(fn item ->
        values = ExSni.DbusProtocol.get_properties(item, properties)
        [item.id, values]
      end)

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
    Menu.onEvent(menu, eventId, id, data, timestamp)
    {:ok, [], []}
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

  def get_property(
        %{menu: %Menu{} = menu},
        "/MenuBar",
        "com.canonical.dbusmenu",
        property,
        _context
      ) do
    ExSni.DbusProtocol.get_property(menu, property)
  end

  def get_property(_router, _path, _interface, _property, _context) do
    :skip
  end

  # SNI properties are all read-only
  def set_property(_router, _path, _interface, _property, _value, _context) do
    :skip
  end
end
