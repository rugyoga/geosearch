defmodule Heap do
  @type heap(a) :: node(a) | nil
  @type node(a) :: {a, heap(a), heap(a)}

  @spec tree(a, heap(a), heap(a)) :: heap(a) when a: var
  def tree(x, l \\ nil, r \\ nil), do: {x, l, r}

  @spec new :: heap(term)
  def new, do: nil

  @spec union(heap(a), heap(a)) :: heap(a) when a: var
  def union(nil, t2), do: t2
  def union(t1, nil), do: t1
  def union({{p1, _} = x1, l1, r1}, {{p2, _}, _, _} = t2) when p1 <= p2, do: tree(x1, union(t2, r1), l1)
  def union(t1, {x2, l2, r2}), do: tree(x2, union(t1, r2), l2)

  @spec push(heap(a), a) :: heap(a) when a: var
  def push(heap, x), do: x |> tree |> union(heap)


  @doc """
  Peek at root

  ## Examples

      iex> Heap.pop(Heap.new)
      {:empty, nil}

      iex> Heap.new() |> Heap.push({2, :a}) |> Heap.push({1, :b}) |> Heap.push({3, :c}) |> Heap.pop() |> elem(0)
      {1, :b}
  """
  @spec pop(heap(a)) :: {a | :empty, heap(a)} when a: var
  def pop(nil), do: {:empty, nil}
  def pop({x, l, r}), do: {x, union(l, r)}

  @doc """
  Peek at root

  ## Examples

      iex> Heap.peek(Heap.new)
      :empty

      iex> Heap.peek(Heap.tree(5))
      5
  """
  @spec peek(heap(a)) :: :empty | a when a: var
  def peek(nil), do: :empty
  def peek({x, _, _}), do: x

  @doc """
  Test for empty heap

  ## Examples

      iex> Heap.empty?(Heap.new)
      true

      iex> Heap.empty?(Heap.tree(5))
      false
  """
  @spec empty?(heap(term())) :: boolean()
  def empty?(nil), do: true
  def empty?(_), do: false

  @doc """
  turn heap into list

  ## Examples


      iex> Heap.new() |> Heap.push({1, :b}) |> Heap.push({2, :a}) |> Heap.push({3, :c}) |> Heap.to_list()
      [{1, :b}, {2, :a}, {3, :c}]
      iex> Heap.new() |> Heap.push({1, :b}) |> Heap.push({3, :c}) |> Heap.push({2, :a}) |> Heap.to_list()
      [{1, :b}, {2, :a}, {3, :c}]
      iex> Heap.new() |> Heap.push({2, :a}) |> Heap.push({1, :b}) |> Heap.push({3, :c}) |> Heap.to_list()
      [{1, :b}, {2, :a}, {3, :c}]
      iex> Heap.new() |> Heap.push({2, :a}) |> Heap.push({3, :c}) |> Heap.push({1, :b}) |> Heap.to_list()
      [{1, :b}, {2, :a}, {3, :c}]
      iex> Heap.new() |> Heap.push({3, :c}) |> Heap.push({1, :b}) |> Heap.push({2, :a}) |> Heap.to_list()
      [{1, :b}, {2, :a}, {3, :c}]
      iex> Heap.new() |> Heap.push({3, :c}) |> Heap.push({2, :a}) |> Heap.push({1, :b}) |> Heap.to_list()
      [{1, :b}, {2, :a}, {3, :c}]
  """
  @spec to_list(heap(a)) :: [a] when a: var
  def to_list(nil), do: []
  def to_list(h) do
      {item, new_h} = pop(h)
      [item | to_list(new_h)]
  end

  # defimpl String.Chars, for: Heap do
  #   def to_string(heap) do
  #     "%Heap{ <#{Heap.to_list(heap)}> }"
  #   end
  # end
end
