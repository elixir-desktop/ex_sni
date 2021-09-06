defmodule ExSni.Icon.Tooltip do
  defstruct name: "",
            data: [],
            title: "",
            description: ""

  @type t() :: %__MODULE__{
          name: String.t(),
          data: nil | list(),
          title: String.t(),
          description: String.t()
        }
end
