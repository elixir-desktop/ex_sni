defmodule MyIcon do
  alias ExSni.Icon
  alias ExSni.Icon.{Info, Tooltip}
  alias ExSni.Menu
  alias ExSni.Menu.Item

  defmodule MyIcon.Router do
    defstruct icon: nil,
              menu: nil
  end

  defimpl ExDBus.Router.Protocol, for: MyIcon.Router do
    def method(
          %{menu: menu},
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
          %{menu: menu},
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

    @doc """
    This is called by the applet to notify the application
    that it is about to show the menu under the specified item.

    Params:
      - id::uint32 - Which menu item represents
                    the parent of the item about to be shown.
    Returns:
      - needUpdate::boolean() - Whether this AboutToShow event
                      should result in the menu being updated.
    """
    def method(
          %{menu: menu},
          "/MenuBar",
          "com.canonical.dbusmenu",
          "AboutToShow",
          _signature,
          args,
          _context
        ) do
      IO.inspect(args, label: "/MenuBar AboutToShow method")
      {:ok, [:boolean], [false]}
    end

    @doc """
    This is called by the applet to notify the application
    an event happened on a menu item.

    Params:
      - id::uint32      - the id of the item which received the event
      - eventId::string - the type of event
              ("clicked", "hovered", "opened", "closed")
      - data::variant   - event-specific data
      - timestamp::uint32 - The time that the event occured if available
            or the time the message was sent if not
    Returns:
      - needUpdate::boolean() - Whether this AboutToShow event
                      should result in the menu being updated.
    """
    def method(
          %{menu: menu},
          "/MenuBar",
          "com.canonical.dbusmenu",
          "Event",
          _signature,
          {id, eventId, data, timestamp} = args,
          _context
        ) do
      IO.inspect(args, label: "/MenuBar Event method")
      {:ok, [], []}
    end

    def method(
          %{menu: menu},
          "/StatusNotifierItem",
          "org.kde.StatusNotifierItem",
          "Activate",
          _signature,
          {x, y} = args,
          _context
        ) do
      IO.inspect(args, label: "/StatusNotifierItem Activate method")
      {:ok, [], []}
    end

    def method(
          %{menu: menu},
          "/StatusNotifierItem",
          "org.kde.StatusNotifierItem",
          "SecondaryActivate",
          _signature,
          {x, y} = args,
          _context
        ) do
      IO.inspect(args, label: "/StatusNotifierItem SecondaryActivate method")
      {:ok, [], []}
    end

    def method(
          %{menu: menu},
          "/StatusNotifierItem",
          "org.kde.StatusNotifierItem",
          "Scroll",
          _signature,
          {delta, orientation} = args,
          _context
        ) do
      IO.inspect(args, label: "/StatusNotifierItem Scroll method")
      {:ok, [], []}
    end

    def method(_router, path, interface, method, signature, args, _context) do
      IO.inspect(
        [
          path,
          interface,
          method,
          signature,
          args
        ],
        label: "ROUTE METHOD"
      )

      :skip
    end

    def get_property(
          %{icon: icon},
          "/StatusNotifierItem",
          "org.kde.StatusNotifierItem",
          property,
          _context
        ) do
      ExSni.DbusProtocol.get_property(icon, property)
    end

    def get_property(%{menu: menu}, "/MenuBar", "com.canonical.dbusmenu", property, _context) do
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

  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      [],
      opts
    )
  end

  @impl true
  def init(_opts) do
    name = "org.example.MyIcon-#{:os.getpid()}-1"

    {menu, icon} = setup()

    {:ok, service} =
      ExDBus.Service.start_link(
        name,
        ExSni.IconSchema,
        router: %MyIcon.Router{menu: menu, icon: icon}
      )

    # bus = ExDBus.Service.get_bus(service)

    register_icon(service, name)

    state = %{service: service, name: name}

    {:ok, state}
  end

  def register_icon(service, service_name) do
    GenServer.call(service, {
      :call_method,
      "org.kde.StatusNotifierWatcher",
      "/StatusNotifierWatcher",
      "org.kde.StatusNotifierWatcher",
      "RegisterStatusNotifierItem",
      {"s", [:string], [service_name]}
    })
    |> IO.inspect(label: "REGISTER ICON CALL")
  end

  def setup() do
    menu = %Menu{
      root: %Item{
        id: 0,
        children: [
          %Item{
            id: 1,
            label: "File"
          },
          %Item{
            id: 2,
            label: "View"
          },
          %Item{
            id: 3,
            label: "Quit"
          }
        ]
      }
    }

    icon = %Icon{
      category: :application_status,
      id: "1",
      title: "Test_Icon",
      menu: "/MenuBar",
      status: :active,
      icon: %Info{
        name: "applications-development"
      },
      tooltip: %Tooltip{
        name: "applications-development",
        title: "test-tooltip",
        description: "Some tooltip description here"
      }
    }

    {menu, icon}
  end
end
