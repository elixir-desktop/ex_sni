defmodule ExSni.Debugger do
  @module """
  Debugger module that attaches to telemetry events.
  Configurable using the EXSNI_DEBUG environment variable, with the following events,
  given as a comma-separated list:
  - menu_diff - Outputs the old menu structure, the new menu structure, and the diff result
  - menu_update - Outputs branch and menu update structures
  - menu_set - Outputs the structure that is set as the current menu
  - dbus_method - Outputs D-Bus method calls and replies
  - dbus_signal - Outputs D-Bus signals sent
  - menu - alias for "menu_diff,menu_update,menu_set" (all menu events)
  - dbus - alias for "dbus_method,dbus_signal" (all dbus events)
  - all - alias for "menu,dbus" (all events)
  """
  require Logger

  @debug_env_name "EXSNI_DEBUG"

  def init(_opts \\ []) do
    get_debug_options()
    |> Enum.each(fn metric ->
      unique_id =
        metric
        |> Enum.map(&Atom.to_string/1)
        |> Enum.join("_")

      :telemetry.attach(
        unique_id,
        metric,
        &handle_event/4,
        nil
      )
    end)
  end

  # Menu Diff telemetry
  def handle_event(
        [:ex_sni, :menu_diff, :branch],
        _metrics,
        %{
          branch: branch,
          description: description,
          layout_changes: layout_changes,
          items_updated_properties_signal: item_updates,
          params: _params,
          new_root: new_root,
          old_root: old_root
        },
        _config
      ) do
    xml_new_root = ExSni.Menu.Debug.debug_root(new_root)
    xml_old_root = ExSni.Menu.Debug.debug_root(old_root)

    {"ex_sni", [{"timestamp", "#{now()}"}],
     [
       {"menu_diff",
        [
          {"branch", "#{branch}"},
          {"layout_changes", "#{inspect(layout_changes)}"},
          {"item_updates", "#{inspect(item_updates)}"},
          {"description", "#{description}"}
        ],
        [
          "<old_root>#{xml_old_root}</old_root><new_root>#{xml_new_root}</new_root>"
        ]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :menu_diff, :result],
        _metrics,
        %{
          branch: branch,
          description: description,
          layout_changes: layout_changes,
          items_updated_properties_signal: item_updates,
          code: code,
          node: node
        },
        _config
      ) do
    xml_node = ExSni.Menu.Debug.debug_root(node)

    {"ex_sni", [{"timestamp", "#{now()}"}],
     [
       {"menu_diff_result",
        [
          {"branch", "#{branch}"},
          {"code", "#{code}"},
          {"layout_changes", "#{inspect(layout_changes)}"},
          {"item_updates", "#{inspect(item_updates)}"},
          {"description", "#{description}"}
        ],
        [
          "<node>#{xml_node}</node>"
        ]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  # ExSni.Menu.Server metrics

  def handle_event(
        [:ex_sni, :do_menu_update],
        _metrics,
        %{
          branch: branch,
          description: description,
          menu_queue: menu_queue,
          returns: returns,
          new_root: new_root,
          old_root: old_root
        },
        _config
      ) do
    xml_new_root =
      if is_atom(new_root) do
        Atom.to_string(new_root)
      else
        ExSni.Menu.Debug.debug_root(new_root)
      end

    xml_old_root = ExSni.Menu.Debug.debug_root(old_root)

    {"ex_sni", [{"timestamp", "#{now()}"}],
     [
       {"do_menu_update",
        [
          {"branch", "#{branch}"},
          {"menu_queue", "#{inspect(menu_queue)}"},
          {"returns", "#{inspect(returns)}"},
          {"description", "#{description}"}
        ],
        [
          "<old_root>#{xml_old_root}</old_root><new_root>#{xml_new_root}</new_root>"
        ]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :send_dbus_signal],
        _metrics,
        %{signal: "LayoutUpdated", args: args},
        _config
      ) do
    xml_updates =
      args
      |> ExSni.Menu.Debug.parse_signal_layout_updated()
      |> Saxy.encode!()

    {"dbus", [{"timestamp", "#{now()}"}],
     [
       "#{xml_updates}"
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :send_dbus_signal],
        _metrics,
        %{signal: "ItemsPropertiesUpdated", args: args},
        _config
      ) do
    xml_updates =
      args
      |> ExSni.Menu.Debug.parse_signal_items_properties_updated()
      |> Saxy.encode!()

    {"dbus", [{"timestamp", "#{now()}"}],
     [
       "#{xml_updates}"
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :dbus_method, :call],
        _metrics,
        %{method: "GetLayout", args: {id, depth, properties}},
        _config
      ) do
    xml_item =
      {"get_layout",
       [{"item_id", "#{id}"}, {"depth", "#{depth}"}, {"properties", Enum.join(properties, ",")}],
       []}
      |> Saxy.encode!()

    {"dbus", [{"timestamp", "#{now()}"}],
     [
       {"method_call", [{"name", "GetLayout"}], ["#{xml_item}"]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :dbus_method, :call],
        _metrics,
        %{method: "GetGroupProperties", args: {ids, properties}},
        _config
      ) do
    xml_item =
      {"get_group_properties",
       [{"ids", Enum.join(ids, ",")}, {"properties", Enum.join(properties, ",")}], []}
      |> Saxy.encode!()

    {"dbus", [{"timestamp", "#{now()}"}],
     [
       {"method_call", [{"name", "GetGroupProperties"}], ["#{xml_item}"]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :dbus_method, :reply],
        _metrics,
        %{method: "GetLayout", response: response},
        _config
      ) do
    xml_layout =
      response
      |> ExSni.Menu.Debug.parse_layout_response()
      |> Saxy.encode!()

    {"dbus", [{"timestamp", "#{now()}"}],
     [
       {"method_reply", [{"name", "GetLayout"}], ["#{xml_layout}"]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event(
        [:ex_sni, :dbus_method, :reply],
        _metrics,
        %{method: "GetGroupProperties", response: response},
        _config
      ) do
    xml_properties =
      response
      |> ExSni.Menu.Debug.parse_get_group_properties()
      |> Saxy.encode!()

    {"dbus", [{"timestamp", "#{now()}"}],
     [
       {"method_reply", [{"name", "GetGroupProperties"}], ["#{xml_properties}"]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  def handle_event([:ex_sni, :set_current_menu], _metrics, %{root: root}, _config) do
    xml_new_root = ExSni.Menu.Debug.debug_root(root)

    {"ex_sni", [{"timestamp", "#{now()}"}],
     [
       {"set_current_menu", [],
        [
          "#{xml_new_root}"
        ]}
     ]}
    |> Saxy.encode!()
    |> _debug()
  end

  defp _debug(str) do
    Logger.debug(str)
  end

  defp now() do
    DateTime.to_unix(DateTime.utc_now())
  end

  # Options parsing

  defp get_debug_options() do
    System.fetch_env(@debug_env_name)
    |> case do
      {:ok, value} ->
        value
        |> String.split(",")
        |> Enum.reject(&(&1 == ""))

      :error ->
        false
    end
    |> process_opts()
  end

  defp process_opts(opts) do
    opts =
      cond do
        env_opts_contains?(opts, "all") ->
          ["all"]

        env_opts_contains?(opts, "menu") ->
          Enum.reject(opts, &(&1 in ["menu_diff", "menu_update", "menu_set"]))

        env_opts_contains?(opts, "dbus") ->
          Enum.reject(opts, &(&1 in ["dbus_method", "dbus_signal"]))
      end

    Enum.reduce(opts, [], &env_opt_to_event/2)
  end

  defp env_opts_contains?(opts, what) do
    Enum.any?(opts, &(&1 == what))
  end

  defp env_opt_to_event("all", acc) do
    Enum.reduce(["menu", "dbus"], acc, &env_opt_to_event/2)
  end

  defp env_opt_to_event("menu", acc) do
    Enum.reduce(["menu_diff", "menu_update", "menu_set"], acc, &env_opt_to_event/2)
  end

  defp env_opt_to_event("menu_diff", acc) do
    [[:ex_sni, :menu_diff, :branch], [:ex_sni, :menu_diff, :result] | acc]
  end

  defp env_opt_to_event("menu_update", acc) do
    [[:ex_sni, :do_menu_update] | acc]
  end

  defp env_opt_to_event("menu_set", acc) do
    [[:ex_sni, :set_current_menu] | acc]
  end

  defp env_opt_to_event("dbus", acc) do
    Enum.reduce(["dbus_method", "dbus_signal"], acc, &env_opt_to_event/2)
  end

  defp env_opt_to_event("dbus_method", acc) do
    [[:ex_sni, :dbus_method, :call], [:ex_sni, :dbus_method, :reply] | acc]
  end

  defp env_opt_to_event("dbus_signal", acc) do
    [[:ex_sni, :send_dbus_signal] | acc]
  end
end
