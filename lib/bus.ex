defmodule ExSni.Bus do
  @doc """
  Returns true if there is a StatusNotifierWatcher available
  on the Session Bus.
  """
  @spec is_supported?() :: boolean()
  def is_supported?() do
    with {:ok, bus} <- ExDBus.Bus.start_link(:session),
         :ok <- ExDBus.Bus.connect(bus) do
      result = is_supported?(bus)
      ExDBus.Bus.close(bus)
      result
    else
      _ ->
        false
    end
  end

  @doc """
  Returns true if there is a StatusNotifierWatcher available
  on the Session Bus.
  - bus_pid - The pid of the ExDBus.Bus GenServer
  """
  @spec is_supported?(pid()) :: boolean()
  def is_supported?(bus_pid) do
    if ExDBus.Bus.name_has_owner(bus_pid, "org.kde.StatusNotifierWatcher") do
      ExDBus.Bus.has_interface?(
        bus_pid,
        "org.kde.StatusNotifierWatcher",
        "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher"
      )
    else
      false
    end
  end
end
