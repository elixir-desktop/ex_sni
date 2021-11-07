defprotocol ExSni.DbusProtocol do
  @type property_value() :: String.t() | binary() | list() | boolean() | number() | tuple()
  @spec get_property(t(), property :: String.t()) ::
          {:ok, property_value()}
          | {:error, String.t(), String.t()}
  def get_property(struct, property)

  @spec get_property(t(), property :: String.t(), options :: any()) ::
          {:ok, property_value()}
          | {:error, String.t(), String.t()}
  def get_property(struct, property, options)

  @spec get_properties(t(), properties :: list(String.t())) :: list(property_value())
  def get_properties(struct, properties)

  @spec get_properties(t(), properties :: list(String.t()), options :: any()) :: list(property_value())
  def get_properties(struct, properties, options)
end
