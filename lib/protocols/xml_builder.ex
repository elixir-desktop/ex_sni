defprotocol ExSni.XML.Builder do
  @fallback_to_any true
  def build!(t, opts)
  def encode!(t)
  def encode!(t, opts)
end
