defmodule ExSni.Menu.Item do
  alias ExSni.Icon.Info, as: IconInfo
  alias ExSni.Menu

  defstruct id: 0,
            uuid: "",
            uid: "",
            type: :standard,
            enabled: true,
            visible: true,
            label: "",
            icon: nil,
            checked: false,
            children: [],
            callbacks: []

  @type id() :: non_neg_integer()
  @type item_type() :: :separator | :root | :standard | :checkbox | :radio | :menu
  @type toggle_type() :: nil | :checkmark | :radio
  @type toggle_state() :: nil | :on | :off
  @type t() :: %__MODULE__{
          id: id(),
          uuid: String.t(),
          uid: String.t(),
          type: item_type(),
          enabled: boolean(),
          visible: boolean(),
          label: String.t(),
          icon: nil | String.t() | IconInfo.t(),
          checked: boolean(),
          children: list(t()),
          callbacks: list(Menu.callback())
        }

  @type layout() :: {:dbus_variant, {:struct, list()}, dbus_menu_item()}
  @type dbus_variant() :: {:dbus_variant, any(), any()}
  @type dbus_menu_properties() :: list({String.t(), dbus_variant()})
  @type dbus_menu_item() :: {integer(), dbus_menu_properties(), list(dbus_menu_item())}

  @dbus_menu_item_type {:struct, [:int32, {:dict, :string, :variant}, {:array, :variant}]}

  @spec separator() :: t()
  def separator() do
    %__MODULE__{id: 1, type: :separator}
    |> assign_uuid()
  end

  @spec root(children :: list(t())) :: t()
  def root(children \\ []) do
    %__MODULE__{id: 0, type: :root, children: children}
    |> assign_uuid()
  end

  @spec menu(children :: list(t())) :: t()
  def menu(children \\ []) do
    %__MODULE__{type: :menu, children: children}
    |> assign_uuid()
  end

  @spec checkbox() :: t()
  def checkbox(label \\ "") do
    %__MODULE__{type: :checkbox}
    |> assign_uuid()
    |> set_label(label)
  end

  @spec radio() :: t()
  def radio(label \\ "") do
    %__MODULE__{type: :radio}
    |> assign_uuid()
    |> set_label(label)
  end

  @spec standard(label :: String.t()) :: t()
  def standard(label \\ "") do
    %__MODULE__{type: :standard}
    |> assign_uuid()
    |> set_label(label)
  end

  @doc """
  WARNING: Always use unique IDs across the entire tree.
  If you set the same ID for a node and any of its descendants,
  most menu hosts (i.e. libdbusmenu) will recurse indefinitely when attempting
  to build the list of IDs to request the layout for; which will most likely
  result in a system-wide crash/hang.

  To store custom ID (e.g. "id" attribute), use `uid` property and `set_uid/2`
  """
  @spec set_id(t(), id :: id()) :: t()
  def set_id(%__MODULE__{type: type} = item, id) when type not in [:root, :separator] do
    %{item | id: id}
  end

  def set_id(%__MODULE__{} = item, _) do
    item
  end

  @spec set_uid(t(), uid :: String.t()) :: t()
  def set_uid(%__MODULE__{} = item, uid) do
    %{item | uid: uid}
  end

  @spec set_label(t(), label :: String.t()) :: t()
  def set_label(%__MODULE__{type: type} = item, label)
      when type not in [:separator] and is_binary(label) do
    %{item | label: label}
  end

  def set_label(item, _) do
    item
  end

  @spec assign_uuid(t()) :: t()
  def assign_uuid(%__MODULE__{} = item) do
    %{item | uuid: UUID.uuid4()}
  end

  @spec set_callbacks(t(), callbacks :: list(Menu.callback())) :: t()
  def set_callbacks(%__MODULE__{} = item, callbacks) do
    %{item | callbacks: callbacks}
  end

  @spec enable(t()) :: t()
  def enable(%__MODULE__{} = item) do
    set_enabled(item, true)
  end

  @spec disable(t()) :: t()
  def disable(%__MODULE__{} = item) do
    set_enabled(item, false)
  end

  @spec toggle_enabled(t()) :: t()
  def toggle_enabled(%__MODULE__{enabled: true} = item) do
    set_enabled(item, false)
  end

  def toggle_enabled(%__MODULE__{enabled: false} = item) do
    set_enabled(item, true)
  end

  @spec set_enabled(t(), value :: boolean()) :: t()
  def set_enabled(%__MODULE__{} = item, value) when is_boolean(value) do
    %{item | enabled: value}
  end

  @spec visible(t()) :: t()
  def visible(%__MODULE__{} = item) do
    set_visible(item, true)
  end

  @spec hidden(t()) :: t()
  def hidden(%__MODULE__{} = item) do
    set_visible(item, false)
  end

  @spec toggle_visible(t()) :: t()
  def toggle_visible(%__MODULE__{visible: true} = item) do
    set_visible(item, false)
  end

  def toggle_visible(%__MODULE__{visible: false} = item) do
    set_visible(item, true)
  end

  @spec set_visible(t(), value :: boolean()) :: t()
  def set_visible(%__MODULE__{} = item, value) when is_boolean(value) do
    %{item | visible: value}
  end

  @spec set_checked(t(), new_state :: boolean()) :: t()
  def set_checked(item, value \\ true)

  def set_checked(%__MODULE__{type: type} = item, value)
      when type in [:checkbox, :radio] and is_boolean(value) do
    %{item | checked: value}
  end

  def set_checked(item, _) do
    item
  end

  @spec toggle_checked(t()) :: t()
  def toggle_checked(%__MODULE__{checked: true} = item) do
    set_checked(item, false)
  end

  def toggle_checked(%__MODULE__{checked: false} = item) do
    set_checked(item, true)
  end

  @spec get_layout(t(), integer(), list(String.t())) :: layout()
  def get_layout(%__MODULE__{id: id, children: children} = menu_item, depth, properties) do
    prop_values =
      properties
      |> Enum.map(fn property ->
        case ExSni.DbusProtocol.get_property(menu_item, property, :ignore_default) do
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

  # This does not check for :id property
  @spec get_changed_properties(current :: t(), other :: t(), properties :: list(atom())) ::
          list(atom())
  def get_changed_properties(%__MODULE__{} = current, %__MODULE__{} = other) do
    get_changed_properties(current, other, [:type, :label, :enabled, :visible, :icon, :checked])
  end

  def get_changed_properties(%__MODULE__{}, %__MODULE__{}, []) do
    []
  end

  def get_changed_properties(%__MODULE__{} = current, %__MODULE__{} = other, [
        property | properties
      ]) do
    current_value = Map.get(current, property)
    other_value = Map.get(other, property)

    if current_value == other_value do
      get_changed_properties(current, other, properties)
    else
      [property | get_changed_properties(current, other, properties)]
    end
  end

  def get_dbus_changed_properties(current, other, opts \\ [])

  def get_dbus_changed_properties(%__MODULE__{} = current, %__MODULE__{} = other, opts) do
    [
      "label",
      "type",
      "enabled",
      "visible",
      "icon-name",
      "icon-data",
      "toggle-type",
      "toggle-state",
      "children-display"
    ]
    |> Enum.reduce(
      [],
      fn property, acc ->
        case get_dbus_changed_property(current, other, property, opts) do
          {:ok, {property, dbus_value}} -> [{property, dbus_value} | acc]
          _ -> acc
        end
      end
    )
  end

  defp get_dbus_changed_property(%__MODULE__{} = current, %__MODULE__{} = other, property, opts) do
    case ExSni.DbusProtocol.get_property(current, property, opts) do
      {:ok, dbus_value} ->
        case ExSni.DbusProtocol.get_property(other, property, opts) do
          {:ok, ^dbus_value} -> :equal
          _ -> {:ok, {property, dbus_value}}
        end

      _ ->
        :error
    end
  end

  defimpl ExSni.DbusProtocol do
    def get_property(item, property) do
      get_property(item, property, [])
    end

    def get_property(%{type: :separator}, "type", _) do
      ok_dbus_variant(:string, "separator")
    end

    def get_property(%{type: _}, "type", :ignore_default) do
      ok_dbus_variant(:string, "standard")
    end

    def get_property(%{type: _}, "type", _) do
      default("standard")
    end

    def get_property(%{enabled: true}, "enabled", :ignore_default) do
      ok_dbus_variant(:boolean, true)
    end

    def get_property(%{enabled: true}, "enabled", _) do
      default(true)
    end

    def get_property(%{enabled: false}, "enabled", _) do
      ok_dbus_variant(:boolean, false)
    end

    def get_property(%{visible: true}, "visible", :ignore_default) do
      ok_dbus_variant(:boolean, true)
    end

    def get_property(%{visible: true}, "visible", _) do
      default(true)
    end

    def get_property(%{visible: false}, "visible", _) do
      ok_dbus_variant(:boolean, false)
    end

    def get_property(%{label: ""}, "label", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(%{label: ""}, "label", _) do
      default("")
    end

    def get_property(%{label: label}, "label", _) do
      ok_dbus_variant(:string, label)
    end

    def get_property(%{icon: ""}, "icon-name", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(%{icon: ""}, "icon-name", _) do
      default("")
    end

    def get_property(%{type: :separator}, "icon-name", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(%{type: :separator}, "icon-name", _) do
      default("")
    end

    def get_property(%{icon: icon_name}, "icon-name", _) when is_binary(icon_name) do
      ok_dbus_variant(:string, icon_name)
    end

    def get_property(%{icon: %IconInfo{name: ""}}, "icon-name", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(%{icon: %IconInfo{name: ""}}, "icon-name", _) do
      default("")
    end

    def get_property(%{icon: %IconInfo{name: name}}, "icon-name", _) do
      ok_dbus_variant(:string, name)
    end

    def get_property(%{type: :separator}, "icon-data", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(%{type: :separator}, "icon-data", _) do
      default("")
    end

    def get_property(%{icon: %IconInfo{data: ""}}, "icon-data", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(%{icon: %IconInfo{data: ""}}, "icon-data", _) do
      default(nil)
    end

    def get_property(%{icon: %IconInfo{data: data}}, "icon-data", _) when is_binary(data) do
      {:ok, data}
    end

    def get_property(_, "icon-data", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(_, "icon-data", _) do
      default("")
    end

    def get_property(%{type: :checkbox}, "toggle-type", _) do
      ok_dbus_variant(:string, "checkmark")
    end

    def get_property(%{type: :radio}, "toggle-type", _) do
      ok_dbus_variant(:string, "radio")
    end

    def get_property(_, "toogle-type", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(_, "toggle-type", _) do
      default("")
    end

    def get_property(%{type: type, checked: true}, "toggle-state", _)
        when type in [:checkbox, :radio] do
      ok_dbus_variant(:int32, 1)
    end

    def get_property(%{type: type, checked: false}, "toggle-state", _)
        when type in [:checkbox, :radio] do
      ok_dbus_variant(:int32, 0)
    end

    def get_property(_, "toggle-state", :ignore_default) do
      ok_dbus_variant(:int32, -1)
    end

    def get_property(_, "toggle-state", _) do
      default(-1)
    end

    def get_property(%{type: type, children: [_ | _]}, "children-display", _)
        when type in [:root, :menu] do
      ok_dbus_variant(:string, "submenu")
    end

    def get_property(_, "children-display", :ignore_default) do
      ok_dbus_variant(:string, "")
    end

    def get_property(_, "children-display", _) do
      default("")
    end

    def get_property(_, _, _) do
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
      get_properties(item, properties, [])
    end

    def get_properties(item, properties, opts) do
      properties
      |> Enum.reduce([], fn property, acc ->
        case get_property(item, property, opts) do
          {:ok, value} -> [{property, value} | acc]
          _ -> acc
        end
      end)
    end

    defp ok_dbus_variant(type, value) do
      {:ok, {:dbus_variant, type, value}}
    end

    defp default(value) do
      {:default, value}
    end
  end

  defimpl Xtree.Protocol do
    def name(%{type: :separator}) do
      "hr"
    end

    def name(%{type: type}) when type in [:root, :menu] do
      "menu"
    end

    def name(_) do
      "item"
    end

    def children(%{children: children}) do
      children
    end

    def type(_) do
      :element
    end

    def value(%{type: :separator}) do
      ""
    end

    def value(%{type: type} = node) when type in [:root, :menu] do
      default_value(node)
    end

    def value(%{type: type, checked: checked} = node) do
      "type=#{type};checked=#{checked}" <> default_value(node)
    end

    # TODO: HANDLE ICON into value

    def value(node) do
      default_value(node)
    end

    def id(%{uid: uid}) do
      uid
    end

    defp default_value(%{
           uid: uid,
           label: label,
           enabled: enabled,
           visible: visible,
           callbacks: callbacks
         }) do
      "id=#{uid};enabled=#{enabled};visible=#{visible};label=#{label}" <>
        stringify_callbacks(callbacks)
    end

    defp stringify_callbacks(callbacks) do
      callbacks
      |> cb_to_attrs_string()
      |> Enum.join(";")
    end

    defp cb_to_attrs_string([]) do
      []
    end

    defp cb_to_attrs_string([{_, _, {attr_name, attr_value}} | callbacks]) do
      ["#{attr_name}=#{attr_value}" | cb_to_attrs_string(callbacks)]
    end

    defp cb_to_attrs_string([_ | callbacks]) do
      cb_to_attrs_string(callbacks)
    end
  end
end
