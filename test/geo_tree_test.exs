defmodule GeoTreeTest do
  use ExUnit.Case
  doctest GeoTree, import: true

  alias TreeMap.Iterator

  def common_data(_ctx) do
    list = [{{-1.0, -1.0}, :d}, {{-1.0, 0.0}, :b}, {{-1.0, 1.0}, :e}, {{0.0, 0.0}, :a}, {{1.0, -1.0}, :f}, {{1.0, 0.0}, :c}, {{1.0, 1.0}, :g}]
    tree = GeoTree.new(list)
    %{
      list: list,
      tree: tree,
      cities:
        %{
          glasgow: {55.8617, 4.2583},
          san_francisco: {37.7749, 122.4194},
          london: {51.5072, 0.1276},
          los_angeles: {34.0549, 118.2426}
        }
    }
  end

  # describe "struct" do
  #   test "creation" do
  #     assert %_{lat: +0.0, lng: +0.0, item: :a} = %GeoTree{lat: 0.0, lng: 0.0, item: :a, left: nil, right: nil}
  #   end
  # end

  # describe "add/2" do
  #   test "nil case" do
  #     assert GeoTree.add(nil, {{0.0, 0.0}, :item}) == %GeoTree{lat: 0.0, lng: 0.0, item: :item}
  #   end
  # end

  describe "from_list/2" do
    setup [:common_data]
    test "happy path", context do
      assert GeoTree.from_list(context.list) == context.tree
    end
  end

  describe "to_list/2" do
    setup [:common_data]
    test "happy path", context do
      assert GeoTree.to_list(context.tree) ==  context.list
    end
  end

  describe "within_box/3" do
    setup [:common_data]
    test "a", context do
      assert GeoTree.within_box(context.tree, {-0.5, -0.5}, {0.5, 0.5}) |> Iterator.to_list() == [{{0.0, 0.0}, :a}]
    end

    test "b", context do
      assert GeoTree.within_box(context.tree, {-1.5, -0.5}, {-0.5, 0.5}) |> Iterator.to_list() == [{{-1.0, 0.0}, :b}]
    end

    test "c", context do
      assert GeoTree.within_box(context.tree, { 0.5, -0.5}, { 1.5, 0.5}) |> Iterator.to_list() == [{{1.0, 0.0}, :c}]
    end

    test "d", context do
      assert GeoTree.within_box(context.tree, { -1.5, -1.5}, { -0.5, -0.5}) |> Iterator.to_list() == [{{-1.0, -1.0}, :d}]
    end

    test "e", context do
      assert GeoTree.within_box(context.tree, {-1.5, 0.5}, { -0.5, 1.5}) |> Iterator.to_list() == [{{-1.0, 1.0}, :e}]
    end

    test "f", context do
      assert GeoTree.within_box(context.tree, {0.5, -1.5}, { 1.5, -0.5}) |> Iterator.to_list() == [{{1.0, -1.0}, :f}]
    end

    test "g", context do
      assert GeoTree.within_box(context.tree, {0.5, 0.5}, {1.5, 1.5}) |> Iterator.to_list() == [{{1.0, 1.0}, :g}]
    end
  end

  describe "within_radius/3" do
    setup [:common_data]
    test "a", context do
      assert GeoTree.within_radius(context.tree, {0.0, 0.0}, 50.0) |> Iterator.to_list() == [{0.0, {{0.0, 0.0}, :a}}]
      assert GeoTree.within_radius(context.tree, {0.0, 0.0}, 70.0) |> Iterator.to_list() == [{0.0, {{0.0, 0.0}, :a}}, {69.13249167149539, {{-1.0, 0.0}, :b}}, {69.13249167149539, {{1.0, 0.0}, :c}}]
      assert GeoTree.within_radius(context.tree, {0.0, 0.0}, 100.0) |> Iterator.to_list() == [{0.0, {{0.0, 0.0}, :a}}, {69.13249167149539, {{-1.0, 0.0}, :b}}, {69.13249167149539, {{1.0, 0.0}, :c}}, {97.76562536778685, {{-1.0, -1.0}, :d}}, {97.76562536778685, {{-1.0, 1.0}, :e}}, {97.76562536778685, {{1.0, -1.0}, :f}}, {97.76562536778685, {{1.0, 1.0}, :g}}]
    end

    test "b", context do
      assert GeoTree.within_radius(context.tree, {-1.0, 0.0}, 50.0) |> Iterator.to_list() == [{0.0, {{-1.0, 0.0}, :b}}]
      assert GeoTree.within_radius(context.tree, {-1.0, 0.0}, 70.0) |> Iterator.to_list() == [{0.0, {{-1.0, 0.0}, :b}}, {69.12196219093418, {{-1.0, -1.0}, :d}}, {69.12196219093418, {{-1.0, 1.0}, :e}}, {69.13249167149539, {{0.0, 0.0}, :a}}]
      assert GeoTree.within_radius(context.tree, {-1.0, 0.0}, 200.0) |> Iterator.to_list() == [{0.0, {{-1.0, 0.0}, :b}}, {69.12196219093418, {{-1.0, -1.0}, :d}}, {69.12196219093418, {{-1.0, 1.0}, :e}}, {69.13249167149539, {{0.0, 0.0}, :a}}, {138.26498334299077, {{1.0, 0.0}, :c}}, {154.58338114129137, {{1.0, -1.0}, :f}}, {154.58338114129137, {{1.0, 1.0}, :g}}]
    end
  end

  describe "nearest/2" do
    setup [:common_data]
    test "empty kd tree" do
      assert GeoTree.nearest(new(), {0.0, 0.0}).() |> :done
    end

    test "exact points", %{tree: tree} do
      assert GeoTree.nearest(tree, {0.0, 0.0}) == {0.0, {{0.0, 0.0}, :a}}
      assert GeoTree.nearest(tree, {-1.0, 0.0}) == {0.0, {{-1.0, 0.0}, :b}}
      assert GeoTree.nearest(tree, {1.0, 0.0}) == {0.0, {{1.0, 0.0}, :c}}
      assert GeoTree.nearest(tree, {-1.0, -1.0}) == {0.0, {{-1.0, -1.0}, :d}}
      assert GeoTree.nearest(tree, {-1.0, 1.0}) == {0.0, {{-1.0, 1.0}, :e}}
      assert GeoTree.nearest(tree, {1.0, -1.0}) == {0.0, {{1.0, -1.0}, :f}}
      assert GeoTree.nearest(tree, {1.0, 1.0}) == {0.0, {{1.0, 1.0}, :g}}
    end

    test "near points", %{tree: tree} do
      distance_1 = GeoTree.haversine_distance({0.01, 0.01}, {0.0, 0.0})
      distance_2 = GeoTree.haversine_distance({1.01, 0.01}, {1.0, 0.0})
      distance_3 = GeoTree.haversine_distance({1.01, 1.01}, {1.0, 1.0})
      assert GeoTree.nearest(tree, {0.01, 0.01}) == {distance_1, {{0.0, 0.0}, :a}}
      assert GeoTree.nearest(tree, {-1.01, 0.01}) == {distance_2, {{-1.0, 0.0}, :b}}
      assert GeoTree.nearest(tree, {1.01, 0.01}) == {distance_2, {{1.0, 0.0}, :c}}
      assert GeoTree.nearest(tree, {-1.01, -1.01}) == {distance_3, {{-1.0, -1.0}, :d}}
      assert GeoTree.nearest(tree, {-1.01, 1.01}) == {distance_3, {{-1.0, 1.0}, :e}}
      assert GeoTree.nearest(tree, {1.01, -1.01}) == {distance_3, {{1.0, -1.0}, :f}}
      assert GeoTree.nearest(tree, {1.01, 1.01}) == {distance_3, {{1.0, 1.0}, :g}}
    end
end
end
