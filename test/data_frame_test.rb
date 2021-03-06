require_relative "test_helper"

class DataFrameTest < Minitest::Test
  # constructors

  def test_data_frame
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal ["a", "b"], Rover::DataFrame.new(df).keys
  end

  def test_array
    df = Rover::DataFrame.new([{a: 1, b: "one"}, {a: 2, b: "two"}, {a: 3, b: "three"}])
    assert_vector [1, 2, 3], df[:a]
    assert_vector ["one", "two", "three"], df[:b]
    assert_equal 3, df.size
    assert_equal 3, df.length
    assert_equal 3, df.count
    assert df.any?
    assert !df.empty?
    assert_vector [1, 2], df.first(2)[:a]
    assert_equal [:a, :b], df.vector_names
    assert_equal [:a, :b], df.keys
    assert df.include?(:a)
    assert !df.include?(:c)
  end

  def test_array_missing
    df = Rover::DataFrame.new([{b: "one"}, {a: 2, b: "two"}, {a: 3}])
    assert df[:a][0].nan?
    assert_equal 2, df[:a][1]
    assert_equal 3, df[:a][2]
    assert_equal "one", df[:b][0]
    assert_equal "two", df[:b][1]
    assert_nil df[:b][2]
  end

  def test_array_invalid
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new([1, 2])
    end
    assert_equal "Array elements must be hashes", error.message
  end

  def test_hash
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_vector [1, 2, 3], df["a"]
    assert_vector ["one", "two", "three"], df["b"]
    assert_equal 3, df.size
    assert_vector [1, 2], df.first(2)["a"]
    assert_equal ["a", "b"], df.vector_names
    assert df.include?("a")
    assert !df.include?("c")
  end

  def test_hash_key
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new(1 => 1..3)
    end
    assert_equal "Key must be a string or symbol, got 1", error.message
  end

  def test_active_record_model
    User.delete_all
    users = 3.times.map { |i| User.create!(name: "User #{i}") }
    df = Rover::DataFrame.new(User)
    assert_equal ["id", "name"], df.vector_names
    assert_vector users.map(&:id), df["id"]
    assert_vector users.map(&:name), df["name"]
  end

  def test_active_record_relation
    User.delete_all
    users = 3.times.map { |i| User.create!(name: "User #{i}") }
    df = Rover::DataFrame.new(User.all)
    assert_equal ["id", "name"], df.vector_names
    assert_vector users.map(&:id), df["id"]
    assert_vector users.map(&:name), df["name"]
  end

  def test_invalid_data
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new(1)
    end
    assert_equal "Cannot cast to data frame: Integer", error.message
  end

  def test_different_sizes
    error = assert_raises(ArgumentError) do
      Rover::DataFrame.new({"a" => [1, 2, 3], "b" => [1, 2]})
    end
    assert_equal "Different sizes: [3, 2]", error.message
  end

  def test_scalar
    df = Rover::DataFrame.new({"a" => 1, "b" => [1, 2, 3]})
    assert_vector [1, 1, 1], df["a"]
    df["c"] = true
    assert_vector [true, true, true], df["c"]
    df["c"] = false
    assert_vector [false, false, false], df["c"]
  end

  def test_read_csv
    df = Rover.read_csv("test/support/data.csv")
    assert_equal ["a", "b"], df.vector_names
  end

  def test_parse_csv
    df = Rover.parse_csv("a,b\n1,one\n2,two\n3,three\n")
    assert_equal ["a", "b"], df.vector_names
  end

  # to methods

  def test_to_a
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal [{"a" => 1, "b" => "one"}, {"a" => 2, "b" => "two"}, {"a" => 3, "b" => "three"}], df.to_a
  end

  def test_to_h
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal ({"a" => [1, 2, 3], "b" => ["one", "two", "three"]}), df.to_h
  end

  def test_to_numo
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 4..6, "c" => 7..9})
    assert_equal [[1, 4, 7], [2, 5, 8], [3, 6, 9]], df.to_numo.to_a
  end

  def test_to_csv
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal "a,b\n1,one\n2,two\n3,three\n", df.to_csv
  end

  # TODO use to_iruby when released
  def test_to_html
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_match "<table>", df.to_html
  end

  # other

  def test_clear
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    df.clear
    assert_equal 0, df.size
    assert_empty df.keys
    assert df.empty?
    assert !df.any?
  end

  def test_sort_by
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    sorted = df.sort_by { |r| r["b"] }
    assert_vector [1, 3, 2], sorted["a"]
    assert_vector ["one", "three", "two"], sorted["b"]
    assert_vector [1, 2, 3], df["a"]
    assert_vector ["one", "two", "three"], df["b"]
  end

  def test_sort_by!
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    df.sort_by! { |r| r["b"] }
    assert_vector [1, 3, 2], df["a"]
    assert_vector ["one", "three", "two"], df["b"]
  end

  # TODO better test
  def test_sample
    df = Rover::DataFrame.new({"a" => [1, 2, 3], "b" => ["one", "two", "three"]})
    assert_equal 1, df.sample.size
    assert_equal 2, df.sample(2).size
    assert_equal 2, df.sample(2, random: Random.new(123)).size
  end

  def test_empty_size
    assert_equal 0,  Rover::DataFrame.new.size
  end

  def test_concat
    df = Rover::DataFrame.new({"a" => 1..3})
    df2 = Rover::DataFrame.new({"b" => 4..6})

    c1 = df + df
    assert_equal 6, c1.size
    assert_equal ["a"], c1.vector_names
    assert_vector [1, 2, 3, 1, 2, 3], c1["a"]

    df.concat(df2)
    assert_equal 6, df.size
    assert_equal ["a", "b"], df.vector_names
  end

  def test_merge
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 4..6})
    df2 = Rover::DataFrame.new({"b" => 7..9, "c" => 10..12})
    merged = df.merge(df2)
    assert_equal ["a", "b"], df.keys
    assert_equal ["b", "c"], df2.keys
    assert_equal ["a", "b", "c"], merged.keys
    assert_vector 1..3, merged["a"]
    assert_vector 7..9, merged["b"]
    assert_vector 10..12, merged["c"]
  end

  def test_merge!
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 4..6})
    df2 = Rover::DataFrame.new({"b" => 7..9, "c" => 10..12})
    df.merge!(df2)
    assert_equal ["a", "b", "c"], df.keys
    assert_vector 1..3, df["a"]
    assert_vector 7..9, df["b"]
    assert_vector 10..12, df["c"]
  end

  def test_merge_different_sizes
    df = Rover::DataFrame.new({"a" => 1..3})
    df2 = Rover::DataFrame.new({"b" => [1]})
    error = assert_raises(ArgumentError) do
      df.merge(df2)
    end
    assert_equal "Size mismatch: expected 3, got 1", error.message
  end

  def test_inner_join
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2],
      b: ["one", "one", "two"],
      c: ["c1", "c2", "c3"]
    })

    assert_equal expected, df.inner_join(other_df)
  end

  def test_inner_join_on_hash
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a2: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2],
      b: ["one", "one", "two"],
      a2: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    assert_equal expected, df.inner_join(other_df, on: {a: :a2})
  end

  def test_inner_join_empty
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a: [4],
      c: ["c1"]
    })

    result = df.inner_join(other_df)
    assert_equal 0, result.size
    assert_equal [:a, :b, :c], result.keys
  end

  def test_inner_join_on_bad
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    error = assert_raises(ArgumentError) do
      df.inner_join(df, on: :bad)
    end
    assert_equal "Missing keys: bad", error.message
  end

  def test_left_join
    df = Rover::DataFrame.new({
      a: [1, 2, 3],
      b: ["one", "two", "three"]
    })

    other_df = Rover::DataFrame.new({
      a: [1, 1, 2],
      c: ["c1", "c2", "c3"]
    })

    expected = Rover::DataFrame.new({
      a: [1, 1, 2, 3],
      b: ["one", "one", "two", "three"],
      c: ["c1", "c2", "c3", nil]
    })

    assert_equal expected, df.left_join(other_df)
  end

  def test_delete
    df = Rover::DataFrame.new({"a" => 1..3, "b" => "a".."c"})
    assert_vector [1, 2, 3], df.delete("a")
    assert_equal ["b"], df.vector_names
  end

  def test_except
    df = Rover::DataFrame.new({"a" => 1..3, "b" => "a".."c", "c" => 1..3})
    assert_equal ["a"], df.except("b", "c").vector_names
    assert_equal ["a", "b", "c"], df.vector_names
  end

  def test_except!
    df = Rover::DataFrame.new({"a" => 1..3, "b" => "a".."c", "c" => 1..3})
    df.except!("b", "c")
    assert_equal ["a"], df.vector_names
  end

  def test_select
    df = Rover::DataFrame.new({"a" => 1..3, "b" => 1..3, "c" => 1..3})
    assert_equal ["a", "b"], df[["a", "b"]].vector_names
  end

  def test_reader
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    assert_vector [2], df[1]["a"]
    assert_vector [1, 2], df[0..1]["a"]
    assert_vector [1, 3], df[[0, 2]]["a"]
  end

  def test_reader_where
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    where = Rover::Vector.new([true, false, true])
    assert_vector [1, 3], df[where]["a"]
  end

  def test_setter
    df = Rover::DataFrame.new({"a" => [1, 2, 3]})
    df["b"] = 1
    assert_vector [1, 1, 1], df["b"]
    error = assert_raises(ArgumentError) do
      df["c"] = [1, 2]
    end
    assert_equal "Size mismatch: expected 3, got 2", error.message
  end

  def test_setter_empty
    df = Rover::DataFrame.new
    df["a"] = [1, 2, 3]
    assert_vector [1, 2, 3], df["a"]
  end

  def test_inspect
    df = Rover::DataFrame.new({"a" => 1..8, "b" => ["one", "two", "three", "four", "five", "six", "seven", "eight"]})
    assert_equal "  a      b\n  1    one\n  2    two\n  3  three\n  4   four\n  5   five\n...    ...", df.inspect
  end

  def test_inspect_empty
    df = Rover::DataFrame.new
    assert_equal "#<Rover::DataFrame>", df.inspect
  end
end
