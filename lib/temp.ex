# defmodule Geo do
#   defstruct [...]

#   @type t(item) :: %Geo{...} | nil
#   @type distance :: float()
#   @type lat :: float()
#   @type lng :: float()
#   @type lat_lng :: {lat(), lng()}
#   @type lat_lng_item(item) :: {lat_lng(), item}

#   @spec add(t(item), lat_lng_item(item)) :: t(item) when item: var
#   @spec nearest(t(item), lat_lng()) :: {distance(), lat_lng_item(item)} | :none when item: var
#   @spec from_list(list(lat_lng_item(item))) :: t(item) when item: var
#   @spec to_list(t(item)) :: list(lat_lng_item(item)) when item: var
# end

# defmodule GeoServer do
#   use GenServer

#   def init(state), do: {:ok, state}
# end
