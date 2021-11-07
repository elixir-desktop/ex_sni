defmodule ExSni.Icon do
  alias ExSni.Icon.{Info, Tooltip}
  alias ExSni.Ref

  defstruct __ref__: %Ref{path: "/StatusNotifierItem", interface: "org.kde.StatusNotifierItem"},
            category: :application_status,
            id: "",
            title: "",
            menu: "/NO_DBUSMENU",
            theme_path: "",
            status: :active,
            icon: nil,
            overlay_icon: nil,
            attention_icon: nil,
            tooltip: [],
            item_is_menu: false,
            window_id: 0

  @type category() :: :application_status | :communications | :system_services | :hardware
  @type status() :: :active | :passive | :needs_attention
  @type t() :: %__MODULE__{
          __ref__: Ref.t() | nil,
          category: category(),
          id: String.t(),
          title: String.t(),
          menu: String.t(),
          theme_path: String.t(),
          status: status(),
          icon: Info.t() | nil,
          overlay_icon: Info.t() | nil,
          attention_icon: Info.t() | nil,
          tooltip: Tooltip.t(),
          item_is_menu: boolean(),
          window_id: integer()
        }
end

defimpl ExSni.DbusProtocol, for: ExSni.Icon do
  alias ExSni.Icon.{Info, Tooltip}

  def get_property(%{category: :application_status}, "Category") do
    {:ok, "ApplicationStatus"}
  end

  def get_property(%{category: :communications}, "Category") do
    {:ok, "Communications"}
  end

  def get_property(%{category: :system_services}, "Category") do
    {:ok, "SystemServices"}
  end

  def get_property(%{category: :hardware}, "Category") do
    {:ok, "Hardware"}
  end

  def get_property(%{id: id}, "Id") do
    {:ok, id}
  end

  def get_property(%{title: title}, "Title") do
    {:ok, title}
  end

  def get_property(%{status: :active}, "Status") do
    {:ok, "Active"}
  end

  def get_property(%{status: :passive}, "Status") do
    {:ok, "Passive"}
  end

  def get_property(%{status: :needs_attention}, "Status") do
    {:ok, "NeedsAttention"}
  end

  def get_property(%{window_id: window_id}, "WindowId") do
    {:ok, window_id}
  end

  def get_property(%{item_is_menu: value}, "ItemIsMenu") do
    {:ok, value}
  end

  def get_property(%{menu: nil}, "Menu") do
    {:ok, "/NO_DBUSMENU"}
  end

  def get_property(%{menu: menu}, "Menu") when is_binary(menu) do
    {:ok, menu}
  end

  def get_property(%{theme_path: path}, "IconThemePath") do
    {:ok, path}
  end

  def get_property(%{icon: %Info{name: name}}, "IconName") do
    {:ok, name}
  end

  def get_property(%{overlay_icon: %Info{name: name}}, "OverlayIconName") do
    {:ok, name}
  end

  def get_property(%{attention_icon: %Info{name: name}}, "AttentionIconName") do
    {:ok, name}
  end

  def get_property(%{icon: %Info{data: {:pixmap, pixmap}}}, "IconPixmap") do
    {:ok, pixmap}
  end

  def get_property(%{overlay_icon: %Info{data: {:pixmap, pixmap}}}, "OverlayIconPixmap") do
    {:ok, pixmap}
  end

  def get_property(%{attention_icon: %Info{data: {:pixmap, pixmap}}}, "AttentionIconPixmap") do
    {:ok, pixmap}
  end

  def get_property(%{icon: %Info{}}, "IconPixmap") do
    :skip
  end

  def get_property(%{overlay_icon: %Info{}}, "OverlayIconPixmap") do
    :skip
  end

  def get_property(%{attention_icon: %Info{}}, "AttentionIconPixmap") do
    :skip
  end

  def get_property(%{tooltip: %Tooltip{} = tooltip}, "ToolTip") do
    name = Map.get(tooltip, :name, "")
    # data = Map.get(tooltip, :data, [])
    title = Map.get(tooltip, :title, "")
    desc = Map.get(tooltip, :description, "")

    {:ok,
     [
       {:dbus_variant, :string, name},
       [],
       {:dbus_variant, :string, title},
       {:dbus_variant, :string, desc}
     ]}
  end

  def get_property(_, "ToolTip") do
    {:ok,
     [
       {:dbus_variant, :string, ""},
       [],
       {:dbus_variant, :string, ""},
       {:dbus_variant, :string, ""}
     ]}
  end

  def get_property(_, empty_props)
      when empty_props in [
             "IconName",
             "OverlayIconName",
             "AttentionIconName",
             "AttentionIconMovie"
           ] do
    {:ok, ""}
  end

  def get_property(_, empty_props)
      when empty_props in [
             "IconPixmap",
             "OverlayIconPixmap",
             "AttentionIconPixmap"
           ] do
    {:ok, []}
  end

  def get_property(_, _) do
    {:error, "org.freedesktop.DBus.Error.UnknownProperty", "Invalid property"}
  end

  def get_property(icon, property, _) do
    get_property(icon, property)
  end

  def get_properties(icon, []) do
    get_properties(icon, [
      "Id",
      "Category",
      "Title",
      "Status",
      "Menu",
      "IconName",
      "OverlayIconName",
      "AttentionIconName",
      "AttentionIconMovie",
      "IconPixmap",
      "OverlayIconPixmap",
      "AttentionIconPixmap",
      "ToolTip",
      "ItemIsMenu",
      "WindowId"
    ])
  end

  def get_properties(icon, properties) do
    properties
    |> Enum.reduce([], fn property, acc ->
      case get_property(icon, property) do
        {:ok, value} -> [{property, value} | acc]
        _ -> acc
      end
    end)
  end

  def get_properties(icon, properties, _) do
    get_properties(icon, properties)
  end
end
