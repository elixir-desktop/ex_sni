defmodule ExSni.Ref do
  defstruct pid: nil,
            path: "/",
            interface: nil

  @type t() :: %__MODULE__{
          pid: ExDBus.Service.pid() | nil,
          path: String.t() | nil,
          interface: String.t() | nil
        }
end
