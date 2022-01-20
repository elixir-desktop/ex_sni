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

  test "Adding menu creates the proper diff and new root", %{
    old_root: old_root,
    new_root: new_root
  } do
    {layout, updates, root} = MenuDiff.diff(new_root, old_root)

    assert layout == 0
    assert updates == []
    assert String.replace(@old_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(old_root)
    assert String.replace(@new_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(new_root)
    assert String.replace(@next_menu, ~r/\n\s*/, "") == ExSni.XML.Builder.encode!(root)
  end

  test "Identifying the last id traverses child submenus too" do
    old_menu = """
    <root id="0" uid="" label="">
      <item id="1" uid="" type="standard" label="Open"/>
      <item id="2" uid="" type="separator" label=""/>
      <menu id="3" uid="" label="DevTools - 10002000">
        <item id="5" uid="" type="standard" label="Check for Update"/>
        <menu id="6" uid="" label="View">
          <item id="7" uid="" type="standard" label="Open Browser"/>
          <item id="8" uid="" type="standard" label="Show Default Layout"/>
          <item id="9" uid="" type="standard" label="Show Android Layout"/>
          <item id="10" uid="" type="standard" label="Show iOS Layout"/>
        </menu>
        <menu id="16" uid="" label="View 2">
          <item id="17" uid="" type="standard" label="Open Browser"/>
          <item id="18" uid="" type="standard" label="Show Default Layout"/>
          <item id="19" uid="" type="standard" label="Show Android Layout"/>
          <item id="20" uid="" type="standard" label="Show iOS Layout"/>
        </menu>
        <item id="4" uid="" type="standard" label="Observer"/>
      </menu>
      <item id="3" uid="" type="standard" label="Quit"/>
    </root>
    """

    new_menu = """
    <root id="0" uid="" label="">
      <item id="0" uid="" type="standard" label="Open"/>
      <item id="0" uid="" type="separator" label=""/>
      <menu id="0" uid="" label="DevTools - 10002000">
        <item id="0" uid="" type="standard" label="Check for Update"/>
        <menu id="0" uid="" label="View">
          <item id="0" uid="" type="standard" label="Open Browser"/>
          <item id="0" uid="" type="standard" label="Show Default Layout"/>
          <item id="0" uid="" type="standard" label="Show Android Layout"/>
          <item id="0" uid="" type="standard" label="Show iOS Layout"/>
        </menu>
        <menu id="0" uid="" label="View 3">
          <item id="0" uid="" type="standard" label="Open Browser 3"/>
          <item id="0" uid="" type="standard" label="Show Default Layout 3"/>
        </menu>
        <menu id="0" uid="" label="View 2">
          <item id="0" uid="" type="standard" label="Open Browser"/>
          <item id="0" uid="" type="standard" label="Show Default Layout"/>
          <item id="0" uid="" type="standard" label="Show Android Layout"/>
          <item id="0" uid="" type="standard" label="Show iOS Layout"/>
        </menu>
        <item id="0" uid="" type="standard" label="Observer"/>
      </menu>
      <item id="0" uid="" type="standard" label="Quit"/>
    </root>
    """

    next_menu = """
    <root id="0" uid="" label="">
      <item id="1" uid="" type="standard" label="Open"/>
      <item id="2" uid="" type="separator" label=""/>
      <menu id="3" uid="" label="DevTools - 10002000">
        <item id="5" uid="" type="standard" label="Check for Update"/>
        <menu id="6" uid="" label="View">
          <item id="7" uid="" type="standard" label="Open Browser"/>
          <item id="8" uid="" type="standard" label="Show Default Layout"/>
          <item id="9" uid="" type="standard" label="Show Android Layout"/>
          <item id="10" uid="" type="standard" label="Show iOS Layout"/>
        </menu>
        <menu id="21" uid="" label="View 3">
          <item id="22" uid="" type="standard" label="Open Browser 3"/>
          <item id="23" uid="" type="standard" label="Show Default Layout 3"/>
        </menu>
        <menu id="16" uid="" label="View 2">
          <item id="17" uid="" type="standard" label="Open Browser"/>
          <item id="18" uid="" type="standard" label="Show Default Layout"/>
          <item id="19" uid="" type="standard" label="Show Android Layout"/>
          <item id="20" uid="" type="standard" label="Show iOS Layout"/>
        </menu>
        <item id="4" uid="" type="standard" label="Observer"/>
      </menu>
      <item id="3" uid="" type="standard" label="Quit"/>
    </root>
    """

    old_root = build_root(old_menu)
    new_root = build_root(new_menu)

    {layout, updates, root} = MenuDiff.diff(new_root, old_root)

    assert layout == 0
    assert updates == []

    assert String.replace(old_menu, ~r/\n\s*/, "") ==
             ExSni.XML.Builder.encode!(old_root, only: [:id, :uid, :type, :label])

    assert String.replace(new_menu, ~r/\n\s*/, "") ==
             ExSni.XML.Builder.encode!(new_root, only: [:id, :uid, :type, :label])

    assert String.replace(next_menu, ~r/\n\s*/, "") ==
             ExSni.XML.Builder.encode!(root, only: [:id, :uid, :type, :label])
  end

  test "Fix node remove and inserts bug" do
    old_menu = """
    <root id="0" uid="" label="">
      <item id="1" uid="" type="standard" label="Add Zone"/>
      <item id="2" uid="" type="standard" label="Open"/>
      <item id="3" uid="" type="standard" label="Pause Network"/>
      <item id="4" uid="" type="standard" label="No Activity"/>
      <item id="5" uid="" type="standard" label="Quit"/>
    </root>
    """

    new_menu = """
    <root id="0" uid="" label="">
      <item id="0" uid="" type="standard" label="Open"/>
      <item id="0" uid="" type="standard" label="Pause Network"/>
      <item id="0" uid="" type="standard" label="No Activity"/>
      <item id="0" uid="" type="standard" label="Quit"/>
      <item id="0" uid="" type="separator" label=""/>
      <item id="0" uid="" type="standard" label="Zones"/>
      <menu id="0" uid="" label="   (Ze first)">
        <item id="0" uid="" type="standard" label="Open Folder"/>
        <item id="0" uid="" type="standard" label="Manage"/>
        <item id="1" uid="" type="separator" label=""/>
        <item id="0" uid="" type="standard" label="1 of 2 Online"/>
        <item id="0" uid="" type="standard" label="10 bytes, 1 Files"/>
      </menu>
      <menu id="0" uid="" label="    (dunedain.diode) (dunedain.diode)">
        <item id="0" uid="" type="standard" label="Open Folder"/>
        <item id="0" uid="" type="standard" label="Manage"/>
        <item id="1" uid="" type="separator" label=""/>
        <item id="0" uid="" type="standard" label="1 of 1 Online"/>
        <item id="0" uid="" type="standard" label="34 bytes, 1 Files"/>
      </menu>
      <menu id="0" uid="" label="   amazing zone #3">
        <item id="0" uid="" type="standard" label="Open Folder"/>
        <item id="0" uid="" type="standard" label="Manage"/>
        <item id="1" uid="" type="separator" label=""/>
        <item id="0" uid="" type="standard" label="1 of 1 Online"/>
        <item id="0" uid="" type="standard" label="143.06mb, 62 Files"/>
        <item id="1" uid="" type="separator" label=""/>
        <item id="0" uid="" type="standard" label="Deleted block49 17d ago"/>
        <item id="0" uid="" type="standard" label="Deleted block49 (copy) 17d ago"/>
        <item id="0" uid="" type="standard" label="Deleted block49 (another c... 17d ago"/>
        <item id="0" uid="" type="standard" label="Updated rand 136d ago"/>
        <item id="0" uid="" type="standard" label="Deleted rand36 136d ago"/>
      </menu>
      <menu id="0" uid="" label="   Dunedain&apos;s zone">
        <item id="0" uid="" type="standard" label="Open Folder"/>
        <item id="0" uid="" type="standard" label="Manage"/>
        <item id="1" uid="" type="separator" label=""/>
        <item id="0" uid="" type="standard" label="1 of 1 Online"/>
        <item id="0" uid="" type="standard" label="0 bytes, 0 Files"/>
      </menu>
      <menu id="0" uid="" label="   Testzone32">
        <item id="0" uid="" type="standard" label="Open Folder"/>
        <item id="0" uid="" type="standard" label="Manage"/>
        <item id="1" uid="" type="separator" label=""/>
        <item id="0" uid="" type="standard" label="1 of 1 Online"/>
        <item id="0" uid="" type="standard" label="0 bytes, 0 Files"/>
      </menu>
    </root>
    """

    next_menu = """
    <root id="0" label="">
      <item id="2" type="standard" label="Open"/>
      <item id="3" type="standard" label="Pause Network"/>
      <item id="4" type="standard" label="No Activity"/>
      <item id="5" type="standard" label="Quit"/>
      <item id="6" type="separator" label=""/>
      <item id="7" type="standard" label="Zones"/>
      <menu id="8" label="   (Ze first)">
        <item id="9" type="standard" label="Open Folder"/>
        <item id="10" type="standard" label="Manage"/>
        <item id="11" type="separator" label=""/>
        <item id="12" type="standard" label="1 of 2 Online"/>
        <item id="13" type="standard" label="10 bytes, 1 Files"/>
      </menu>
      <menu id="14" label="    (dunedain.diode) (dunedain.diode)">
        <item id="15" type="standard" label="Open Folder"/>
        <item id="16" type="standard" label="Manage"/>
        <item id="17" type="separator" label=""/>
        <item id="18" type="standard" label="1 of 1 Online"/>
        <item id="19" type="standard" label="34 bytes, 1 Files"/>
      </menu>
      <menu id="20" label="   amazing zone #3">
        <item id="21" type="standard" label="Open Folder"/>
        <item id="22" type="standard" label="Manage"/>
        <item id="23" type="separator" label=""/>
        <item id="24" type="standard" label="1 of 1 Online"/>
        <item id="25" type="standard" label="143.06mb, 62 Files"/>
        <item id="26" type="separator" label=""/>
        <item id="27" type="standard" label="Deleted block49 17d ago"/>
        <item id="28" type="standard" label="Deleted block49 (copy) 17d ago"/>
        <item id="29" type="standard" label="Deleted block49 (another c... 17d ago"/>
        <item id="30" type="standard" label="Updated rand 136d ago"/>
        <item id="31" type="standard" label="Deleted rand36 136d ago"/>
      </menu>
      <menu id="32" label="   Dunedain&apos;s zone">
        <item id="33" type="standard" label="Open Folder"/>
        <item id="34" type="standard" label="Manage"/>
        <item id="35" type="separator" label=""/>
        <item id="36" type="standard" label="1 of 1 Online"/>
        <item id="37" type="standard" label="0 bytes, 0 Files"/>
      </menu>
      <menu id="38" label="   Testzone32">
        <item id="39" type="standard" label="Open Folder"/>
        <item id="40" type="standard" label="Manage"/>
        <item id="41" type="separator" label=""/>
        <item id="42" type="standard" label="1 of 1 Online"/>
        <item id="43" type="standard" label="0 bytes, 0 Files"/>
      </menu>
    </root>
    """

    old_menu
    |> from_menu()
    |> to_menu(new_menu)
    |> test_menu_diff()
    |> assert_layout(0)
    |> assert_updates([])
    |> assert_menu(next_menu)
  end

  test "Insert and delete items in root" do
    from_menu("""
    <root id="0" label=""></root>
    """)
    |> to_menu("""
    <root label="">
    <item type="standard" label="Item 1"/>
    </root>
    """)
    |> test_menu_diff()
    |> assert_menu("""
    <root id="0" label="">
    <item id="1" type="standard" label="Item 1"/>
    </root>
    """)
    |> to_menu("""
    <root label="">
    <item type="standard" label="Item 1"/>
    <item type="separator" label=""/>
    <item type="standard" label="Item 2"/>
    </root>
    """)
    |> test_menu_diff()
    |> assert_menu("""
    <root id="0" label="">
    <item id="1" type="standard" label="Item 1"/>
    <item id="2" type="separator" label=""/>
    <item id="3" type="standard" label="Item 2"/>
    </root>
    """)
    |> to_menu("""
    <root label="">
    <item type="standard" label="Item 2"/>
    </root>
    """)
    |> test_menu_diff()
    |> assert_menu("""
    <root id="0" label="">
    <item id="3" type="standard" label="Item 2"/>
    </root>
    """)
  end

  test "Insert and delete items in submenus" do
    from_menu("""
      <root id="0" label=""></root>
    """)
    |> to_menu("""
      <root id="0" label="">
        <item id="0" type="standard" label="Item 1"/>
        <item id="0" type="separator" label=""/>
        <menu id="0" label=" Some submenu 1">
          <item id="0" type="standard" label="Sub item 1"/>
          <item id="0" type="separator" label=""/>
          <item id="0" type="standard" label="Sub item 2"/>
          <menu id="0" label="Some submenu 2">
            <item id="0" type="standard" label="Sub item 3"/>
          </menu>
        </menu>
      </root>
    """)
    |> test_menu_diff()
    |> assert_menu("""
    <root id="0" label="">
        <item id="1" type="standard" label="Item 1"/>
        <item id="2" type="separator" label=""/>
        <menu id="3" label=" Some submenu 1">
          <item id="4" type="standard" label="Sub item 1"/>
          <item id="5" type="separator" label=""/>
          <item id="6" type="standard" label="Sub item 2"/>
          <menu id="7" label="Some submenu 2">
            <item id="8" type="standard" label="Sub item 3"/>
          </menu>
        </menu>
      </root>
    """)
    |> to_menu("""
      <root id="0" label="">
        <item id="0" type="standard" label="Item 1"/>
        <item id="0" type="standard" label="Item 2"/>
        <item id="0" type="separator" label=""/>
        <menu id="0" label=" Some submenu 1">
          <item id="0" type="standard" label="Sub item 1"/>
          <item id="0" type="standard" label="Sub item 2"/>
          <menu id="0" label="Some submenu 2">
            <item id="0" type="standard" label="Sub item 3"/>
            <item id="0" type="separator" label=""/>
            <item id="0" type="standard" label="Sub item 4"/>
          </menu>
        </menu>
        <item id="0" type="standard" label="Item 3"/>
      </root>
    """)
    |> test_menu_diff()
    |> assert_menu("""
      <root id="0" label="">
        <item id="1" type="standard" label="Item 1"/>
        <item id="9" type="standard" label="Item 2"/>
        <item id="2" type="separator" label=""/>
        <menu id="3" label=" Some submenu 1">
          <item id="4" type="standard" label="Sub item 1"/>
          <item id="6" type="standard" label="Sub item 2"/>
          <menu id="7" label="Some submenu 2">
            <item id="8" type="standard" label="Sub item 3"/>
            <item id="5" type="separator" label=""/>
            <item id="10" type="standard" label="Sub item 4"/>
          </menu>
        </menu>
        <item id="11" type="standard" label="Item 3"/>
      </root>
    """)
  end

  # Private utility functions

  defp from_menu(old_menu) do
    from_menu({nil, nil}, old_menu)
  end

  defp from_menu({_, new_root}, old_menu) do
    {build_root(old_menu), new_root}
  end

  defp to_menu({old_root, _}, new_menu) do
    {old_root, build_root(new_menu)}
  end

  defp to_menu({_layout, _updates, old_root}, new_menu) do
    {old_root, build_root(new_menu)}
  end

  defp test_menu_diff({old_root, new_root}) do
    assert {layout, updates, root} = MenuDiff.diff(new_root, old_root)
    {layout, updates, root}
  end

  defp assert_menu(
         {_, _, root} = diff_result,
         expected_menu,
         encode_opts \\ [only: [:id, :type, :label]]
       ) do
    expected_menu = trim_xml_menu(expected_menu)

    assert expected_menu ==
             ExSni.XML.Builder.encode!(root, encode_opts)

    diff_result
  end

  defp assert_layout({layout, _, _} = diff_result, expected_layout) do
    assert layout == expected_layout
    diff_result
  end

  defp assert_updates({_, updates, _} = diff_result, expected_updates) do
    assert updates == expected_updates
    diff_result
  end

  defp trim_xml_menu(menu) when is_binary(menu) do
    menu
    |> String.replace(~r/^\s*/, "")
    |> String.replace(~r/\s*$/, "")
    |> String.replace(~r/\n\s*/, "")
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

    attrs
    |> Enum.reject(&(&1 == "type"))
    |> Enum.reduce(node, fn {name, value}, node ->
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
