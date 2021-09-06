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

  @type toggle_type() :: nil | :checkmark | :radio
  @type toggle_state() :: nil | :on | :off
  @type t() :: %__MODULE__{
          id: non_neg_integer(),
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

  def get_layout(%__MODULE__{id: id, children: children} = menu_item, -1, properties) do
    prop_values =
      properties
      |> Enum.map(fn property ->
        {property, ExSni.DbusProtocol.get_property(menu_item, property)}
      end)
      |> Enum.filter(fn
        {:ok, _} -> true
        _ -> false
      end)
      |> Enum.map(&elem(&1, 1))

    children =
      children
      |> Enum.map(&get_layout(&1, -1, properties))

    {:dbus_variant, @dbus_menu_item_type,
     {
       id,
       prop_values,
       children
     }}
  end

  def get_layout(%__MODULE__{id: id, children: children} = menu_item, depth, properties) do
    prop_values =
      properties
      |> Enum.map(fn property ->
        {property, ExSni.DbusProtocol.get_property(menu_item, property)}
      end)
      |> Enum.filter(fn
        {:ok, _} -> true
        _ -> false
      end)
      |> Enum.map(&elem(&1, 1))

    children =
      if depth == 0 do
        []
      else
        children
        |> Enum.map(&get_layout(&1, depth - 1, properties))
      end

    {:dbus_variant, @dbus_menu_item_type,
     {
       id,
       prop_values,
       children
     }}
  end

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
      {:ok, {:dbus_variant, :string, ""}}
    end
  end
end
