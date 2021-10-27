defmodule ExSni.MenuDiff do
  alias ExSni.Menu
  alias ExSni.Menu.Item

  def diff(%Menu{root: root}, %Menu{root: old_root}) do
    IO.inspect("[MENUDIFF]")

    case Item.compare(root, old_root) do
      :equal ->
        # root nodes have no additional or removed children
        # check children
        nil
      {:changes, changed} ->
        # root nodes have changes in their properties
        nil
      {:error, _} ->
        # root nodes have different IDs
        nil
    end

    old_root
    |> tree_to_list()
    |> group_items()
    |> IO.inspect(label: "diff node result")
  end

  def diff(_, _) do
    # Whole menus are different
    IO.inspect("NOTHING TO INSPECT", label: "[MENUDIFF]")
  end

  def group_items(list) do
    map = group_by_property(list, :type)
    items = to_groups(map["standard"], [:children, :label, :toggle_type, :enabled, :visible])
    Map.put(map, "standard", items)
  end

  def to_groups(list, []) do
    list
  end

  def to_groups(list, [:type | properties]) do
    map = group_by_property(list, :type)
    items = to_groups(map["standard"], [:children, :label, :toggle_type, :enabled, :visible])
    %{
      "separator" => map["separator"],
      "standard" => items
    }

    map
    |> group_separators()
    |> group_checkboxes()
    |> group_radios()
    |> group_menus()
    |> group_standard()
  end

  def to_groups(list, [property | properties]) do
    list
    |> group_by_property(property)
    |> Enum.map(fn {property_value, items} ->
      {property_value, to_groups(items, properties)}
    end)
  end

  def group_by_property(list, :children) do
    Enum.group_by(list, fn {_, %{children: children}} -> Enum.count(children) end)
  end
  def group_by_property(list, property) do
    Enum.group_by(list, fn {_, item} -> Map.get(item, property) end)
  end

  def tree_to_list(node) do
    node
    |> flatten_tree()
    |> Enum.reverse()
    |> Enum.sort_by(&elem(&1,0))
  end

  def flatten_tree(what, acc \\ [])
  def flatten_tree(%Item{id: id, children: children} = item, acc) do
    flatten_tree(children, [{id, item} | acc])
  end
  def flatten_tree([], acc) do
    acc
  end
  def flatten_tree([item | items], acc) do
    flatten_tree(items, flatten_tree(item, acc))
  end
  def flatten_tree(_, acc) do
    acc
  end
end
