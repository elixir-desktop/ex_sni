defmodule ExSni.Menu.BackupStore do
  use GenServer

  def start_link(opts, gen_opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      gen_opts
    )
  end

  @impl true
  def init(options) do
    {:ok, Keyword.get(options, :menu, nil)}
  end

  @impl true
  def handle_call({:restore_menu, menu}, {pid, _tag}, nil)
      when is_pid(pid) do
    Process.monitor(pid)

    {:reply, menu, menu}
  end

  def handle_call({:restore_menu, _menu}, {pid, _tag}, menu) do
    Process.monitor(pid)
    {:reply, menu, menu}
  end

  def handle_call({:save_menu, menu}, {_pid, _tag} = _from, _menu) do
    {:reply, menu, menu}
  end

  @impl true
  def handle_cast({:save_menu, menu}, _menu) do
    {:noreply, menu}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _object, _reason}, menu) do
    Process.demonitor(ref)
    {:noreply, menu}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
