defmodule Queue do
  @type t(item) :: {[item], [item]}

  @doc """
  Test for empty queue

  ## Examples

      iex> Queue.empty?(Queue.new)
      true

      iex> Queue.empty?(Queue.new() |> Queue.push(5))
      false
  """
  @spec empty?(t(term())) :: boolean()
  def empty?({[], []}), do: true
  def empty?(_), do: false

  @spec new() :: t(term())
  def new(), do: {[], []}

  @spec push(t(item), item) :: t(item) when item: var
  def push({front, back}, item), do: {front, [item | back]}

  @spec pop(t(item)) :: {t(item), item | :none} when item: var
  def pop({[], []} = q), do: {q, :none}
  def pop({[], back}), do: pop({Enum.reverse(back), []})
  def pop({[item | front], back}), do: {{front, back}, item}
end
