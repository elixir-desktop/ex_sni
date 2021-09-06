defprotocol ExSni.DbusProtocol do
  @spec get_property(t(), String.t()) ::
          {:ok, String.t() | list() | boolean() | number() | tuple()}
          | {:error, String.t(), String.t()}
  def get_property(struct, property)
end
