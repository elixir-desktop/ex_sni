defmodule ExSni.Icon.Info do
  defstruct name: "",
            data: nil

  @type t() :: %__MODULE__{
          name: String.t(),
          data: nil | binary() | {:pixmap, list()} | list() | {:png, binary()}
        }
end
