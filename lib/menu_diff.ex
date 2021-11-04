defmodule ExSni.MenuDiff do
  alias ExSni.Menu
  alias ExSni.Menu.Item

  def diff(menu, old_menu) do
    new_root = get_root(menu)
    old_root = get_root(old_menu)

    # Retrieve the diff as {inserts, deletes, updates, unchanged}
    {inserts, deletes, updates, _} = menu_diff = diff_trees(new_root, old_root)

    {Enum.count(inserts), deletes, Enum.count(updates)}
    |> IO.inspect(label: "MENU DIFF: {inserts, deletes, updates}")

    case menu_diff do
      {[], [], [], []} ->
        # Nothing to update. Both new and old menus are empty
        # No layout changes
        # No items to signal updated properties for
        {-1, [], old_menu}

      {[], [], [], _unchanged} ->
        # Nothing to update. Both menus are equal
        # No layout changes
        # No items to signal updated properties for
        {-1, [], old_menu}

      {_inserts, _deletes, [], []} ->
        # If there are inserts or deletes, but there are no updates and no unchanged
        # this is a completely different new menu
        # Full layout change
        # Signal property changes for all items in the new menu

        # menu = assign_menu_ids(menu)
        # {0, Menu.get_group_properties(menu, :all, []), menu}
        {-1, [], menu}

      {[], [], updates, []} ->
        # All items in the old menu have changes.
        # Return the new menu, but assign old menu IDs to all the new items
        # No layout changes
        # Signal property changes for all updated items

        # menu = assign_menu_ids(menu)
        # {-1, all_ids, menu}
        {-1, [], menu}

      {[], [], updates, unchanged} ->
        # This is a partial update of the menu.
        # Return the new menu, and copy old menu IDs to the updated items
        # No layout changes
        # Signal property changes for some updated items

        # {updated_ids, menu} = todo()
        # {-1, updated_ids, menu}
        {-1, [], menu}

      {inserts, deletes, updates, []} ->
        # This is updates to all items in the menu and some deletes and/or some inserts
        # Some layout changes
        # - ideally we'd send the subtree id for layout changes,
        #   but libdbusmenu ignores it
        # Signal property changes for all updated items

        # menu = assign_menu_ids(menu)
        # {0, updated_ids, menu}
        {-1, [], menu}

      {inserts, deletes, [], unchanged} ->
        # This is only a layout change where items have been removed from the old menu
        # or added in the new menu.
        # Some layout changes
        # - ideally we'd send the subtree id for layout changes,
        #   but libdbusmenu ignores it
        # No items to signal updated properties for

        # menu = alter_menu()
        # {0, [], menu}
        {-1, [], menu}

      {inserts, deletes, updates, unchanged} ->
        # There are mixed changes in our menus:
        #   inserts and/or deletes, updates but also unchanged items
        # Some layout changes
        # - ideally we'd send the subtree id for layout changes,
        #   but libdbusmenu ignores it
        # Signal property changes for some updated items

        # {0, updated_ids, menu}
        {-1, [], menu}
    end
  end

  defp diff_trees(new_tree, old_tree) do
    [{new_op_map, old_op_map}, _] = XdiffPlus.diff(new_tree, old_tree)

    {inserts, nops} = get_changes_new(new_op_map)
    {updates, deletes} = get_changes_old(old_op_map)

    {inserts, deletes, updates, nops}
  end

  defp get_root(%Menu{root: root}) do
    root
  end

  defp get_root(_) do
    nil
  end

  defp get_changes_new(op_map) do
    # We only care about inserts from the new map
    Enum.reduce(op_map, {[], []}, fn
      {%{ref: node}, {:ins, %{ref: parent_node}, %{ref: prev_node}}}, {inserts, nops} ->
        {[{node, parent_node, prev_node} | inserts], nops}

      {%{ref: node}, {:ins, nil, %{ref: prev_node}}}, {inserts, nops} ->
        {[{node, nil, prev_node} | inserts], nops}

      {%{ref: node}, {:ins, %{ref: parent_node}, nil}}, {inserts, nops} ->
        {[{node, parent_node, nil} | inserts], nops}

      {%{ref: node}, {:ins, nil, nil}}, {inserts, nops} ->
        {[{node, nil, nil} | inserts], nops}

      {%{ref: node}, {:nop, %{ref: old_node}}}, {inserts, nops} ->
        {inserts, [{node, old_node} | nops]}

      _, acc ->
        acc
    end)
  end

  defp get_changes_old(op_map) do
    # We only care about deletes and updates out of the old map
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
