defmodule ExSni.Ref do
  defstruct pid: nil,
            path: "/",
            interface: nil

  @type t() :: %__MODULE__{
          pid: GenServer.server() | nil,
          path: String.t() | nil,
          interface: String.t() | nil
        }
end
