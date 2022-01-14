defmodule ExSni.Menu do
  require Logger

  alias ExSni.Menu.Item
  alias ExSni.Ref

  defstruct __ref__: %Ref{path: "/MenuBar", interface: "com.canonical.dbusmenu"},
            version: 1,
            text_direction: "ltr",
            icon_theme_path: [""],
            status: "normal",
            root: nil,
            last_id: 0,
            callbacks: []

  @type fn_callback() :: (... -> any())
  @type callback() :: {atom(), fn_callback()}
  @type t() :: %__MODULE__{
          __ref__: Ref.t() | nil,
          version: integer(),
          text_direction: String.t(),
          icon_theme_path: list(String.t()),
          status: String.t(),
          root: Item.t(),
          last_id: non_neg_integer(),
          callbacks: list(callback())
        }

  @dbus_menu_item_type {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

  @spec get_root(t() | any()) :: Item.t() | nil
  def get_root(%__MODULE__{root: root}) do
    root
  end

  def get_root(_) do
    nil
  end

  @spec get_layout(t(), integer(), list(String.t())) ::
          {:ok, list(), list()} | {:error, binary(), binary()}
  def get_layout(%__MODULE__{} = menu, depth, properties) do
    get_layout(menu, 0, depth, properties)
  end

  @spec get_layout(t(), non_neg_integer(), integer(), list(String.t())) ::
          {:ok, list(), list()} | {:error, binary(), binary()}
  def get_layout(%__MODULE__{root: %Item{} = root, version: version}, 0, depth, properties) do
    {_, _, root_layout} = Item.get_layout(root, depth, properties)
    {:ok, [:uint32, @dbus_menu_item_type], [version, root_layout]}
  end

  def get_layout(%__MODULE__{root: %Item{children: children}}, parentId, depth, properties) do
    case find_child(children, parentId) do
      %Item{} = child ->
        {_, _, child_layout} = Item.get_layout(child, depth, properties)
        {:ok, [:uint32, @dbus_menu_item_type], [parentId, child_layout]}

      _ ->
        {:error, "org.freedesktop.DBus.Error.Failed", "No such menu item"}
    end
  end

  def get_layout(%__MODULE__{root: _, version: version}, parentId, _, _) do
    {:ok, [:uint32, @dbus_menu_item_type], [version, [parentId, [], []]]}
  end

  def get_layout(_, _, _, _) do
    {:error, "org.freedesktop.DBus.Error.Failed", "No such menu item"}
  end

  def get_group_properties(%__MODULE__{} = menu, :all, properties) do
    ids =
      menu
      |> get_children()
      |> Enum.map(&Map.get(&1, :id))

    get_group_properties(menu, ids, properties)
  end

  def get_group_properties(%__MODULE__{} = menu, ids, properties) do
    ids
    |> Enum.map(&find_item(menu, &1))
    |> Enum.reject(&(&1 == nil))
    |> Enum.map(fn item ->
      values = ExSni.DbusProtocol.get_properties(item, properties)
      [item.id, values]
    end)
  end

  def get_group_properties(_, _, _) do
    []
  end

  def get_group_properties_per_item(%__MODULE__{} = menu, mapping) do
    Enum.reduce(mapping, [], fn {id, properties}, acc ->
      case find_item(menu, id) do
        nil ->
          acc

        item ->
          values = ExSni.DbusProtocol.get_properties(item, properties)
          [id, values]
      end
    end)
  end

  def get_last_id(%__MODULE__{last_id: last_id}) do
    last_id
  end

  def get_last_id(_) do
    0
  end

  defp get_children(%__MODULE__{root: %{} = root}) do
    get_children(root)
  end

  defp get_children(%{children: []}) do
    []
  end

  defp get_children(%{children: children}) when is_list(children) do
    Enum.reduce(children, [], fn child, acc ->
      children = get_children(child)
      [child | children] ++ acc
    end)
  end

  defp get_children(_) do
    []
  end

  def find_item(%__MODULE__{root: %Item{} = root}, id) do
    Item.find_item(root, id)
  end

  def find_item(_, _) do
    nil
  end

  @spec onAboutToShow(t(), id :: non_neg_integer()) :: boolean()
  def onAboutToShow(%__MODULE__{callbacks: callbacks}, 0) do
    run_aboutToShow(callbacks)
  end

  def onAboutToShow(%__MODULE__{} = menu, id) do
    case find_item(menu, id) do
      %Item{callbacks: callbacks} ->
        run_aboutToShow(callbacks)

      _ ->
        Logger.debug("Menu.onEvent:: Failed to find menu item by id [#{id}] (AboutToShow})")
        false
    end
  end

  def onAboutToShow(nil, _) do
    false
  end

  @spec onEvent(
          t(),
          eventId :: String.t(),
          menuId :: non_neg_integer(),
          data :: any(),
          timestamp :: any()
        ) :: any()
  def onEvent(%__MODULE__{callbacks: callbacks}, eventId, 0, data, timestamp) do
    run_events(callbacks, eventId, data, timestamp)
  end

  def onEvent(%__MODULE__{} = menu, eventId, id, data, timestamp) do
    case find_item(menu, id) do
      %Item{callbacks: callbacks} ->
        run_events(callbacks, eventId, data, timestamp)

      _ ->
        Logger.debug(
          "Menu.onEvent:: Failed to find menu item by id [#{id}] (eventId: #{eventId})"
        )

        nil
    end
  end

  def onEvent(nil, _, _, _, _) do
    nil
  end

  defp run_events(callbacks, eventId, data, timestamp) do
    callbacks
    |> get_callbacks(eventId)
    |> Enum.reduce(nil, fn func, _ ->
      try do
        func.(data, timestamp)
      rescue
        _ -> nil
      end
    end)
  end

  defp run_aboutToShow(callbacks) do
    callbacks
    |> get_callbacks(:show)
    |> Enum.reduce(false, fn func, acc ->
      try do
        func.()
      rescue
        _ -> acc
      else
        v -> v || acc
      end
    end)
  end

  defp get_callbacks([], _eventId) do
    []
  end

  defp get_callbacks(callbacks, eventId) do
    callbacks
    # |> Enum.filter(&is_tuple/1)
    # |> Enum.filter(&(elem(&1, 0) == eventId))
    |> Enum.filter(&has_event_id(&1, eventId))
    |> Enum.map(&elem(&1, 1))
    |> Enum.filter(&is_function(&1))
  end

  defp has_event_id(item, eventId) when is_tuple(item) do
    elem(item, 0) == eventId
  end

  defp has_event_id(_, _) do
    false
  end

  @spec find_child(list(Item.t()), non_neg_integer()) :: nil | Item.t()
  defp find_child([], _) do
    nil
  end

  defp find_child([%Item{id: id} = item | _], id) do
    item
  end

  defp find_child([_ | items], id) do
    find_child(items, id)
  end
end

defimpl ExSni.DbusProtocol, for: ExSni.Menu do
  def get_property(%{version: version}, "Version") do
    {:ok, version}
  end

  def get_property(%{text_direction: text_direction}, "TextDirection") do
    {:ok, text_direction}
  end

  def get_property(%{status: status}, "Status") do
    {:ok, status}
  end

  def get_property(%{icon_theme_path: icon_theme_path}, "IconThemePath")
      when is_binary(icon_theme_path) do
    {:ok, [icon_theme_path]}
  end

  def get_property(%{icon_theme_path: icon_theme_path}, "IconThemePath")
      when is_list(icon_theme_path) do
    {:ok, icon_theme_path}
  end

  def get_property(_, _) do
    {:error, "org.freedesktop.DBus.Error.UnknownProperty", "Invalid property"}
  end

  def get_property(item, property, _) do
    get_property(item, property)
  end

  def get_properties(item, []) do
    get_properties(item, [
      "Version",
      "TextDirection",
      "Status",
      "IconThemePath"
    ])
  end

  def get_properties(item, properties) do
    get_properties(item, properties, [])
  end

  def get_properties(item, properties, options) do
    properties
    |> Enum.reduce([], fn property, acc ->
      case get_property(item, property, options) do
        {:ok, value} -> [{property, value} | acc]
        _ -> acc
      end
    end)
  end
end

defimpl ExSni.XML.Builder, for: ExSni.Menu do
  def build!(menu, []) do
    Saxy.Builder.build(menu)
  end

  def build!(%{root: nil} = item, _opts) do
    build!(item, [])
  end

  def build!(%{root: root} = item, opts) do
    item
    |> Map.put(root, ExSni.XML.Builder.build!(item, opts))
    |> build!([])
  end

  def encode!(menu) do
    menu
    |> build!([])
    |> Saxy.encode!()
  end

  def encode!(menu, opts) do
    menu
    |> build!(opts)
    |> Saxy.encode!()
  end
end

defimpl Saxy.Builder, for: ExSni.Menu do
  import Saxy.XML

  def build(%{version: version, root: root}) do
    element("dbus_menu", [version: version], [Saxy.Builder.build(root)])
  end
end
