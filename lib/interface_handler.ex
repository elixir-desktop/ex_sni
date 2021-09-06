defmodule ExSni.InterfaceHandler do
  use GenServer

  def init(%{} = props) do
    {:ok, props}
  end

  @impl true
  def handle_call({:get_property, key}, _from, state) do
    if Map.has_key?(state, key) do
      {:reply, Map.get(state, key), state}
    else
      {:reply, {:error, "org.freedesktop.DBus.UnknownProperty", "Invalid property"}, state}
    end
  end

  def handle_call({:set_property, key, value}, _from, state) do
    state = Map.put(state, key, value)
    {:reply, :ok, state}
  end

  def handle_call(
        {:method, "GetLayout", {0, -1, ["type", "children-display"]}, _context},
        _from,
        state
      ) do
    # Signature: u(ia{sv}av)
    # result = [
    #   # u
    #   0,
    #   # (
    #   # i
    #   [
    #     0,
    #     # a
    #     [
    #       # a
    #       # {sv}
    #       ["label", ["s", "Label Empty"]],
    #       ["visible", ["b", 1]],
    #       ["enabled", ["b", 1]],
    #       ["children-display", ["s", "submenu"]]
    #     ],
    #     # a
    #     [
    #       # v
    #       [
    #         "(ia{sv}av)",
    #         # (
    #         [
    #           # i
    #           75,
    #           # a
    #           [
    #             # {sv}
    #             ["label", ["s", "_File"]],
    #             ["visible", ["b", 1]],
    #             ["enabled", ["b", 1]],
    #             ["children-display", ["s", "submenu"]]
    #           ],
    #           # av
    #           []
    #         ]
    #       ]
    #     ]
    #   ]
    # ]

    # "(ia{sv}av)"
    dbus_menu_item_type = {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

    children = [
      {:dbus_variant, dbus_menu_item_type,
       {
         1,
         [
           {"enabled", {:dbus_variant, :boolean, true}},
           {"visible", {:dbus_variant, :boolean, true}},
           {"type", {:dbus_variant, :string, "standard"}},
           {"label", {:dbus_variant, :string, "File"}},
           {"children-display", {:dbus_variant, :string, "submenu"}}
         ],
         []
       }},
      {:dbus_variant, dbus_menu_item_type,
       {
         2,
         [
           {"enabled", {:dbus_variant, :boolean, true}},
           {"visible", {:dbus_variant, :boolean, true}},
           {"type", {:dbus_variant, :string, "standard"}},
           {"label", {:dbus_variant, :string, "View"}},
           {"children-display", {:dbus_variant, :string, "submenu"}}
         ],
         []
       }},
      {:dbus_variant, dbus_menu_item_type,
       {
         3,
         [
           {"enabled", {:dbus_variant, :boolean, true}},
           {"visible", {:dbus_variant, :boolean, true}},
           {"type", {:dbus_variant, :string, "standard"}},
           {"label", {:dbus_variant, :string, "Quit"}},
           {"children-display", {:dbus_variant, :string, ""}}
         ],
         []
       }}
    ]

    menu = {
      0,
      [
        {"enabled", {:dbus_variant, :boolean, true}},
        {"visible", {:dbus_variant, :boolean, true}},
        {"type", {:dbus_variant, :string, "standard"}},
        {"children-display", {:dbus_variant, :string, "submenu"}}
      ],
      children
    }

    reply = {:ok, [:uint32, dbus_menu_item_type], [0, menu]}

    {:reply, reply, state}
  end

  def handle_call(
        {:method, "AboutToShow", _args, _context},
        _from,
        state
      ) do
    {:reply, {:ok, [:boolean], [false]}, state}
  end

  def handle_call({:method, "Activate", _args, _context}, _from, state) do
    {:reply, {:ok, [], []}, state}
  end

  def handle_call({:method, method_name, args, context}, _from, state) do
    IO.inspect({method_name, args}, label: "[MyIcon.Config] METHOD call")

    {:reply,
     {:error, "org.freedesktop.DBus.Error.UnknownMethod",
      "Method (#{method_name}) not found on given interface"}, state}
  end
end
