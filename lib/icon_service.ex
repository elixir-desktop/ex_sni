defmodule ExSni.IconService do
  use GenServer

  def register_icon(pid \\ __MODULE__) do
    GenServer.call(pid, :register_icon)
  end

  def start_link(opts) do
    GenServer.start_link(
      __MODULE__,
      [],
      opts
    )
  end

  @impl true
  def init(_opts) do
    name = "org.example.MyIcon-#{:os.getpid()}-1"

    {:ok, service} =
      ExDBus.Service.start_link(
        name,
        DBusTrayIcon.IconSchema
      )

    # bus = ExDBus.Service.get_bus(service)

    state = %{service: service, name: name}

    {:ok, state}
  end

  # Gen server implementation

  @impl true

  def handle_call(:register_icon, _from, %{service: service, name: service_name} = state) do
    reply =
      GenServer.call(service, {
        :call_method,
        "org.kde.StatusNotifierWatcher",
        "/StatusNotifierWatcher",
        "org.kde.StatusNotifierWatcher",
        "RegisterStatusNotifierItem",
        {"s", [:string], [service_name]}
      })
      |> IO.inspect(label: "REGISTER ICON CALL")

    {:reply, reply, state}
  end

  def handle_call(_request, _from, state) do
    {:noreply, state}
  end

  @impl true
  def handle_cast(_request, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info(_message, state) do
    {:noreply, state}
  end
end
