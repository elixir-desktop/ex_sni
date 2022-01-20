defmodule ExSni.Menu.Debug do
  def parse_layout_response({:ok, _, [version, [0, [], []]]}) do
    {"layout", [{"version", "#{version}"}], []}
  end

  def parse_layout_response({:ok, _, [version, root_node]}) do
    {"layout", [{"version", "#{version}"}], [parse_layout_item(root_node)]}
  end

  def parse_layout_response({:error, type, reason}) do
    {:error, "#{type}: #{reason}"}
  end

  def parse_signal_layout_updated([version, item_id]) do
    {"signal", [{"name", "LayoutUpdated"}, {"version", "#{version}"}, {"id", "#{item_id}"}], []}
  end

  def parse_signal_items_properties_updated([updated, removed]) do
    {"signal", [{"name", "ItemPropertiesUpdated"}],
     [
       {"updated", [], parse_group_items(updated)},
       {"removed", [], parse_group_items(removed)}
     ]}
  end

  def parse_get_group_properties([]) do
    {"group_properties", [], []}
  end

  def parse_get_group_properties(items) do
    {"group_properties", [], parse_group_items(items)}
  end

  defp parse_group_items(items) do
    items
    |> Enum.map(fn [id, prop_list] ->
      {"item", [{"id", "#{id}"} | parse_group_item_properties(prop_list)], []}
    end)
  end

  defp parse_group_item_properties(properties) do
    properties
    |> Enum.map(fn {name, {:dbus_variant, _type, value}} ->
      {name, "#{value}"}
    end)
  end

  def parse_layout_item({id, properties, children}) do
    properties = parse_properties(properties)

    children =
      Enum.map(children, fn {:dbus_variant, _, child} ->
        parse_layout_item(child)
      end)

    {"item", [{"id", "#{id}"} | properties], children}
  end

  def debug_root(nil) do
    ""
  end

  def debug_root(root) do
    ExSni.XML.Builder.encode!(root, only: [:id, :label])
  end

  defp parse_properties(properties) do
    Enum.reduce(properties, [], fn {key, {:dbus_variant, _type, value}}, acc ->
      [{key, "#{value}"} | acc]
    end)
    |> Enum.reverse()
  end
end
