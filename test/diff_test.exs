defmodule ExSni.MenuDiffTest do
  use ExUnit.Case
  alias ExSni.Menu.Item
  alias ExSni.MenuDiff

  @old_menu """
  <root id="0" uid="" enabled="true" visible="true" label="" checked="false">
    <item id="1" uid="" type="standard" enabled="true" visible="true" label="Open" checked="false"/>
    <item id="2" uid="" type="checkbox" enabled="true" visible="true" label="Pause Network" checked="false"/>
    <item id="3" uid="" type="standard" enabled="false" visible="true" label="No Activity" checked="false"/>
    <item id="4" uid="" type="standard" enabled="true" visible="true" label="Quit" checked="false"/>
    <item id="5" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <menu id="6" uid="" enabled="true" visible="true" label="DevTools - 10002000" checked="false">
      <item id="7" uid="" type="standard" enabled="true" visible="true" label="Check for Update" checked="false"/>
      <menu id="8" uid="" enabled="true" visible="true" label="View" checked="false">
        <item id="9" uid="" type="standard" enabled="true" visible="true" label="Open Browser" checked="false"/>
        <item id="10" uid="" type="standard" enabled="true" visible="true" label="Show Default Layout" checked="false"/>
        <item id="11" uid="" type="standard" enabled="true" visible="true" label="Show Android Layout" checked="false"/>
        <item id="12" uid="" type="standard" enabled="true" visible="true" label="Show iOS Layout" checked="false"/>
      </menu>
      <item id="13" uid="" type="standard" enabled="true" visible="true" label="Observer" checked="false"/>
      <item id="14" uid="" type="standard" enabled="true" visible="true" label="Login" checked="false"/>
      <item id="15" uid="" type="standard" enabled="true" visible="true" label="Logout" checked="false"/>
      <item id="16" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="17" uid="" type="standard" enabled="true" visible="true" label="Restart" checked="false"/>
    </menu>
    <item id="18" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <item id="19" uid="" type="standard" enabled="true" visible="true" label="Zones" checked="false"/>
    <menu id="20" uid="" enabled="true" visible="true" label="   10002000&apos;s zone" checked="false">
      <item id="21" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="22" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="23" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="24" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="25" uid="" type="standard" enabled="true" visible="true" label="38.68kb, 2 Files" checked="false"/>
      <item id="26" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="27" uid="" type="standard" enabled="true" visible="true" label="Updated i4d18u02asy6qq69 2d ago" checked="false"/>
      <item id="28" uid="" type="standard" enabled="false" visible="true" label="Deleted kqchvyjxi1yw70xc 2d ago" checked="false"/>
      <item id="29" uid="" type="standard" enabled="false" visible="true" label="Deleted wf88k4px4jstq5q1 2d ago" checked="false"/>
      <item id="30" uid="" type="standard" enabled="true" visible="true" label="Updated image(2).png 2d ago" checked="false"/>
    </menu>
    <menu id="31" uid="" enabled="true" visible="true" label="   10002001" checked="false">
      <item id="32" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="33" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="34" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="35" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="36" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="37" uid="" enabled="true" visible="true" label="   First" checked="false">
      <item id="38" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="39" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="40" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="41" uid="" type="standard" enabled="true" visible="true" label="3 of 10 Online" checked="false"/>
      <item id="42" uid="" type="standard" enabled="true" visible="true" label="1.29gb, 79 Files" checked="false"/>
      <item id="43" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="44" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.5-win32... 48d ago" checked="false"/>
      <item id="45" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.0.1-win32... 163d ago" checked="false"/>
      <item id="46" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.1-win32... 168d ago" checked="false"/>
      <item id="47" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.3.5.dmg 2d ago" checked="false"/>
      <item id="48" uid="" type="standard" enabled="true" visible="true" label="Downloaded nightly_debug.zip 2d ago" checked="false"/>
    </menu>
    <menu id="49" uid="" enabled="true" visible="true" label="   Mikesnewzone2" checked="false">
      <item id="50" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="51" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="52" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="53" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="54" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
  </root>
  """

  @new_menu """
  <root id="0" uid="" enabled="true" visible="true" label="" checked="false">
    <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open" checked="false"/>
    <item id="0" uid="" type="checkbox" enabled="true" visible="true" label="Pause Network" checked="false"/>
    <item id="0" uid="" type="standard" enabled="false" visible="true" label="No Activity" checked="false"/>
    <item id="0" uid="" type="standard" enabled="true" visible="true" label="Quit" checked="false"/>
    <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <menu id="0" uid="" enabled="true" visible="true" label="DevTools - 10002000" checked="false">
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Check for Update" checked="false"/>
      <menu id="0" uid="" enabled="true" visible="true" label="View" checked="false">
        <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open Browser" checked="false"/>
        <item id="0" uid="" type="standard" enabled="true" visible="true" label="Show Default Layout" checked="false"/>
        <item id="0" uid="" type="standard" enabled="true" visible="true" label="Show Android Layout" checked="false"/>
        <item id="0" uid="" type="standard" enabled="true" visible="true" label="Show iOS Layout" checked="false"/>
      </menu>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Observer" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Login" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Logout" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Restart" checked="false"/>
    </menu>
    <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <item id="0" uid="" type="standard" enabled="true" visible="true" label="Zones" checked="false"/>
    <menu id="0" uid="" enabled="true" visible="true" label="   10002000&apos;s zone" checked="false">
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="38.68kb, 2 Files" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Updated i4d18u02asy6qq69 2d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="false" visible="true" label="Deleted kqchvyjxi1yw70xc 2d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="false" visible="true" label="Deleted wf88k4px4jstq5q1 2d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Updated image(2).png 2d ago" checked="false"/>
    </menu>
    <menu id="0" uid="" enabled="true" visible="true" label="   10002001" checked="false">
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="0" uid="" enabled="true" visible="true" label="   First" checked="false">
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="3 of 10 Online" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="1.29gb, 79 Files" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.5-win32... 48d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.0.1-win32... 163d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.1-win32... 168d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.3.5.dmg 2d ago" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Downloaded nightly_debug.zip 2d ago" checked="false"/>
    </menu>
    <menu id="0" uid="" enabled="true" visible="true" label="   Mikesnewzone2" checked="false">
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="0" uid="" enabled="true" visible="true" label="   Mikesnewzone1" checked="false">
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="1" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="0" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
  </root>
  """

  @next_menu """
  <root id="0" uid="" enabled="true" visible="true" label="" checked="false">
    <item id="1" uid="" type="standard" enabled="true" visible="true" label="Open" checked="false"/>
    <item id="2" uid="" type="checkbox" enabled="true" visible="true" label="Pause Network" checked="false"/>
    <item id="3" uid="" type="standard" enabled="false" visible="true" label="No Activity" checked="false"/>
    <item id="4" uid="" type="standard" enabled="true" visible="true" label="Quit" checked="false"/>
    <item id="5" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <menu id="6" uid="" enabled="true" visible="true" label="DevTools - 10002000" checked="false">
      <item id="7" uid="" type="standard" enabled="true" visible="true" label="Check for Update" checked="false"/>
      <menu id="8" uid="" enabled="true" visible="true" label="View" checked="false">
        <item id="9" uid="" type="standard" enabled="true" visible="true" label="Open Browser" checked="false"/>
        <item id="10" uid="" type="standard" enabled="true" visible="true" label="Show Default Layout" checked="false"/>
        <item id="11" uid="" type="standard" enabled="true" visible="true" label="Show Android Layout" checked="false"/>
        <item id="12" uid="" type="standard" enabled="true" visible="true" label="Show iOS Layout" checked="false"/>
      </menu>
      <item id="13" uid="" type="standard" enabled="true" visible="true" label="Observer" checked="false"/>
      <item id="14" uid="" type="standard" enabled="true" visible="true" label="Login" checked="false"/>
      <item id="15" uid="" type="standard" enabled="true" visible="true" label="Logout" checked="false"/>
      <item id="16" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="17" uid="" type="standard" enabled="true" visible="true" label="Restart" checked="false"/>
    </menu>
    <item id="18" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
    <item id="19" uid="" type="standard" enabled="true" visible="true" label="Zones" checked="false"/>
    <menu id="20" uid="" enabled="true" visible="true" label="   10002000&apos;s zone" checked="false">
      <item id="21" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="22" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="23" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="24" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="25" uid="" type="standard" enabled="true" visible="true" label="38.68kb, 2 Files" checked="false"/>
      <item id="26" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="27" uid="" type="standard" enabled="true" visible="true" label="Updated i4d18u02asy6qq69 2d ago" checked="false"/>
      <item id="28" uid="" type="standard" enabled="false" visible="true" label="Deleted kqchvyjxi1yw70xc 2d ago" checked="false"/>
      <item id="29" uid="" type="standard" enabled="false" visible="true" label="Deleted wf88k4px4jstq5q1 2d ago" checked="false"/>
      <item id="30" uid="" type="standard" enabled="true" visible="true" label="Updated image(2).png 2d ago" checked="false"/>
    </menu>
    <menu id="31" uid="" enabled="true" visible="true" label="   10002001" checked="false">
      <item id="32" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="33" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="34" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="35" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="36" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="37" uid="" enabled="true" visible="true" label="   First" checked="false">
      <item id="38" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="39" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="40" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="41" uid="" type="standard" enabled="true" visible="true" label="3 of 10 Online" checked="false"/>
      <item id="42" uid="" type="standard" enabled="true" visible="true" label="1.29gb, 79 Files" checked="false"/>
      <item id="43" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="44" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.5-win32... 48d ago" checked="false"/>
      <item id="45" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.0.1-win32... 163d ago" checked="false"/>
      <item id="46" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.2.1-win32... 168d ago" checked="false"/>
      <item id="47" uid="" type="standard" enabled="true" visible="true" label="Downloaded dDrive-1.3.5.dmg 2d ago" checked="false"/>
      <item id="48" uid="" type="standard" enabled="true" visible="true" label="Downloaded nightly_debug.zip 2d ago" checked="false"/>
    </menu>
    <menu id="49" uid="" enabled="true" visible="true" label="   Mikesnewzone2" checked="false">
      <item id="50" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="51" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="52" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="53" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="54" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
    <menu id="55" uid="" enabled="true" visible="true" label="   Mikesnewzone1" checked="false">
      <item id="56" uid="" type="standard" enabled="true" visible="true" label="Open Folder" checked="false"/>
      <item id="57" uid="" type="standard" enabled="true" visible="true" label="Manage" checked="false"/>
      <item id="58" uid="" type="separator" enabled="true" visible="true" label="" checked="false"/>
      <item id="59" uid="" type="standard" enabled="true" visible="true" label="0 of 0 Online" checked="false"/>
      <item id="60" uid="" type="standard" enabled="true" visible="true" label="0 bytes, 0 Files" checked="false"/>
    </menu>
  </root>
  """

  setup do
    old_root = build_root(@old_menu)
    new_root = build_root(@new_menu)
    {:ok, %{old_root: old_root, new_root: new_root}}
  end

  test "something", %{old_root: old_root, new_root: new_root} do
    {layout, updates, root} = MenuDiff.diff(new_root, old_root)

    assert layout == 0
    assert updates == []
    assert String.replace(@old_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(old_root)
    assert String.replace(@new_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(new_root)
    assert String.replace(@next_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(root)
  end

  defp build_root(source) do
    case Saxy.SimpleForm.parse_string(source) do
      {:ok, {"root", _, children}} ->
        children = build_nodes(children) |> Enum.reject(fn node -> node == nil end)

        %Item{type: :root, children: children}
        |> Item.assign_unique_int()

      _ ->
        nil
    end
  end

  defp build_nodes([]) do
    []
  end

  defp build_nodes([child | children]) do
    [build_node(child) | build_nodes(children)]
  end

  defp build_node({"menu", attrs, children}) do
    children = build_nodes(children) |> Enum.reject(fn node -> node == nil end)

    node =
      %Item{type: :menu, children: children}
      |> Item.assign_unique_int()

    Enum.reduce(attrs, node, fn {name, value}, node ->
      set_attr(node, name, value)
    end)
  end

  defp build_node({"item", attrs, children}) do
    children = build_nodes(children) |> Enum.reject(fn node -> node == nil end)
    {_, value} = Enum.find(attrs, fn {key, _} -> key == "type" end)

    node =
      %Item{type: String.to_atom(value), children: children}
      |> Item.assign_unique_int()

    Enum.reduce(attrs, node, fn {name, value}, node ->
      set_attr(node, name, value)
    end)
  end

  defp build_node(_) do
    nil
  end

  defp set_attr(node, "type", value) do
    Map.put(node, :type, String.to_atom(value))
  end

  defp set_attr(node, name, "true") do
    Map.put(node, String.to_atom(name), true)
  end

  defp set_attr(node, name, "false") do
    Map.put(node, String.to_atom(name), false)
  end

  defp set_attr(node, "id", value) do
    {id_value, _} = Integer.parse(value)
    Map.put(node, :id, id_value)
  end

  defp set_attr(node, name, value) when name in ["label"] do
    Map.put(node, String.to_atom(name), value)
  end

  defp set_attr(node, _, _) do
    node
  end
end
