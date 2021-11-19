defimpl ExSni.XML.Builder, for: ExSni.Menu.Item do
  def encode!(item) do
    Saxy.Builder.build(item)
    |> Saxy.encode!()
  end
end

defimpl ExSni.XML.Builder, for: ExSni.Menu do
  def encode!(menu) do
    Saxy.Builder.build(menu)
    |> Saxy.encode!()
  end
end

defimpl ExSni.XML.Builder, for: Atom do
  def encode!(atom) do
    Atom.to_string(atom)
  end
end

defimpl ExSni.XML.Builder, for: String do
  def encode!(string) do
    string
  end
end

defimpl ExSni.XML.Builder, for: List do
  def encode!(list) do
    Enum.map(list, &ExSni.XML.Builder.encode!/1)
    |> Enum.join("")
  end
end

defimpl ExSni.XML.Builder, for: Integer do
  def encode!(number) do
    "#{number}"
  end
end

defimpl ExSni.XML.Builder, for: Tuple do
  def encode!({a, b}) do
    ExSni.XML.Builder.encode!([a, b])
  end

  def encode!({a, b, c}) do
    ExSni.XML.Builder.encode!([a, b, c])
  end

  def encode!({a, b, c, d}) do
    ExSni.XML.Builder.encode!([a, b, c, d])
  end
end

defimpl ExSni.XML.Builder, for: Any do
  def encode!(value) do
    "#{inspect(value)}"
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
