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
          root: list(Item.t())
        }

  # @dbus_menu_item_type {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

  @spec get_layout(t(), integer(), list(String.t())) :: Item.layout()
  def get_layout(%__MODULE__{root: %Item{} = root}, depth, properties) do
    root_layout = Item.get_layout(root, depth, properties)
    root_layout
    # {:ok, [:uint32, @dbus_menu_item_type], [0, root_layout]}
  end

  def get_layout(%__MODULE__{root: _}, _, _) do
    {:dbus_variant, {:struct, []}, {0, [], []}}
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
