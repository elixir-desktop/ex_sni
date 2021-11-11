defprotocol ExSni.XML.Builder do
  @fallback_to_any true
  def encode!(t)
end
