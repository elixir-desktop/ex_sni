defprotocol ExSni.DbusProtocol do
  @type property_value() :: String.t() | binary() | list() | boolean() | number() | tuple()
  @spec get_property(t(), String.t()) ::
          {:ok, property_value()}
          | {:error, String.t(), String.t()}
  def get_property(struct, property)

  @spec get_properties(t(), list(String.t())) :: list(property_value())
  def get_properties(struct, properties)
end
