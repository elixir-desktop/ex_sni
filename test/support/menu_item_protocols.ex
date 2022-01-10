defimpl ExSni.XML.Builder, for: ExSni.Menu.Item do
  def build!(item, []) do
    Saxy.Builder.build(item)
  end

  def build!(item, opts) do
    built_item = build!(item, [])

    case Keyword.get(opts, :only) do
      [] ->
        built_item

      keys when is_list(keys) ->
        only_keys(built_item, Enum.map(keys, &Atom.to_string/1))

      _ ->
        built_item
    end
  end

  def encode!(item) do
    item
    |> build!([])
    |> Saxy.encode!()
  end

  def encode!(item, opts) do
    item
    |> build!(opts)
    |> Saxy.encode!()
  end

  defp only_keys(elem, []) do
    elem
  end

  defp only_keys({tag, attrs, children}, keys) do
    {
      tag,
      Enum.filter(attrs, fn {key, _} ->
        Enum.member?(keys, key)
      end),
      Enum.map(children, &only_keys(&1, keys))
    }
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

defimpl ExSni.XML.Builder, for: Atom do
  def build!(atom, _opts) do
    atom
  end

  def encode!(atom) do
    Atom.to_string(atom)
  end

  def encode!(atom, _opts) do
    encode!(atom)
  end
end

defimpl ExSni.XML.Builder, for: String do
  def build!(string, _opts) do
    string
  end

  def encode!(string) do
    string
  end

  def encode!(string, _opts) do
    encode!(string)
  end
end

defimpl ExSni.XML.Builder, for: List do
  def build!(list, _opts) do
    list
  end

  def encode!(list) do
    Enum.map_join(list, "", &ExSni.XML.Builder.encode!/1)
  end

  def encode!(list, _opts) do
    encode!(list)
  end
end

defimpl ExSni.XML.Builder, for: Integer do
  def build!(number, _opts) do
    number
  end

  def encode!(number) do
    "#{number}"
  end

  def encode!(integer, _opts) do
    encode!(integer)
  end
end

defimpl ExSni.XML.Builder, for: Tuple do
  def build!(tuple, _opts) do
    tuple
  end

  def encode!({a, b}) do
    ExSni.XML.Builder.encode!([a, b])
  end

  def encode!({a, b, c}) do
    ExSni.XML.Builder.encode!([a, b, c])
  end

  def encode!({a, b, c, d}) do
    ExSni.XML.Builder.encode!([a, b, c, d])
  end

  def encode!(tuple, _opts) do
    encode!(tuple)
  end
end

defimpl ExSni.XML.Builder, for: Any do
  def build!(value, _opts) do
    value
  end

  def encode!(value) do
    "#{inspect(value)}"
  end

  def encode!(value, _opts) do
    encode!(value)
  end
end

defimpl Saxy.Builder, for: ExSni.Menu do
  import Saxy.XML

  def build(%{version: version, root: root}) do
    element("dbus_menu", [version: version], [Saxy.Builder.build(root)])
  end
end

defimpl Saxy.Builder, for: ExSni.Menu.Item do
  import Saxy.XML

  def build(%{type: :root, children: children} = item) do
    element("root", build_attrs(item), Enum.map(children, &build/1))
  end

  def build(%{type: :menu, children: children} = item) do
    element("menu", build_attrs(item), Enum.map(children, &build/1))
  end

  def build(%{children: children} = item) do
    element("item", build_item_attrs(item), Enum.map(children, &build/1))
  end

  defp build_item_attrs(item) when is_map(item) do
    [:id, :uid, :type, :enabled, :visible, :label, :checked]
    |> build_attrs(item)
  end

  defp build_attrs(item) when is_map(item) do
    [:id, :uid, :enabled, :visible, :label, :checked]
    |> build_attrs(item)
  end

  defp build_attrs(attrs, item) when is_list(attrs) do
    attrs
    |> Enum.map(fn attr -> {attr, Map.get(item, attr)} end)
  end
end
