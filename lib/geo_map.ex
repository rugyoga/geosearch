defmodule GeoMap do
  defstruct [:lat, :lng, :item, :left, :right]

  @earth_radius_miles 3_961.0
  @max_distance 50_000.0
  @first_level :lat

  @opaque t(item) :: %GeoMap{lat: latitude(), lng: longitude(), item: item, left: t(item), right: t(item)} | nil
  @type latitude :: float()
  @type longitude :: float()
  @type distance :: float()
  @type axis :: :lat | :lng
  @type direction :: :left | :right
  @type point :: {latitude(), longitude()}
  @type pointm :: %{lat: latitude(), lng: longitude()}
  @type geo_item(item) :: {point(), item}

  @type queue(t) :: {[t], [t]}

  @spec add(t(item), geo_item(item)) :: t(item) when item: var
  def add(t, geo_item), do: add(t, item_to_t(geo_item), @first_level)

  @spec add(t(item), t(item), axis()) :: t(item) when item: var
  defp add(nil, new, _), do: new
  defp add(t, new, axis), do:
    Map.update!(t, direction(new, t, axis), &add(&1, new, flip_axis(axis)))

  @spec direction(t(item), t(item), axis()) :: direction() when item: var
  defp direction(a, b, :lat), do: if(a.lat < b.lat, do: :left, else: :right)
  defp direction(a, b, :lng), do: if(a.lng < b.lng, do: :left, else: :right)

  @spec flip_axis(axis()) :: axis()
  defp flip_axis(:lat), do: :lng
  defp flip_axis(:lng), do: :lat

  @spec flip_dir(direction()) :: direction()
  defp flip_dir(:left), do: :right
  defp flip_dir(:right), do: :left

  @spec within_box(t(item), point(), point()) :: [geo_item(item)] when item: var
  def within_box(t, {a_lat, a_lng}, {b_lat, b_lng}) do
    {min_lat, max_lat} = Enum.min_max([a_lat, b_lat])
    {min_lng, max_lng} = Enum.min_max([a_lng, b_lng])
    within_box(t, tup_to_map({min_lat, min_lng}),  tup_to_map({max_lat, max_lng}), @first_level)
  end

  @spec within_box(t(item), pointm(), pointm(), axis()) :: [geo_item(item)] when item: var
  defp within_box(nil, _, _, _), do: []
  defp within_box(t, min, max, axis) do
    lte? = fn a, b, f -> Map.fetch!(a, f) <= Map.fetch!(b, f) end
    other_axis = flip_axis(axis)
    if lte?.(min, t, axis) do
      if lte?.(t, max, axis) do
        subtrees = [t.left, t.right] |> Enum.flat_map(&within_box(&1, min, max, other_axis))
        if lte?.(min, t, other_axis) and lte?.(t, max, other_axis) do
          [t_to_item(t) | subtrees]
        else
          subtrees
        end
      else
        within_box(t.left, min, max, other_axis)
      end
    else
      within_box(t.right, min, max, other_axis)
    end
  end

  @spec t_to_item(t(item)) :: geo_item(item) when item: var
  defp t_to_item(t), do: {map_to_tup(t), t.item}

  @spec item_to_t(geo_item(item)) :: t(item) when item: var
  defp item_to_t({{lat, lng}, item}), do: %GeoMap{lat: lat, lng: lng, item: item}

  defp tup_to_map({lat, lng}), do: %{lat: lat, lng: lng}
  defp map_to_tup(%{lat: lat, lng: lng}), do: {lat, lng}

  @spec from_list([geo_item(item)]) :: t(item) when item: var
  def from_list(geo_items), do: geo_items |> Enum.reduce(nil, fn item, t -> add(t, item) end)

  @spec to_list(t(item)) :: [geo_item(item)] when item: var
  def to_list(t), do: to_list(Queue.new(), t)

  @spec to_list(Queue.t(t(item)), t(item)) :: [geo_item(item)] when item: var
  defp to_list(q, nil) do
    {q, t} = Queue.pop(q)
    if(t == :none, do: [], else: to_list(q, t))
  end

  defp to_list(q, %GeoMap{} = g), do:
    [{map_to_tup(g), g.item} | Enum.reduce([g.left, g.right], q, &cond_push/2) |> to_list(nil)]

  @spec cond_push(Queue.t(item), item | nil) :: Queue.t(item) when item: var
  defp cond_push(nil, q), do: q
  defp cond_push(item, q), do: Queue.push(q, item)


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

  @spec unwrap_geo({distance(), nil | t(item)}) :: {distance(), geo_item(item)} | :none when item: var
  defp unwrap_geo({d, pointm}), do: if(is_nil(pointm), do: :none, else: {d, t_to_item(pointm)})

  @spec nearest(t(item), point()) :: {distance(), geo_item(item)} | :none when item: var
  def nearest(t, p), do: nearest(t, tup_to_map(p), @first_level, {@max_distance, nil}) |> unwrap_geo()

  @spec nearest(t(item), pointm(), axis, {distance(), t(item) | nil}) :: {distance(), t(item)} when item: var
  defp nearest(nil, _p, _axis, best), do: best
  defp nearest(t, p, axis, best) do
    direction = if(Map.fetch!(t, axis) < Map.fetch!(p, axis), do: :left, else: :right)
    other_axis = flip_axis(axis)
    other_direction = flip_dir(direction)
    best = nearest(Map.fetch!(t, direction), p, other_axis, best)
    {best_distance, _} = best
    if axis_distance(t, p, axis) < best_distance do
      t_distance = haversine_distance(map_to_tup(p), map_to_tup(t))
      best = if(t_distance < best_distance, do: {t_distance, t}, else: best)
      nearest(Map.fetch!(t, other_direction), p, other_axis, best)
    else
      best
    end
  end

  defp axis_distance(t, p, :lat), do: haversine_distance({t.lat, t.lng}, {p.lat, t.lng})
  defp axis_distance(t, p, :lng), do: haversine_distance({t.lat, t.lng}, {t.lat, p.lng})

  @spec within_radius(t(item), point(), distance()) :: [geo_item(item)] when item: var
  def within_radius(t, p, radius) do
    within_box(t, haversine_delta(p, -radius, -radius), haversine_delta(p, radius, radius))
    |> Enum.map(fn {q, _}=lli -> {haversine_distance(p, q), lli} end)
    |> Enum.reject(fn {distance, _} -> distance > radius end)
    |> Enum.sort()
  end

end
