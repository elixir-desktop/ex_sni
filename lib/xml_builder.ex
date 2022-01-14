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
