defmodule GeosearchV1 do
  use GenServer

  @impl true
  @spec init(Path.t() | Geo.t(data)) :: {:ok, Geo.t(data)} | {:ok, nil, {:continue, Path.t()}} when data: var
   def init(%Geo{} = initial), do: {:ok, initial}
   def init(path), do: {:ok, nil, {:continue, path}}

  @impl true
  @spec handle_continue(Path.t(), any()) :: {:noreply, Geo.t(term())}
  def handle_continue(path, _) do
    {:noreply, Geo.load(path)}
  end

  @impl true
  @spec handle_call({:nearest, Geo.point()}, any(), Geo.t(data)) :: {:reply, {Geo.distance(), Geo.item(data)} | :none , Geo.t(data)} when data: var
  def handle_call({:nearest, coord}, _from, state), do:
    {:reply, Geo.nearest(state, coord), state}

  @impl true
  @spec handle_call({:within_radius, Geo.point(), Geo.distance()}, any(), Geo.t(data)) :: {:reply, [{Geo.distance(), Geo.item(data)}], Geo.t(data)} when data: var
  def handle_call({:within_radius, coord, radius}, _from, state), do:
    {:reply, Geo.within_radius(state, coord, radius), state}

  @impl true
  @spec handle_call({:within_box, Geo.point(), Geo.point()}, any(), Geo.t(data)) :: {:reply, [Geo.item(data)], Geo.t(data)} when data: var
  def handle_call({:within_box, min, max}, _from, state), do:
    {:reply, Geo.within_box(state, min, max), state}

  @impl true
  @spec handle_cast({:add, Geo.item(data)}, Geo.t(data)) :: {:noreply, Geo.t(data)} when data: var
  def handle_cast({:add, item}, state) do
    {:noreply, Geo.add(state, item)}
  end

  @snapshot_interval 60*60*1_000
  @impl true
  @spec handle_info({:snapshot, Path.t()}, Geo.t(data)) :: {:noreply, Geo.t(data)} when data: var
  def handle_info({:snapshot, path} = message, state) do
    Geo.save(Path.join(path, datestamp()), state)
    Process.send_after(self(), message, @snapshot_interval)
    {:noreply, state}
  end

  @spec nearest(pid(), Geo.point()) :: {Geo.distance(), Geo.item(term())} | :none
  def nearest(pid, point) do
    GenServer.call(pid, {:nearest, point})
  end

  @spec within_radius(pid(), Geo.point(), Geo.distance()) :: [{Geo.distance(), Geo.item(term())}]
  def within_radius(pid, point, radius) do
    GenServer.call(pid, {:within_radius, point, radius})
  end

  @spec within_box(pid(), Geo.point(), Geo.point()) :: [Geo.item(term())]
  def within_box(pid, min, max) do
    GenServer.call(pid, {:within_box, min, max})
  end

  @spec add(pid(), Geo.item(term)) :: :ok
  def add(pid, item) do
    GenServer.cast(pid, {:add, item})
  end

  defp datestamp(), do: DateTime.utc_now() |> DateTime.to_iso8601()
end
