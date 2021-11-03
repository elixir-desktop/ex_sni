defmodule ExSni.MenuDiff do
  alias ExSni.Menu
  # alias ExSni.Menu.Item

  def diff(%Menu{root: root}, %Menu{root: old_root}) do
    IO.inspect("[MENUDIFF]")

    [{new_op_map, old_op_map}, _] = XdiffPlus.diff(root, old_root)

    new_op_map
    |> new_ops()
    |> IO.inspect(label: "DIFF NEW INSERTS")

    old_op_map
    |> old_ops()
    |> IO.inspect(label: "DIFF {UPDATES, DELETES} in OLD MAP")
  end

  def diff(_, _) do
    # Whole menus are different
    IO.inspect("NOTHING TO INSPECT", label: "[MENUDIFF]")
  end

  defp new_ops(op_map) do
    # We only care about inserts from the new map
    Enum.reduce(op_map, [], fn
      {%{ref: node}, :ins}, acc ->
        [{node, nil} | acc]

      _, acc ->
        acc
    end)
  end

  defp old_ops(op_map) do
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
