defmodule GeoTree do

  alias TreeMap.Iterator

  @earth_radius_miles 3_961.0
  #@max_distance 50_000.0

  @opaque t(item) :: TreeMap.t(point(), item)
  @type latitude :: float()
  @type longitude :: float()
  @type distance :: float()
  @type axis :: :lat | :lng
  @type direction :: :left | :right
  @type point :: {latitude(), longitude()}
  @type item(data) :: {point(), data}

  @type queue(t) :: {[t], [t]}

  @spec coalesced_less(point(), point()) :: boolean()
  def coalesced_less({x_lat, x_lng}, {y_lat, y_lng}), do: x_lat+x_lng < y_lat+y_lng
  @spec coalesced_distance(point(), point()) :: distance()
  def coalesced_distance({x_lat, x_lng}, {y_lat, y_lng}), do: abs((x_lat+x_lng) - (y_lat+y_lng))

  @spec new(Enumerable.t(item)) :: t(item) when item: var
  def new(enum \\ []), do: TreeMap.new(enum, &coalesced_less/2)

  @spec add(t(item), point, item) :: t(item) when item: var
  def add(t, p, item), do: TreeMap.put(t, p, item)

  @doc """
  Return the corner of a box

  ## Examples
      iex> box({1.0, 2.0}, {3.0, 5.0})
      {{1.0, 2.0}, {3.0, 5.0}}
  """
  @spec box(point(), point()) :: {point(), point()}
  def box({x_lat, x_lng}, {y_lat, y_lng}) do
    [min_lat, max_lat] = Enum.sort([x_lat, y_lat])
    [min_lng, max_lng] = Enum.sort([x_lng, y_lng])
    {{min_lat, min_lng}, {max_lat, max_lng}}
  end

  @doc """
  Create a function that tests if point is within box

  ## Examples
      iex> b = box({1.0, 2.0}, {3.0, 5.0})
      iex> p = within?(b)
      iex> p.({1.0, 2.0})
      true
      iex> p.({3.0, 5.0})
      true
      iex> p.({3.0, 2.0})
      true
      iex> p.({1.0, 5.0})
      true
      iex> p.({0.9, 5.0})
      false
      iex> p.({3.1, 2.0})
      false
      iex> p.({1.0, 5.1})
      false
      iex> p.({1.0, 1.9})
      false
      {{1.0, 2.0}, {3.0, 5.0}}
  """
  @spec within?({point(), point()}) :: (point() -> boolean())
  def within?({{min_lat, min_lng}, {max_lat, max_lng}}) do
    fn {lat, lng} -> min_lat <= lat and lat <= max_lat and min_lng <= lng and lng <= max_lng end
  end

  @spec within_box(t(data), {point(), point()}) :: Iterator.t(item(data)) when data: var
  def within_box(t, {min, max} = box) do
    t
    |> TreeMap.from(min)
    |> TreeMap.until(max, t.less)
    |> Iterator.filter(within?(box))
  end

  # @spec t_to_item(t(data)) :: item(data) when data: var
  # defp t_to_item(t), do: {map_to_tup(t), t.item}

  # @spec item_to_t(item(data)) :: t(data) when data: var
  # defp item_to_t({{lat, lng}, item}), do: %Geo{lat: lat, lng: lng, item: item}

  # defp tup_to_map({lat, lng}), do: %{lat: lat, lng: lng}
  # defp map_to_tup(%{lat: lat, lng: lng}), do: {lat, lng}

  @spec from_list([item(data)]) :: t(data) when data: var
  def from_list(items), do: TreeMap.build(items, &coalesced_less/2)

  @spec to_list(t(data)) :: [item(data)] when data: var
  def to_list(t), do: t |> TreeMap.forward() |> Iterator.to_list()

  @spec haversine_distance(point(), point()) :: float()
  def haversine_distance({lat1, lng1}, {lat2, lng2}) do
    delta_lat = (lat2 - lat1) * radians_per_degree()
    delta_lng = (lng2 - lng1) * radians_per_degree()
    a = :math.pow(:math.sin(delta_lat/2.0), 2) +
        :math.cos(lat1 * radians_per_degree()) *
        :math.cos(lat2 * radians_per_degree()) *
        :math.pow(:math.sin(delta_lng/2.0), 2)
    2 * :math.atan2(:math.sqrt(a), :math.sqrt(1-a)) * @earth_radius_miles
  end

  @spec haversine_delta(point(), float(), float()) :: point()
  def haversine_delta({lat, lng}, lat_delta_miles, lng_delta_miles) do
    miles_to_degrees = fn miles -> (miles / @earth_radius_miles) * degrees_per_radian() end
    {lat + miles_to_degrees.(lat_delta_miles),
     lng + miles_to_degrees.(lng_delta_miles) / :math.cos(lat * radians_per_degree())}
  end

  defp radians_per_degree(), do: :math.pi()/180.0
  defp degrees_per_radian(), do: 180.0 / :math.pi()

  @spec nearest(t(data), point()) :: Iterator.t({distance(), item(data)}) when data: var
  def nearest(t, p), do: TreeMap.nearest(t, p, &coalesced_distance/2)

  #defp axis_distance(t, p, :lat), do: haversine_distance({t.lat, t.lng}, {p.lat, t.lng})
  #defp axis_distance(t, p, :lng), do: haversine_distance({t.lat, t.lng}, {t.lat, p.lng})

  @spec within_radius(t(data), point(), distance()) :: Iterator.t({distance(), item(data)}) when data: var
  def within_radius(t, origin, radius) do
    t
    |> TreeMap.nearest(origin, &coalesced_distance/2)
    |> Iterator.map(fn {_d, {p, item}} -> {haversine_distance(origin, p), {p, item}} end)
    |> Iterator.filter(fn {d, _} -> d <= radius end)
  end

  @spec load(Path.t()) :: t(term())
  def load(path) do
    path
    |> File.read!()
    |> :erlang.binary_to_term()
  end

  @spec save(Path.t(), t(term())) :: :ok
  def save(path, geo) do
    File.write!(path, :erlang.term_to_binary(geo))
  end

end
