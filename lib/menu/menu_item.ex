defmodule ExSni.Menu.Item do
  alias ExSni.Icon.Info, as: IconInfo

  defstruct id: 0,
            type: "standard",
            enabled: true,
            visible: true,
            label: "",
            icon: nil,
            toggle_type: nil,
            toggle_state: nil,
            children: []

  @type id() :: non_neg_integer()
  @type toggle_type() :: nil | :checkmark | :radio
  @type toggle_state() :: nil | :on | :off
  @type t() :: %__MODULE__{
          id: id(),
          type: String.t(),
          enabled: boolean(),
          visible: boolean(),
          label: String.t(),
          icon: String.t() | IconInfo.t(),
          toggle_type: toggle_type(),
          toggle_state: toggle_state(),
          children: list(t())
        }

  @type layout() :: {:dbus_variant, {:struct, list()}, dbus_menu_item()}
  @type dbus_variant() :: {:dbus_variant, any(), any()}
  @type dbus_menu_properties() :: list({String.t(), dbus_variant()})
  @type dbus_menu_item() :: {integer(), dbus_menu_properties(), list(dbus_menu_item())}

  @dbus_menu_item_type {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

  @spec get_layout(t(), integer(), list(String.t())) :: layout()
  def get_layout(%__MODULE__{id: id, children: children} = menu_item, depth, properties) do
    prop_values =
      properties
      |> Enum.map(fn property ->
        case ExSni.DbusProtocol.get_property(menu_item, property) do
          {:ok, value} -> {property, value}
          _ -> nil
        end
      end)
      |> Enum.reject(&(&1 == nil))

    children =
      case depth do
        0 -> []
        -1 -> Enum.map(children, &get_layout(&1, -1, properties))
        depth -> Enum.map(children, &get_layout(&1, depth - 1, properties))
      end

    {:dbus_variant, @dbus_menu_item_type,
     {
       id,
       prop_values,
       children
     }}
  end

  @spec find_item(t(), id()) :: nil | t()
  def find_item(%__MODULE__{children: []}, _id) do
    nil
  end

  def find_item(%__MODULE__{children: [%__MODULE__{id: id} = item | _]}, id) do
    item
  end

  def find_item(%__MODULE__{children: [item | items]}, id) do
    case find_item(item, id) do
      nil -> find_item(%{item | children: items}, id)
      item -> item
    end
  end

  # @spec find_child(list(Item.t()), non_neg_integer()) :: nil | Item.t()
  # defp find_child([], _) do
  #   nil
  # end

  # defp find_child([%Item{id: id} = item | _], id) do
  #   item
  # end

  # defp find_child([_ | items], id) do
  #   find_child(items, id)
  # end

  defimpl ExSni.DbusProtocol do
    def get_property(%{type: type}, "type") do
      {:ok, {:dbus_variant, :string, type}}
    end

    def get_property(%{enabled: enabled}, "enabled") do
      {:ok, {:dbus_variant, :boolean, enabled}}
    end

    def get_property(%{visible: visible}, "visible") do
      {:ok, {:dbus_variant, :boolean, visible}}
    end

    def get_property(%{label: label}, "label") do
      {:ok, {:dbus_variant, :string, label}}
    end

    def get_property(%{icon: icon_name}, "icon_name") when is_binary(icon_name) do
      {:ok, {:dbus_variant, :string, icon_name}}
    end

    def get_property(%{icon: %IconInfo{name: name}}, "icon-name") do
      {:ok, {:dbus_variant, :string, name}}
    end

    def get_property(%{icon: %IconInfo{data: data}}, "icon-data") when is_binary(data) do
      {:ok, data}
    end

    def get_property(_, "icon-data") do
      {:ok, {:dbus_variant, :string, ""}}
    end

    def get_property(%{toggle_type: :checkmark}, "toggle-type") do
      {:ok, {:dbus_variant, :string, "checkmark"}}
    end

    def get_property(%{toggle_type: :radio}, "toggle-type") do
      {:ok, {:dbus_variant, :string, "radio"}}
    end

    def get_property(_, "toggle-type") do
      {:ok, {:dbus_variant, :string, ""}}
    end

    def get_property(%{toggle_state: :on}, "toggle-state") do
      {:ok, {:dbus_variant, :int32, 1}}
    end

    def get_property(%{toggle_state: :off}, "toggle-state") do
      {:ok, {:dbus_variant, :int32, 0}}
    end

    def get_property(_, "toggle-state") do
      {:ok, {:dbus_variant, :int32, -1}}
    end

    def get_property(%{children: [_ | _]}, "children-display") do
      {:ok, {:dbus_variant, :string, "submenu"}}
    end

    def get_property(%{children: []}, "children-display") do
      {:ok, {:dbus_variant, :string, ""}}
    end

    def get_property(_, _) do
      {:error, "org.freedesktop.DBus.Error.UnknownProperty", "Invalid property"}
    end

    def get_properties(item, []) do
      get_properties(item, [
        "type",
        "enabled",
        "visible",
        "label",
        "icon-name",
        "icon-data",
        "toggle-type",
        "toggle-state",
        "children-display"
      ])
    end

    def get_properties(item, properties) do
      properties
      |> Enum.reduce([], fn property, acc ->
        case get_property(item, property) do
          {:ok, value} -> [{property, value} | acc]
          _ -> acc
        end
      end)
    end
  end
end
