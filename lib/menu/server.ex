defmodule ExSni.Menu.Server do
  @moduledoc false

  use GenServer

  alias ExSni.Menu

  defmodule SignalsState do
    defstruct layout_updated: {0, false},
              items_properties_updated: {0, false},
              activation_request: {0, false}

    @type signal_tracking() ::
            {last_requested_timestamp :: non_neg_integer(), queued? :: boolean()}
    @type t() :: %__MODULE__{
            layout_updated: signal_tracking(),
            items_properties_updated: signal_tracking(),
            activation_request: signal_tracking()
          }
  end

  defmodule State do
    defstruct menu: %Menu{version: 1},
              backup_server: nil,
              dbus_service: nil,
              menu_queue: []

    @type method_tracking() ::
            {last_requested_timestamp :: non_neg_integer(), payload :: any()}
    @type t() :: %__MODULE__{
            menu: Menu.t(),
            backup_server: nil | GenServer.server(),
            dbus_service: nil | GenServer.server(),
            menu_queue: list(Menu.t())
          }
  end

  def start_link(opts, gen_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      gen_opts
    )
  end

  @impl true
  def init(options) do
    backup_server = Keyword.get(options, :backup_server)

    init_menu =
      case Keyword.get(options, :menu, nil) do
        %Menu{} = menu -> menu
        _ -> %Menu{version: 1}
      end

    state =
      %State{
        menu: init_menu,
        dbus_service: Keyword.get(options, :dbus_service, nil),
        backup_server: backup_server
      }
      |> restore_backup_menu()

    {:ok, state}
  end

  def method(server_pid, name, arguments) do
    GenServer.call(server_pid, {:method, name, arguments})
  end

  def get_property(server_pid, property_name) do
    GenServer.call(server_pid, {:get_property, property_name})
  end

  def set(server_pid, menu) do
    GenServer.cast(server_pid, {:set, menu})
  end

  def get(server_pid) do
    GenServer.call(server_pid, :get)
  end

  def reset(server_pid) do
    GenServer.cast(server_pid, {:set, nil})
  end

  # GenServer implementations

  @impl true
  def handle_cast({:set, menu}, state) do
    state =
      case add_menu_to_queue(state, menu) do
        %{menu_queue: [_ | _]} = state ->
          queue_menu_update(state)

        _ ->
          state
      end

    {:noreply, state}
  end

  @impl true
  def handle_call(:get, _from, %{menu: menu} = state) do
    {:reply, {:ok, menu}, state}
  end

  def handle_call({:method, method_name, arguments}, from, state) do
    handle_method(method_name, arguments, from, state)
  end

  def handle_call(
        {:get_property, property_name},
        _from,
        %{menu: menu} = state
      ) do
    ret = ExSni.DbusProtocol.get_property(menu, property_name)
    {:reply, ret, state}
  end

  def handle_call(
        {:get_property, _property_name},
        _from,
        state
      ) do
    {:reply, {:error, "org.freedesktop.DBus.Error.UnknownProperty", "Invalid property"}, state}
  end

  @impl true
  def handle_info(:menu_update, state) do
    case do_menu_update(state) do
      {:skip, state} ->
        {:noreply, state}

      {:ok, state} ->
        {:noreply, state}
    end
  end

  def handle_info(
        {:signal_layout_updated, [version, item_id]},
        %{dbus_service: dbus_service} = state
      ) do
    Debouncer.immediate(
      {__MODULE__, self(), "LayoutUpdated"},
      fn ->
        send_dbus_signal(dbus_service, "LayoutUpdated", [version, item_id])
      end,
      3000
    )

    {:noreply, state}
  end

  def handle_info(
        {:signal_items_properties_updated, [properties_updated, properties_removed]},
        %{dbus_service: dbus_service} = state
      ) do
    send_dbus_signal(dbus_service, "ItemsPropertiesUpdated", [
      properties_updated,
      properties_removed
    ])

    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  # Private methods

  # Menu queue is empty, so current menu is still valid
  # Return that we want to skip any dbus menu updates
  defp do_menu_update(%{menu_queue: []} = state) do
    {:skip, state}
  end

  # Current menu is nil and a reset is queued
  # Skip the reset and try again
  defp do_menu_update(%{menu: %Menu{root: nil}, menu_queue: [:reset | menu_queue]} = state) do
    state
    |> set_menu_queue(menu_queue)
    |> do_menu_update()
  end

  # There is a reset pending, and the current menu is not empty
  # Action on the reset.
  defp do_menu_update(
         %{menu: %Menu{version: old_version} = old_menu, menu_queue: [:reset | menu_queue]} =
           state
       ) do
    # Increment the version of an empty menu
    menu = %Menu{old_menu | root: nil, version: old_version + 1}

    # Update the queue
    # Send a LayoutUpdated signal, so that D-Bus can fetch the new empty menu

    {:ok,
     state
     |> set_current_menu(menu)
     |> set_menu_queue(menu_queue)}
  end

  # Current menu is nil, no reset pending and full new menu
  defp do_menu_update(
         %{menu: %Menu{version: old_version}, menu_queue: [{:nodiff, new_menu}]} = state
       ) do
    if menu_empty?(new_menu) do
      {:skip, set_menu_queue(state, [])}
    else
      menu = %Menu{new_menu | version: old_version + 1}
      # Update the queue
      # Send a LayoutUpdated signal, so that D-Bus can fetch the new empty menu
      {:ok,
       state
       |> set_current_menu(menu)
       |> set_menu_queue([])}
    end
  end

  # No reset pending, just a possible menu update
  defp do_menu_update(
         %{
           menu: %Menu{version: old_version},
           menu_queue: [%Menu{} = new_menu]
         } = state
       ) do
    if menu_empty?(new_menu) do
      {:skip, set_menu_queue(state, [])}
    else
      menu = %Menu{new_menu | version: old_version + 1}
      # Update the queue
      # Send a LayoutUpdated signal, so that D-Bus can fetch the new empty menu
      {:ok,
       state
       |> set_current_menu(menu)
       |> set_menu_queue([])}
    end
  end

  defp queue_menu_update(state) do
    pid = self()

    Debouncer.immediate(
      {__MODULE__, pid, :menu_update},
      fn ->
        send(pid, :menu_update)
      end,
      1000
    )

    state
  end

  defp trigger_layout_update_signal(%{menu: %Menu{version: version}} = state, item_id \\ 0) do
    send(self(), {:signal_layout_updated, [version, item_id]})
    state
  end

  defp send_dbus_signal(service_pid, "LayoutUpdated" = signal, args) do
    service_send_signal(service_pid, signal, {"ui", [:uint32, :int32], args})
  end

  defp send_dbus_signal(service_pid, "ItemsPropertiesUpdated" = signal, args) do
    service_send_signal(service_pid, signal, {
      "a(ia{sv})a(ias)",
      [
        {:array, {:struct, [:int32, {:dict, :string, :variant}]}},
        {:array, {:struct, [:int32, {:array, :string}]}}
      ],
      args
    })
  end

  defp service_send_signal(service_pid, signal, args) do
    # IO.inspect([signal, args], label: "Sending D-Bus signal", limit: :infinity)

    ExDBus.Service.send_signal(
      service_pid,
      "/MenuBar",
      "com.canonical.dbusmenu",
      signal,
      args
    )
  end

  # Method handling

  defp handle_method("GetLayout", {parentId, depth, properties}, _from, state) do
    {:reply, method_reply("GetLayout", {parentId, depth, properties}, state), state}
  end

  defp handle_method("GetGroupProperties", {ids, properties}, _from, state) do
    {:reply, method_reply("GetGroupProperties", {ids, properties}, state), state}
  end

  # This is called by the applet to notify the application
  # that it is about to show the menu under the specified item.

  # Params:
  #   - id::uint32 - Which menu item represents
  #                 the parent of the item about to be shown.
  # Returns:
  #   - needUpdate::boolean() - Whether this AboutToShow event
  #                   should result in the menu being updated.
  defp handle_method("AboutToShow", id, _from, state) do
    {:reply, method_reply("AboutToShow", id, state), state}
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
  defp handle_method("Event", {id, eventId, data, timestamp}, _from, state) do
    {:reply, method_reply("Event", {id, eventId, data, timestamp}, state), state}
  end

  # Reject all other method calls
  defp handle_method(_method, _arguments, _from, state) do
    {:reply, :skip, state}
  end

  defp method_reply("GetLayout", {parentId, depth, properties}, %{menu: menu}) do
    # IO.inspect({parentId, depth, properties},
    #   label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] GetLayout"
    # )

    Menu.get_layout(menu, parentId, depth, properties)
    # |> IO.inspect(label: "GetLayout reply", limit: :infinity)
  end

  defp method_reply("GetGroupProperties", {ids, properties}, %{menu: menu}) do
    # IO.inspect({ids, properties},
    #   label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] GetGroupProperties"
    # )

    result = Menu.get_group_properties(menu, ids, properties)
    # |> IO.inspect(label: "GetGroupProperties reply", limit: :infinity)

    {:ok, [{:array, {:struct, [:int32, {:dict, :string, :variant}]}}], [result]}
  end

  defp method_reply("AboutToShow", id, %{menu: menu}) do
    ret = Menu.onAboutToShow(menu, id)
    {:ok, [:boolean], [ret]}
  end

  defp method_reply("Event", {id, eventId, data, timestamp}, %{menu: menu}) do
    # IO.inspect({id, eventId, data, timestamp},
    #   label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] Menu OnEvent"
    # )

    Menu.onEvent(menu, eventId, id, data, timestamp)
    {:ok, [], []}
  end

  defp method_reply(_, _, _) do
    :skip
  end

  # Other private functions

  # A menu queue (`menu_queue`) holds the next menus to process
  # Queueing a menu will always take care of pruning the menu queue so that
  # it would only hold the bare minimum to process on next round.
  #
  # There are only 3 types of queued menus:
  # - An empty menu (where root is nil, or the root element has no children)
  # - A menu that holds items
  # - :reset - a special entry that means we need to force sending an empty menu to DBus
  # so that it would clear up the current menu. This entry must never be removed from the queue
  # once it has been set. It can only be consumed by menu processing.
  #
  # The queue is always either empty or contains two queued entries at most:
  # - 0 entries:  No changes queued; the current dbus menu
  #               can be either in a nil/cleared state or have items
  # - 1 entry:    One change queued
  # - 2 entries:  This is always going to be a `:reset` followed by a non-empty menu
  #               menu_queue = [:reset, non_empty_menu]
  #
  # Queuing the menus with the below functions,
  # must always ensure the correct format for the menu_queue.
  # Never store multiple :reset entries in the queue.
  #
  # If for example, menu_queue == [:reset] then we never remove it from the queue
  # and never push empty menus or further resets after it.
  # If menu_queue == [:reset, non_empty_menu] then if we want to queue an empty menu
  # we just take the non_empty_menu out, leaving menu_queue = [:reset]. However, when
  # the menu we want to queue is not an empty menu, we only replace the non_empty_menu entry
  # leaving menu_queue = [:reset, new_non_empty_menu]
  # If menu_queue == [non_empty_menu] we replace it with whatever we want to queue,
  # setting menu_queue = [new_menu], regardless if the new menu is empty, non-empty or a reset

  # Handle queueing :reset
  defp add_menu_to_queue(%{menu_queue: _queue, menu: _current_menu} = state, :reset) do
    # Reset is very straight-forward when queueing.

    # Clear the queue and add :reset to it
    set_menu_queue(state, [:reset])
  end

  # Handling of empty menus that do not have root: nil, but have a root without children

  defp add_menu_to_queue(state, %Menu{root: %Menu.Item{type: :root, children: []}} = new_menu) do
    # Menu is actually empty, because there are no children in the root item
    # Forward it as %Menu{root: nil}
    add_menu_to_queue(state, {:nodiff, new_menu})
  end

  defp add_menu_to_queue(
         state,
         {:nodiff, %Menu{root: %Menu.Item{type: :root, children: []}} = new_menu}
       ) do
    # Menu is actually empty, because there are no children in the root item
    # Forward it as %Menu{root: nil}
    add_menu_to_queue(state, {:nodiff, %{new_menu | root: nil}})
  end

  # Handle queueing nil menu
  defp add_menu_to_queue(
         state,
         %Menu{root: nil} = empty_menu
       ) do
    add_menu_to_queue(state, {:nodiff, empty_menu})
  end

  defp add_menu_to_queue(
         %{menu_queue: queue, menu: current_menu} = state,
         {:nodiff, %Menu{root: nil} = empty_menu}
       ) do
    case queue do
      [] ->
        # Handle empty queue
        if menu_empty?(current_menu) do
          # Do not update D-Bus with empty menus if the current D-Bus menu is already empty.
          state
        else
          set_menu_queue(state, [{:nodiff, empty_menu}])
        end

      [:reset] ->
        # The reset will also clear the current menu, just as the empty menu would do,
        # but it's an enforced clear that we need to keep
        state

      [%Menu{}] ->
        if menu_empty?(current_menu) do
          # The current menu is already cleared, so clear the queue
          set_menu_queue(state, [])
        else
          # The current menu is non-empty. Queue clearing the menu
          set_menu_queue(state, [{:nodiff, empty_menu}])
        end

      [{:nodiff, %Menu{}}] ->
        if menu_empty?(current_menu) do
          # The current menu is already cleared, so clear the queue
          set_menu_queue(state, [])
        else
          # The current menu is non-empty. Queue clearing the menu
          set_menu_queue(state, [{:nodiff, empty_menu}])
        end

      [_, :reset] ->
        # If there is a reset queued, regardless of the next item in queue,
        # because we ask to update to an empty menu, keep the :reset only
        set_menu_queue(state, [:reset])
    end
  end

  # Queue non-empty menu when the queue is empty
  defp add_menu_to_queue(%{menu_queue: []} = state, {:nodiff, %Menu{} = new_menu}) do
    # Just add it to the queue
    set_menu_queue(state, [{:nodiff, new_menu}])
  end

  defp add_menu_to_queue(%{menu_queue: []} = state, %Menu{} = new_menu) do
    # Just add it to the queue
    set_menu_queue(state, [new_menu])
  end

  # Queue non-empty menu when there's a reset in the queue
  defp add_menu_to_queue(%{menu_queue: [:reset | _]} = state, {:nodiff, %Menu{} = new_menu}) do
    set_menu_queue(state, [:reset, {:nodiff, new_menu}])
  end

  defp add_menu_to_queue(%{menu_queue: [:reset | _]} = state, %Menu{} = new_menu) do
    set_menu_queue(state, [:reset, new_menu])
  end

  # Queue non-empty menu when there's another menu in the queue
  defp add_menu_to_queue(%{menu_queue: [_]} = state, {:nodiff, %Menu{} = new_menu}) do
    # There is a non-empty menu queued. Replace it
    set_menu_queue(state, [{:nodiff, new_menu}])
  end

  defp add_menu_to_queue(%{menu_queue: [_]} = state, %Menu{} = new_menu) do
    # There is a non-empty menu queued. Replace it
    set_menu_queue(state, [new_menu])
  end

  defp set_current_menu(
         %State{menu: %{item_cache: items} = old_menu} = state,
         %Menu{root: root} = menu
       ) do
    root = strip_menu(root)

    if old_menu != nil and strip_menu(old_menu.root) == root do
      state
    else
      {last_id, version} =
        case old_menu do
          %Menu{last_id: last_id, version: version} -> {max(last_id, 100), version}
          nil -> {100, 1}
        end

      cache = Enum.map(items, fn {item, _time} -> {strip_menu(item), item} end) |> Map.new()
      {root, last_id} = update_menu(root, last_id, cache)

      menu = %Menu{menu | version: version + 1, last_id: last_id, root: root}
      now = System.os_time(:millisecond)

      new_items =
        Menu.get_children(old_menu)
        |> Enum.map(fn item -> {item, now} end)
        |> Map.new()

      items =
        Enum.reject(items, fn {_, time} -> now - time > 10_000 end)
        |> Map.new()
        |> Map.merge(new_items)

      backup_current_menu(%State{state | menu: Map.put(menu, :item_cache, items)})
      |> trigger_layout_update_signal()
    end
  end

  defp update_menu(%Menu.Item{children: children} = item, id, cache) do
    {children, id} =
      Enum.map_reduce(children, id, fn item = %Menu.Item{type: type}, id ->
        case cache[item] do
          nil ->
            id = id + 1
            item = Menu.Item.set_id(item, id)

            if type == :menu do
              update_menu(item, id, cache)
            else
              {item, id}
            end

          old_item ->
            {old_item, id}
        end
      end)

    {%Menu.Item{item | children: children}, id}
  end

  defp strip_menu(nil), do: nil

  defp strip_menu(%Menu.Item{children: children} = item) do
    children =
      Enum.map(children, fn item = %Menu.Item{type: type} ->
        item = Menu.Item.set_id(item, nil)

        if type == :menu do
          strip_menu(item)
        else
          item
        end
      end)

    %Menu.Item{item | children: children}
  end

  defp restore_backup_menu(%{backup_server: nil} = state) do
    state
  end

  defp restore_backup_menu(%{backup_server: server, menu: init_menu} = state) do
    try do
      menu = GenServer.call(server, {:restore_menu, init_menu})
      %{state | menu: menu}
    rescue
      _error -> state
    end
  end

  defp backup_current_menu(%{backup_server: nil} = state) do
    state
  end

  defp backup_current_menu(%{backup_server: server, menu: menu} = state) do
    try do
      GenServer.cast(server, {:save_menu, menu})
    rescue
      _ -> :ok
    end

    state
  end

  defp set_menu_queue(state, queue) do
    %{state | menu_queue: queue}
  end

  defp menu_empty?(nil) do
    true
  end

  defp menu_empty?({:nodiff, menu}) do
    menu_empty?(menu)
  end

  defp menu_empty?(%Menu{root: nil}) do
    true
  end

  defp menu_empty?(%Menu{root: %Menu.Item{type: :root, children: []}}) do
    true
  end

  defp menu_empty?(%Menu{root: %Menu.Item{}}) do
    false
  end
end
