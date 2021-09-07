defmodule ExSni.Menu do
  alias ExSni.Menu.Item

  defstruct version: 1,
            text_direction: "ltr",
            icon_theme_path: "",
            status: "normal",
            root: %Item{}

  @type t() :: %__MODULE__{
          version: integer(),
          text_direction: String.t(),
          icon_theme_path: String.t(),
          status: String.t(),
          root: Item.t()
        }

  @dbus_menu_item_type {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

  @spec get_layout(t(), integer(), list(String.t())) ::
          {:ok, list(), list()} | {:error, binary(), binary()}
  def get_layout(%__MODULE__{} = menu, depth, properties) do
    get_layout(menu, 0, depth, properties)
  end

  @spec get_layout(t(), non_neg_integer(), integer(), list(String.t())) ::
          {:ok, list(), list()} | {:error, binary(), binary()}
  def get_layout(%__MODULE__{root: %Item{} = root}, 0, depth, properties) do
    root_layout = Item.get_layout(root, depth, properties)
    {:ok, [:uint32, @dbus_menu_item_type], [0, root_layout]}
  end

  def get_layout(%__MODULE__{root: %Item{children: children}}, parentId, depth, properties) do
    case find_child(children, parentId) do
      %Item{} = child ->
        child_layout = Item.get_layout(child, depth, properties)
        {:ok, [:uint32, @dbus_menu_item_type], [parentId, child_layout]}

      _ ->
        {:error, "Error", "No such menu item"}
    end
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

  defimpl ExSni.DbusProtocol do
    def get_property(%{version: version}, "Version") do
      {:ok, version}
    end

    def get_property(%{text_direction: text_direction}, "TextDirection") do
      {:ok, text_direction}
    end

    def get_property(%{status: status}, "Status") do
      {:ok, status}
    end

    def get_property(%{icon_theme_path: icon_theme_path}, "IconThemePath") do
      {:ok, icon_theme_path}
    end

    def get_property(_, _) do
      {:error, "org.freedesktop.DBus.UnknownProperty", "Invalid property"}
    end
  end
end
