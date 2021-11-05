defmodule ExSni.Menu.Server do
  use GenServer

  alias ExSni.Menu
  alias ExSni.MenuDiff

  defmodule SignalsState do
    defstruct layout_updated: {0, false},
              properties_updated: {0, false},
              activation_request: {0, false}

    @type signal_tracking() ::
            {last_requested_timestamp :: non_neg_integer(), queued? :: boolean()}
    @type t() :: %__MODULE__{
            layout_updated: signal_tracking(),
            properties_updated: signal_tracking(),
            activation_request: signal_tracking()
          }
  end

  defmodule State do
    defstruct menu: %Menu{version: 1},
              signals: %SignalsState{},
              get_layout: {0, false},
              get_group_properties: {0, false},
              last_layout_menu: nil,
              dbus_service: nil,
              menu_queue: [%Menu{version: 1}],
              throttle: 600

    @type t() :: %__MODULE__{
            menu: Menu.t(),
            signals: SignalsState.t(),
            get_layout: non_neg_integer(),
            get_group_properties: non_neg_integer(),
            last_layout_menu: nil | Menu.t(),
            dbus_service: nil | pid() | {:via, atom(), any()},
            menu_queue: list(Menu.t()),
            throttle: non_neg_integer()
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
    init_menu =
      case Keyword.get(options, :menu, nil) do
        %Menu{} = menu -> menu
        _ -> %Menu{version: 1}
      end

    state = %State{menu: init_menu, dbus_service: Keyword.get(options, :dbus_service, nil)}

    {:ok, state}
  end

  def method(server_pid, name, arguments) do
    GenServer.call(server_pid, {:method, name, arguments})
  end

  def get_property(server_pid, property_name) do
    GenServer.call(server_pid, {:get_property, property_name})
  end

  def set(server_pid, menu) do
    GenServer.call(server_pid, {:set, menu, false})
  end

  def get(server_pid) do
    GenServer.call(server_pid, :get)
  end

  def reset(server_pid) do
    GenServer.call(server_pid, {:set, nil, true})
  end

  # GenServer implementations

  @impl true
  def handle_call({:set, menu, force?}, _from, state) do
    IO.inspect("menu", label: "[Menu.Server][set menu]/1 -------------------------")
    handle_set_menu(menu, force?, state)
  end

  def handle_call(:get, _from, %{menu: menu} = state) do
    {:reply, {:ok, menu}, state}
  end

  def handle_call({:method, method_name, arguments}, from, state) do
    IO.inspect({method_name, arguments}, label: "[Menu.Server] received method")
    {reply, ret, state} = handle_method(method_name, arguments, from, state)

    IO.inspect({method_name, arguments}, label: "[Menu.Server] Method will return:")

    {reply, ret, state}
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
  def handle_info(
        :signal_layout_updated,
        %{menu: %{version: version}, dbus_service: dbus_service} = state
      ) do
    send_dbus_signal(dbus_service, "LayoutUpdated", [version, 0])
    {:noreply, state}
  end

  @impl true
  def handle_info(
        {:signal_items_properties_updated, pair},
        %{menu: %{version: version}, dbus_service: dbus_service} = state
      ) do
    send_dbus_signal(dbus_service, "ItemsPropertiesUpdated", pair)
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  # Private methods

  defp get_current_menu(%State{menu_queue: [nil]}) do
    %Menu{version: 1}
  end

  defp get_current_menu(%State{menu_queue: [menu]}) do
    menu
  end

  defp get_current_menu(%State{menu_queue: list}) do
    List.last(list)
  end

  defp fetch_next_menu(%State{menu_queue: [menu]} = state) do
    {menu, state}
  end

  defp fetch_next_menu(%State{menu_queue: list} = state) do
    {menu, list} = List.pop_at(list, -1)
    {menu, %{state | menu_queue: list}}
  end

  defp handle_set_menu(menu, force?, state) do
    set_menu(menu, force?, state)
    |> case do
      {:ok, menu, state} -> {:reply, menu, state}
      {:noop, menu, state} -> {:reply, menu, state}
    end
  end

  defp set_menu(nil, force?, %{menu: %Menu{} = old_menu} = state) do
    set_menu(%{old_menu | root: nil}, force?, state)
  end

  defp set_menu(
         %Menu{root: nil} = _new_menu,
         _force?,
         %{menu: %Menu{root: nil} = old_menu} = state
       ) do
    # Request to reset the menu, but the menu is already reset
    {:noop, old_menu, state}
  end

  defp set_menu(
         %Menu{root: nil} = new_menu,
         force?,
         %{menu: %Menu{version: version, root: old_root} = _old_menu} = state
       ) do
    # Request to reset the menu
    new_menu = %{new_menu | version: version + 1, root: nil}

    state = %{state | menu: new_menu}
    {:ok, new_menu, state}
  end

  defp set_menu(
         %Menu{root: new_root} = new_menu,
         force?,
         %{dbus_service: dbus_service, menu: %Menu{version: version, root: old_root} = _old_menu} =
           state
       ) do
    {layout_update_id, properties_updated, _} = menu_diff = MenuDiff.diff(new_root, old_root)

    menu =
      case menu_diff do
        {-1, [], _} ->
          %{new_menu | version: version}

        {-2, [], new_root} ->
          # This means reset the menu, and then send the new menu
          #
          # Signal LayoutUpdated to nil menu first
          # and after GetLayout, signal the new menu
          # %{new_menu | version: version + 1, root: nil}
          %{new_menu | version: version + 1, root: new_root}

        {_, _, new_root} ->
          %{new_menu | version: version + 1, root: new_root}
      end

    IO.inspect({layout_update_id, properties_updated}, label: "SET MENU DIFF")

    case layout_update_id do
      0 -> Process.send_after(self(), :signal_layout_updated, 3)
      -2 -> Process.send_after(self(), :signal_layout_updated, 3)
      _ -> :ok
    end

    case properties_updated do
      [] ->
        :ok

      list ->
        #  send_dbus_signal(dbus_service, "ItemsPropertiesUpdated", [properties_updated, []])
        Process.send_after(
          self(),
          {:signal_items_properties_updated, [properties_updated, []]},
          5
        )
    end

    state = %{state | menu: menu}
    {:ok, menu, state}
  end

  # defp handle_send_signal(
  #        "LayoutUpdated",
  #        args,
  #        %{signals_sent: signals_sent, menu: menu} = state
  #      ) do
  # end

  # defp send_signal(%{dbus_service: service_pid, signals_sent: signals_sent} = state, signal, args) do
  # end

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
    IO.inspect({signal, args}, label: "[Menu.Server] sending signal to D-Bus")

    ExDBus.Service.send_signal(
      service_pid,
      "/MenuBar",
      "com.canonical.dbusmenu",
      signal,
      args
    )
  end

  # Method handling

  defp handle_method(
         "GetLayout",
         {parentId, depth, properties},
         _from,
         %{signals: signals} = state
       ) do
    # {menu, state} = fetch_next_menu(state)

    %{menu: menu} = state

    state = %{
      state
      | last_layout_menu: menu,
        signals: %{signals | layout_updated: :clear}
    }

    {:reply, method_reply("GetLayout", {parentId, depth, properties}, menu), state}
  end

  defp handle_method("GetGroupProperties", {ids, properties}, _from, %{menu: menu} = state) do
    {:reply, method_reply("GetGroupProperties", {ids, properties}, menu), state}
  end

  # This is called by the applet to notify the application
  # that it is about to show the menu under the specified item.

  # Params:
  #   - id::uint32 - Which menu item represents
  #                 the parent of the item about to be shown.
  # Returns:
  #   - needUpdate::boolean() - Whether this AboutToShow event
  #                   should result in the menu being updated.
  defp handle_method("AboutToShow", id, _from, %{menu: menu} = state) do
    {:reply, method_reply("AboutToShow", id, menu), state}
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
  defp handle_method("Event", {id, eventId, data, timestamp}, _from, %{menu: menu} = state) do
    {:reply, method_reply("Event", {id, eventId, data, timestamp}, menu), state}
  end

  # Reject all other method calls
  defp handle_method(_method, _arguments, _from, state) do
    {:reply, :skip, state}
  end

  defp method_reply("GetLayout", {parentId, depth, properties}, menu) do
    IO.inspect({parentId, depth, properties},
      label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] GetLayout"
    )

    ret = Menu.get_layout(menu, parentId, depth, properties)

    # IO.inspect(ret, label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] GetLayout")
    ret
  end

  defp method_reply("GetGroupProperties", {ids, properties}, menu) do
    IO.inspect({ids, properties},
      label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] GetGroupProperties"
    )

    result = Menu.get_group_properties(menu, ids, properties)

    # IO.inspect(result,
    #   label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] GOT GetGroupProperties"
    # )

    {:ok, [{:array, {:struct, [:int32, {:dict, :string, :variant}]}}], [result]}
  end

  defp method_reply("AboutToShow", id, menu) do
    ret = Menu.onAboutToShow(menu, id)
    {:ok, [:boolean], [ret]}
  end

  defp method_reply("Event", {id, eventId, data, timestamp}, menu) do
    IO.inspect({id, eventId, data, timestamp},
      label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] Menu OnEvent"
    )

    Menu.onEvent(menu, eventId, id, data, timestamp)
    {:ok, [], []}
  end

  defp method_reply(_, _, _) do
    :skip
  end

  defp now() do
    System.monotonic_time(:millisecond)
  end

  # def handle_info(
  #       {:before_method, listeners, method_name, arguments, from},
  #       %{before: before_listeners} = state
  #     ) do
  #   case run_listeners(listeners, {:method, method_name, arguments}) do
  #     {:halt, ret, listeners} ->
  #       GenServer.reply(from, ret)
  #       queue_after_method(self(), method_name, arguments, ret)
  #       {:noreply, Map.put(state, :before, Enum.concat(listeners, before_listeners))}

  #     _ ->
  #       Process.send_after(self(), {:run_method, method_name, arguments, from}, 10)
  #       {:noreply, state}
  #   end
  # end

  # def handle_info({:run_method, method_name, arguments, from}, state) do
  #   case run_method(method_name, arguments, from, state) do
  #     {:noreply, state} ->
  #       {:noreply, state}

  #     {:reply, ret, state} ->
  #       GenServer.reply(from, ret)
  #       {:noreply, state}
  #   end
  # end

  # def handle_info({:after_method, _, _, _ret}, %{after: []} = state) do
  #   {:noreply, state}
  # end

  # def handle_info(
  #       {:after_method, method_name, arguments, _ret},
  #       %{after: after_listeners} = state
  #     ) do
  #   case match_listeners(after_listeners, {:method, method_name}) do
  #     {[], list} ->
  #       {:noreply, Map.put(state, :after, list)}

  #     {listeners, list} ->
  #       run_listeners(listeners, {:method, method_name, arguments})
  #       {:noreply, Map.put(state, :after, list)}
  #   end
  # end

  # def handle_info(_, state) do
  #   {:noreply, state}
  # end

  # defp run_method(method_name, arguments, from, state) do
  #   case handle_method(method_name, arguments, from, state) do
  #     {:reply, ret, state} ->
  #       queue_after_method(self(), method_name, arguments, ret)
  #       {:reply, ret, state}

  #     _ ->
  #       queue_after_method(self(), method_name, arguments, nil)
  #       {:noreply, state}
  #   end
  # end

  # defp queue_after_method(pid, method_name, arguments, ret) do
  #   Process.send_after(pid, {:after_method, method_name, arguments, ret}, 10)
  # end

  # defp match_listeners([], _pattern) do
  #   {[], []}
  # end

  # defp match_listeners(
  #        [{:method, method, _, _} = listener | list],
  #        {:method, method} = pattern
  #      ) do
  #   {runnable, keep} = match_listeners(list, pattern)
  #   {[listener | runnable], keep}
  # end

  # defp match_listeners([listener | list], pattern) do
  #   {runnable, keep} = match_listeners(list, pattern)
  #   {runnable, [listener | keep]}
  # end

  # # Before task handling
  # defp run_listeners([], _pattern) do
  #   :ok
  # end

  # defp run_listeners(
  #        [{_, _, listener, await} | list],
  #        {:method, _method, _arguments} = pattern
  #      ) do
  #   # Execute the before task
  #   case run_listener(listener, pattern, Enum.count(list), await) do
  #     {:reply, menu} ->
  #       {:halt, menu, list}

  #     _ ->
  #       run_listeners(list, pattern)
  #   end
  # end

  # defp run_listener(listener, pattern, num_remaining, await, timeout \\ 1000)

  # defp run_listener({:via, _, _} = listener, pattern, await, num_remaining, timeout) do
  #   signal_listener(listener, pattern, num_remaining, await, timeout)
  # end

  # defp run_listener(pid, pattern, num_remaining, await, timeout)
  #      when is_pid(pid) or is_atom(pid) do
  #   signal_listener(pid, pattern, num_remaining, await, timeout)
  # end

  # defp run_listener(callback, {_, _, arguments}, num_remaining, _, _)
  #      when is_function(callback) do
  #   callback.(arguments, num_remaining)
  # end

  # defp run_listener(_, _, _, _, _) do
  #   :noreply
  # end

  # defp signal_listener(dest, arguments, _num_remaining, _, 0) do
  #   Process.send(dest, {arguments, self()}, [:noconnect])
  # end

  # defp signal_listener(dest, arguments, _num_remaining, :await, timeout) do
  #   if Process.send(dest, {arguments, self()}, [:noconnect]) == :noconnect do
  #     :noconnect
  #   else
  #     receive do
  #       {:reply, value} -> {:reply, value}
  #       _ -> :noreply
  #     after
  #       timeout -> :timeout
  #     end
  #   end
  # end

  # defp signal_listener(dest, arguments, _num_remaining, _, _) do
  #   Process.send(dest, {arguments, self()}, [:noconnect])
  # end
end
