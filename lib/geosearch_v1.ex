defmodule GeosearchV1 do
  use GenServer

  @impl true
  @spec init([GeoMap.geo_item(item)] | GeoMap.t(item)) :: {:ok, GeoMap.t(item)} | {:continue, [GeoMap.geo_item(item)]} when item: var
  def init(list) when is_list(list), do: {:continue, list}
  def init(%GeoMap{} = initial), do: {:ok, initial}

  @impl true
  @spec handle_continue([GeoMap.geo_item(item)], any()) :: {:noreply, GeoMap.t(item)} when item: var
  def handle_continue(list, _) do
    {:noreply, GeoMap.from_list(list)}
  end

  @impl true
  @spec handle_call({:nearest, GeoMap.point()}, any(), GeoMap.t(item)) :: {:reply, {GeoMap.distance(), GeoMap.geo_item(item)} | :none , GeoMap.t(item)} when item: var
  def handle_call({:nearest, coord}, _from, state), do:
    {:reply, GeoMap.nearest(state, coord), state}

  @impl true
  @spec handle_call({:within_radius, GeoMap.point(), GeoMap.distance()}, any(), GeoMap.t(item)) :: {:reply, [{GeoMap.distance(), GeoMap.geo_item(item)}], GeoMap.t(item)} when item: var
  def handle_call({:within_radius, coord, radius}, _from, state), do:
    {:reply, GeoMap.within_radius(state, coord, radius), state}

  @impl true
  @spec handle_call({:within_box, GeoMap.point(), GeoMap.point()}, any(), GeoMap.t(item)) :: {:reply, [GeoMap.geo_item(item)], GeoMap.t(item)} when item: var
  def handle_call({:within_box, min, max}, _from, state), do:
    {:reply, GeoMap.within_box(state, min, max), state}

  @impl true
  @spec handle_cast({:add, GeoMap.geo_item(item)}, GeoMap.t(item)) :: {:noreply, GeoMap.t(item)} when item: var
  def handle_cast({:add, item}, state) do
    {:noreply, GeoMap.add(state, item)}
  end

  @impl true
  @spec handle_info({:snapshot, binary()}, GeoMap.t(item)) :: {:noreply, GeoMap.t(item)} when item: var
  def handle_info({:snapshot, filename}, state) do
    File.write!(filename, :erlang.term_to_binary(state))
    {:noreply, state}
  end

  @spec nearest(pid(), GeoMap.point()) :: {GeoMap.distance(), GeoMap.geo_item(term())} | :none
  def nearest(pid, point) do
    GenServer.call(pid, {:nearest, point})
  end

  @spec within_radius(pid(), GeoMap.point(), GeoMap.distance()) :: [{GeoMap.distance(), GeoMap.geo_item(term())}]
  def within_radius(pid, point, radius) do
    GenServer.call(pid, {:within_radius, point, radius})
  end

  @spec within_box(pid(), GeoMap.point(), GeoMap.point()) :: [GeoMap.geo_item(term())]
  def within_box(pid, min, max) do
    GenServer.call(pid, {:within_box, min, max})
  end

  @spec add(pid(), GeoMap.geo_item(term)) :: :ok
  def add(pid, item) do
    GenServer.cast(pid, {:add, item})
  end
end
