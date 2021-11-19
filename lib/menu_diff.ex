defmodule ExSni.MenuDiff do
  @moduledoc """
  Module to generate diff between two Menu roots (new and old)
  """
  alias ExSni.Menu
  alias ExSni.Menu.Item

  @spec diff(
          newer_menu :: nil | Menu.t() | Menu.Item.t(),
          previous_menu :: nil | Menu.t() | Menu.Item.t()
        ) ::
          {layout_id_to_update :: integer(), dbus_update_properties :: list(),
           new_root :: Menu.Item.t() | nil}
  def diff(menu, old_menu) do
    new_root = get_root(menu)
    old_root = get_root(old_menu)

    # Retrieve the diff as {inserts, deletes, updates, unchanged}
    {inserts, deletes, updates, nops, mapping} = diff_trees(new_root, old_root)

    case {inserts, deletes, updates, nops} do
      {[], [], [], []} ->
        # IO.inspect("{[], [], [], []}", label: "[DIFF::[1]]")
        # [x] Implemented
        # Nothing to update. Both new and old menus are empty
        # No layout changes
        # No items to signal updated properties for
        {-1, [], old_root}

      {[], [], [], _unchanged} ->
        # IO.inspect("{[], [], [], _unchanged}", label: "[DIFF::[2]]")
        # [x] Implemented
        # Nothing to update. Both menus are equal
        # No layout changes
        # No items to signal updated properties for
        {-1, [], old_root}

      {_inserts, _deletes, [], []} ->
        # IO.inspect("{_inserts, _deletes, [], []}", label: "[DIFF::[3]]")
        # [x] Implemented
        # If there are inserts or deletes, but there are no updates and no unchanged
        # then this is a completely different new menu
        # Full layout change
        # Signal property changes for all items in the new menu

        {node, _last_id, _new_ids_map} = assign_ids(new_root, %{}, 0)

        # This should be signaled as a menu reset and then switching to this new menu
        # {0, [], node}
        {-2, [], node}

      {[], [], updates, []} ->
        # IO.inspect("{[], [], updates, []}", label: "[DIFF::[4]]")
        # [x] Implemented
        # All items in the old menu have changes.
        # Return the new menu, but assign old menu IDs to all the new items
        # No layout changes
        # Signal property changes for all updated items

        last_id = get_last_id(old_root, 0)

        {node, _last_id, _new_ids_map} = assign_ids(new_root, mapping, last_id + 1)

        group_properties =
          Enum.reduce(updates, [], fn {%{id: id} = old_node, new_node}, acc ->
            [[id, Item.get_dbus_changed_properties(new_node, old_node, :ignore_default)] | acc]
          end)

        {-1, group_properties, node}

      {[], [], updates, _unchanged} ->
        # IO.inspect("{[], [], updates, _unchanged}", label: "[DIFF::[5]]")
        # [x] Implemented
        # This is a partial update of the menu.
        # Return the new menu, and copy old menu IDs to the updated items
        # No layout changes
        # Signal property changes for some updated items

        last_id = get_last_id(old_root, 0)

        {node, _last_id, _new_ids_map} = assign_ids(new_root, mapping, last_id + 1)

        group_properties =
          Enum.reduce(updates, [], fn {%{id: id} = old_node, new_node}, acc ->
            [[id, Item.get_dbus_changed_properties(new_node, old_node, :ignore_default)] | acc]
          end)

        # {updated_ids, menu} = todo()
        # {-1, updated_ids, menu}
        {-1, group_properties, node}

      {_inserts, deletes, updates, []} ->
        # IO.inspect("{inserts, deletes, updates, []}", label: "[DIFF::[6]]")
        # [x] Implemented
        # This is updates to all items in the menu and some deletes and/or some inserts
        # Some layout changes
        # - ideally we'd send the subtree id for layout changes,
        #   but libdbusmenu ignores it
        # Signal property changes for all updated items

        # Copy old ids from to the new menu from the old menu
        # and assign new ids for the inserts.
        delete_nodes =
          Enum.reduce(deletes, [], fn {node, _}, acc ->
            [node | acc]
          end)

        last_id =
          old_root
          |> get_last_id(0, delete_nodes)

        # Return the new menu, but with ids assigned from the old menu and new ids
        # for all other (inserts) items

        {node, _last_id, _new_ids_map} = assign_ids(new_root, mapping, last_id + 1)

        group_properties =
          Enum.reduce(updates, [], fn {%{id: id} = old_node, new_node}, acc ->
            [[id, Item.get_dbus_changed_properties(new_node, old_node, :ignore_default)] | acc]
          end)

        {0, group_properties, node}

      {_inserts, deletes, [], _unchanged} ->
        # IO.inspect("{inserts, deletes, [], unchanged}", label: "[DIFF::[7]]")
        # [x] Implemented
        # This is only a layout change where items have been removed from the old menu
        # or added in the new menu.
        # Some layout changes
        # - ideally we'd send the subtree id for layout changes,
        #   but libdbusmenu ignores it
        # No items to signal updated properties for

        delete_nodes =
          Enum.reduce(deletes, [], fn {node, _}, acc ->
            [node | acc]
          end)

        last_id =
          old_root
          |> get_last_id(0, delete_nodes)

        # Return the new menu, but with ids assigned from the old menu and new ids
        # for all other (inserts) items

        {node, _last_id, _new_ids_map} = assign_ids(new_root, mapping, last_id + 1)

        {0, [], node}

      {_inserts, deletes, updates, _unchanged} ->
        # IO.inspect("{inserts, deletes, updates, unchanged}", label: "[DIFF::[8]]")
        # [x] Implemented
        # There are mixed changes in our menus:
        #   inserts and/or deletes, updates but also unchanged items
        # Some layout changes
        # - ideally we'd send the subtree id for layout changes,
        #   but libdbusmenu ignores it
        # Signal property changes for some updated items

        # Copy old ids from to the new menu from the old menu
        # and assign new ids for the inserts.
        delete_nodes =
          Enum.reduce(deletes, [], fn {node, _}, acc ->
            [node | acc]
          end)

        last_id =
          old_root
          |> get_last_id(0, delete_nodes)

        # Return the new menu, but with ids assigned from the old menu and new ids
        # for all other (inserts) items

        {node, _last_id, _new_ids_map} = assign_ids(new_root, mapping, last_id + 1)

        group_properties =
          Enum.reduce(updates, [], fn {%{id: id} = old_node, new_node}, acc ->
            [[id, Item.get_dbus_changed_properties(new_node, old_node, :ignore_default)] | acc]
          end)

        {0, group_properties, node}
    end
  end

  defp get_last_id(node, last_id, except_nodes \\ [])

  defp get_last_id(%{children: []} = node, last_id, except_nodes) do
    get_last_node_id(node, last_id, except_nodes)
  end

  defp get_last_id(%{children: children} = node, last_id, except_nodes) do
    last_id = get_last_node_id(node, last_id, except_nodes)
    get_last_id(children, last_id, except_nodes)
  end

  defp get_last_id([], last_id, _) do
    last_id
  end

  defp get_last_id([node | nodes], last_id, except_nodes) do
    get_last_id(nodes, get_last_node_id(node, last_id, except_nodes))
  end

  defp get_last_node_id(%{id: id}, last_id, []) do
    if id > last_id do
      id
    else
      last_id
    end
  end

  defp get_last_node_id(node, last_id, except_nodes) do
    if Enum.member?(except_nodes, node) do
      last_id
    else
      get_last_node_id(node, last_id, [])
    end
  end

  defp assign_ids(node, mapping, last_id, new_ids_map \\ %{})

  defp assign_ids(%{children: []} = node, mapping, last_id, new_ids_map) do
    assign_node_id(node, mapping, last_id, new_ids_map)
  end

  defp assign_ids(%{children: children} = node, mapping, last_id, new_ids_map) do
    {node, last_id, new_ids_map} = assign_node_id(node, mapping, last_id, new_ids_map)
    {children, last_id, new_ids_map} = assign_ids(children, mapping, last_id, new_ids_map)
    {Map.put(node, :children, children), last_id, new_ids_map}
  end

  defp assign_ids([], _, last_id, new_ids_map) do
    {[], last_id, new_ids_map}
  end

  defp assign_ids([node | nodes], mapping, last_id, new_ids_map) do
    {node, last_id, new_ids_map} = assign_ids(node, mapping, last_id, new_ids_map)
    {nodes, last_id, new_ids_map} = assign_ids(nodes, mapping, last_id, new_ids_map)
    {[node | nodes], last_id, new_ids_map}
  end

  defp assign_node_id(node, mapping, last_id, new_ids_map) do
    {id, last_id, new_ids_map} =
      case Map.get(mapping, node) do
        %{id: id} when not is_nil(id) ->
          last_id = if id >= last_id, do: id + 1, else: last_id
          {id, last_id, new_ids_map}

        _ ->
          {last_id, last_id + 1, Map.put(new_ids_map, node, last_id)}
      end

    {Map.put(node, :id, id), last_id, new_ids_map}
  end

  defp diff_trees(new_tree, old_tree) do
    [{new_op_map, old_op_map}, _] = XdiffPlus.diff(new_tree, old_tree)

    {inserts, nops, mapping} = get_changes_new(new_op_map)
    {updates, deletes} = get_changes_old(old_op_map)

    {inserts, deletes, updates, nops, mapping}
  end

  defp get_root(%Menu{root: root}) do
    root
  end

  defp get_root(%Item{} = root) do
    root
  end

  defp get_root(_) do
    nil
  end

  defp get_changes_new(op_map) do
    # We only care about inserts, nops and the mapping from the new map
    # Returns {inserts, nops, mapping}
    Enum.reduce(op_map, {[], [], %{}}, fn
      {%{ref: node}, {:ins, %{ref: parent_node}, %{ref: prev_node}}}, {inserts, nops, mapping} ->
        {[{node, parent_node, prev_node} | inserts], nops, mapping}

      {%{ref: node}, {:ins, nil, %{ref: prev_node}}}, {inserts, nops, mapping} ->
        {[{node, nil, prev_node} | inserts], nops, mapping}

      {%{ref: node}, {:ins, %{ref: parent_node}, nil}}, {inserts, nops, mapping} ->
        {[{node, parent_node, nil} | inserts], nops, mapping}

      {%{ref: node}, {:ins, nil, nil}}, {inserts, nops, mapping} ->
        {[{node, nil, nil} | inserts], nops, mapping}

      {%{ref: node}, {:nop, %{ref: old_node}}}, {inserts, nops, mapping} ->
        {inserts, [{node, old_node} | nops], Map.put(mapping, node, old_node)}

      {%{ref: node}, {_, %{ref: old_node}}}, {inserts, nops, mapping} ->
        {inserts, nops, Map.put(mapping, node, old_node)}

      _, acc ->
        acc
    end)
  end

  defp get_changes_old(op_map) do
    # We only care about deletes and updates out of the old map
    # Returns {updates, deletes}
    Enum.reduce(op_map, {[], []}, fn
      {%{ref: node}, {:upd, %{ref: match_node}}}, {updates, deletes} ->
        {[{node, match_node} | updates], deletes}

      {%{ref: node}, :del}, {updates, deletes} ->
        {updates, [{node, nil} | deletes]}

      _, acc ->
        acc
    end)
  end
end
