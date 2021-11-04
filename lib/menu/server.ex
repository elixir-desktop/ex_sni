defmodule ExSni.Menu.Server do
  use GenServer

  alias ExSni.Menu

  def start_link(opts, gen_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      gen_opts
    )
  end

  @impl true
  def init(menus) when is_list(menus) do
    state = %{
      menus: menus,
      before: [],
      after: [],
      options: %{},
      is_setting_menu?: false,
      pending_menus: []
    }

    {:ok, state}
  end

  def set_option(server_pid, key, value) do
    GenServer.call(server_pid, {:set_option, key, value})
  end

  def get_option(server_pid, key, default \\ nil) do
    GenServer.call(server_pid, {:get_option, key, default})
  end

  def unset_option(server_pid, key) do
    GenServer.call(server_pid, {:unset_option, key})
  end

  def has_option?(server_pid, key) do
    GenServer.call(server_pid, {:has_option?, key})
  end

  def method(server_pid, name, arguments) do
    GenServer.call(server_pid, {:method, name, arguments})
  end

  def get_property(server_pid, property_name) do
    GenServer.call(server_pid, {:get_property, property_name})
  end

  def set_menu(server_pid, menu) do
    GenServer.call(server_pid, {:set_menu, menu})
  end

  def get_menu(server_pid) do
    GenServer.call(server_pid, :get_menu)
  end

  def register_before_method(server_pid, method, listener, await \\ false)

  def register_before_method(server_pid, method, listener, true) do
    GenServer.cast(server_pid, {:register_before_method, method, listener, :await})
  end

  def register_before_method(server_pid, method, listener, _) do
    GenServer.cast(server_pid, {:register_before_method, method, listener, :nowait})
  end

  def register_after_method(server_pid, method, listener) do
    GenServer.cast(server_pid, {:register_after_method, method, listener})
  end

  @impl true

  def handle_cast(
        {:register_before_method, method, listener, await},
        %{before: listeners} = state
      ) do
    state = Map.put(state, :before, [{:method, method, listener, await} | listeners])
    {:noreply, state}
  end

  def handle_cast(
        {:register_after_method, method, listener},
        %{after: listeners} = state
      ) do
    state = Map.put(state, :after, [{:method, method, listener, :nowait} | listeners])
    {:noreply, state}
  end

  @impl true
  def handle_call({:set_menu, menu}, _from, %{menus: _menus} = state) do
    IO.inspect("", label: "[Menu.Server][set_menu]/1 -------------------------")
    {:reply, {:ok, menu}, Map.put(state, :menus, [menu])}
  end

  def handle_call(:get_menu, _from, %{menus: [menu | _]} = state) do
    {:reply, {:ok, menu}, state}
  end

  def handle_call({:method, method_name, arguments}, from, %{before: []} = state) do
    # IO.inspect({method_name, arguments}, label: "[Menu][Server] received method")
    run_method(method_name, arguments, from, state)
  end

  def handle_call(
        {:method, method_name, arguments},
        from,
        %{before: [_ | _] = before_listeners} = state
      ) do
    case match_listeners(before_listeners, {:method, method_name}) do
      {[], list} ->
        run_method(method_name, arguments, from, Map.put(state, :before, list))

      {listeners, list} ->
        Process.send_after(self(), {:before_method, listeners, method_name, arguments, from}, 10)
        {:noreply, Map.put(state, :before, list)}
    end
  end

  def handle_call(
        {:get_property, property_name},
        _from,
        %{menus: [%Menu{} = menu | _]} = state
      ) do
    # IO.inspect(property_name,
    #   label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] Menu GetProperty"
    # )

    ret = ExSni.DbusProtocol.get_property(menu, property_name)
    {:reply, ret, state}
  end

  def handle_call(
        {:get_property, _property_name},
        _from,
        state
      ) do
    # IO.inspect(property_name,
    #   label: "[#{System.os_time(:millisecond)}] [ExSni][Menu.Server] Menu GetProperty"
    # )

    {:reply, {:error, "org.freedesktop.DBus.Error.UnknownProperty", "Invalid property"}, state}
  end

  def handle_call({:has_option?, key}, _from, %{options: options} = state) do
    {:reply, Map.has_key?(options, key), state}
  end

  def handle_call({:get_option, key, default}, _from, %{options: options} = state) do
    {:reply, Map.get(options, key, default), state}
  end

  def handle_call({:set_option, key, value}, _from, %{options: options} = state) do
    {:reply, value, Map.put(state, :options, Map.put(options, key, value))}
  end

  def handle_call({:unset_option, key}, _from, %{options: options} = state) do
    value = Map.get(options, key)
    {:reply, value, Map.put(state, :options, Map.delete(options, key))}
  end

  @impl true
  def handle_info(
        {:before_method, listeners, method_name, arguments, from},
        %{before: before_listeners} = state
      ) do
    case run_listeners(listeners, {:method, method_name, arguments}) do
      {:halt, ret, listeners} ->
        GenServer.reply(from, ret)
        queue_after_method(self(), method_name, arguments, ret)
        {:noreply, Map.put(state, :before, Enum.concat(listeners, before_listeners))}

      _ ->
        Process.send_after(self(), {:run_method, method_name, arguments, from}, 10)
        {:noreply, state}
    end
  end

  def handle_info({:run_method, method_name, arguments, from}, state) do
    case run_method(method_name, arguments, from, state) do
      {:noreply, state} ->
        {:noreply, state}

      {:reply, ret, state} ->
        GenServer.reply(from, ret)
        {:noreply, state}
    end
  end

  def handle_info({:after_method, _, _, _ret}, %{after: []} = state) do
    {:noreply, state}
  end

  def handle_info({:after_method, method_name, arguments, _ret}, %{after: after_listeners} = state) do
    case match_listeners(after_listeners, {:method, method_name}) do
      {[], list} ->
        {:noreply, Map.put(state, :after, list)}

      {listeners, list} ->
        run_listeners(listeners, {:method, method_name, arguments})
        {:noreply, Map.put(state, :after, list)}
    end
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  defp run_method(method_name, arguments, from, state) do
    case handle_method(method_name, arguments, from, state) do
      {:reply, ret, state} ->
        queue_after_method(self(), method_name, arguments, ret)
        {:reply, ret, state}

      _ ->
        queue_after_method(self(), method_name, arguments, nil)
        {:noreply, state}
    end
  end

  defp queue_after_method(pid, method_name, arguments, ret) do
    Process.send_after(pid, {:after_method, method_name, arguments, ret}, 10)
  end

  defp match_listeners([], _pattern) do
    {[], []}
  end

  defp match_listeners(
         [{:method, method, _, _} = listener | list],
         {:method, method} = pattern
       ) do
    {runnable, keep} = match_listeners(list, pattern)
    {[listener | runnable], keep}
  end

  defp match_listeners([listener | list], pattern) do
    {runnable, keep} = match_listeners(list, pattern)
    {runnable, [listener | keep]}
  end

  # Before task handling
  defp run_listeners([], _pattern) do
    :ok
  end

  defp run_listeners(
         [{_, _, listener, await} | list],
         {:method, _method, _arguments} = pattern
       ) do
    # Execute the before task
    case run_listener(listener, pattern, Enum.count(list), await) do
      {:reply, menu} ->
        {:halt, menu, list}

      _ ->
        run_listeners(list, pattern)
    end
  end

  defp run_listener(listener, pattern, num_remaining, await, timeout \\ 1000)

  defp run_listener({:via, _, _} = listener, pattern, await, num_remaining, timeout) do
    signal_listener(listener, pattern, num_remaining, await, timeout)
  end

  defp run_listener(pid, pattern, num_remaining, await, timeout)
       when is_pid(pid) or is_atom(pid) do
    signal_listener(pid, pattern, num_remaining, await, timeout)
  end

  defp run_listener(callback, {_, _, arguments}, num_remaining, _, _)
       when is_function(callback) do
    callback.(arguments, num_remaining)
  end

  defp run_listener(_, _, _, _, _) do
    :noreply
  end

  defp signal_listener(dest, arguments, _num_remaining, _, 0) do
    Process.send(dest, {arguments, self()}, [:noconnect])
  end

  defp signal_listener(dest, arguments, _num_remaining, :await, timeout) do
    if Process.send(dest, {arguments, self()}, [:noconnect]) == :noconnect do
      :noconnect
    else
      receive do
        {:reply, value} -> {:reply, value}
        _ -> :noreply
      after
        timeout -> :timeout
      end
    end
  end

  defp signal_listener(dest, arguments, _num_remaining, _, _) do
    Process.send(dest, {arguments, self()}, [:noconnect])
  end

  # Method handling

  defp handle_method(
         "GetLayout",
         {parentId, depth, properties},
         _from,
         %{menus: [menu | _]} = state
       ) do
    {:reply, method_reply("GetLayout", {parentId, depth, properties}, menu), state}
  end

  defp handle_method("GetGroupProperties", {ids, properties}, _from, %{menus: [menu | _]} = state) do
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
  defp handle_method("AboutToShow", id, _from, %{menus: [menu | _]} = state) do
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
  defp handle_method("Event", {id, eventId, data, timestamp}, _from, %{menus: [menu | _]} = state) do
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
end
