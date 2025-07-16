# Object Hash List Diff Performance Benchmark
# Run with: mix run object_hash_benchmark.exs

defmodule ObjectHashBenchmark do
  @doc """
  Prepare test cases focused on list diffing with object hashing
  """
  def prepare_test_cases() do
    %{
      "Small List (20 items)" => prepare_list_case(20),
      "Medium List (100 items)" => prepare_list_case(100),
      "Large List (500 items)" => prepare_list_case(500),
      "Very Large List (1000 items)" => prepare_list_case(1_000),
      "Nested Lists - User Management" => prepare_nested_case(),
      "Complex Objects - Product Catalog" => prepare_complex_objects_case(),
      "Mixed Operations - Social Feed" => prepare_mixed_operations_case()
    }
  end

  defp prepare_list_case(size) do
    # Create original list with sequential IDs
    original =
      1..size
      |> Enum.map(fn id ->
        %{
          "id" => id,
          "name" => "Item #{id}",
          "status" => Enum.random(["active", "inactive", "pending"]),
          "value" => :rand.uniform(1_000),
          "metadata" => %{
            "created_at" => "2023-01-#{rem(id, 28) + 1}T10:00:00Z",
            "category" => Enum.random(["A", "B", "C", "D"])
          }
        }
      end)

    # Create modified list with various operations:
    # - Remove some items (every 7th item)
    # - Modify some items (every 5th item)
    # - Add new items
    # - Reorder some items
    modified =
      original
      |> Enum.reject(fn %{"id" => id} -> rem(id, 7) == 0 end)  # Remove every 7th
      |> Enum.map(fn item ->
        if rem(item["id"], 5) == 0 do
          # Modify every 5th item
          %{item | "name" => "Modified #{item["name"]}", "value" => item["value"] * 2}
        else
          item
        end
      end)
      |> then(fn list ->
        # Add some new items
        new_items =
          (size + 1)..(size + div(size, 10))
          |> Enum.map(fn id ->
            %{
              "id" => id,
              "name" => "New Item #{id}",
              "status" => "new",
              "value" => :rand.uniform(1_000),
              "metadata" => %{
                "created_at" => "2023-12-01T10:00:00Z",
                "category" => "NEW"
              }
            }
          end)

        list ++ new_items
      end)
      |> Enum.shuffle()  # Reorder items

    %{doc: original, expected: modified}
  end

  defp prepare_nested_case() do
    original = %{
      "users" => [
        %{
          "id" => 1,
          "name" => "Alice",
          "permissions" => [
            %{"id" => 101, "resource" => "posts", "action" => "read"},
            %{"id" => 102, "resource" => "posts", "action" => "write"},
            %{"id" => 103, "resource" => "users", "action" => "read"}
          ]
        },
        %{
          "id" => 2,
          "name" => "Bob",
          "permissions" => [
            %{"id" => 201, "resource" => "posts", "action" => "read"},
            %{"id" => 202, "resource" => "comments", "action" => "write"}
          ]
        },
        %{
          "id" => 3,
          "name" => "Charlie",
          "permissions" => [
            %{"id" => 301, "resource" => "posts", "action" => "read"}
          ]
        }
      ],
      "groups" => [
        %{
          "id" => 10,
          "name" => "Admins",
          "members" => [
            %{"id" => 1, "role" => "owner"},
            %{"id" => 2, "role" => "admin"}
          ]
        },
        %{
          "id" => 20,
          "name" => "Users",
          "members" => [
            %{"id" => 2, "role" => "member"},
            %{"id" => 3, "role" => "member"}
          ]
        }
      ]
    }

    expected = %{
      "users" => [
        %{
          "id" => 1,
          "name" => "Alice Smith",
          "permissions" => [
            %{"id" => 101, "resource" => "posts", "action" => "read"},
            %{"id" => 102, "resource" => "posts", "action" => "write"},
            %{"id" => 103, "resource" => "users", "action" => "read"},
            %{"id" => 104, "resource" => "users", "action" => "write"}
          ]
        },
        %{
          "id" => 4,
          "name" => "David",
          "permissions" => [
            %{"id" => 401, "resource" => "posts", "action" => "read"}
          ]
        },
        %{
          "id" => 3,
          "name" => "Charlie Brown",
          "permissions" => [
            %{"id" => 301, "resource" => "posts", "action" => "read"},
            %{"id" => 302, "resource" => "comments", "action" => "read"}
          ]
        }
      ],
      "groups" => [
        %{
          "id" => 10,
          "name" => "Administrators",
          "members" => [
            %{"id" => 1, "role" => "owner"},
            %{"id" => 4, "role" => "admin"}
          ]
        },
        %{
          "id" => 30,
          "name" => "Moderators",
          "members" => [
            %{"id" => 3, "role" => "moderator"}
          ]
        }
      ]
    }

    %{doc: original, expected: expected}
  end

  defp prepare_complex_objects_case() do
    original = [
      %{
        "id" => "prod-001",
        "name" => "Laptop Pro",
        "price" => 1299.99,
        "variants" => [
          %{"id" => "var-001", "color" => "silver", "storage" => "256GB", "stock" => 10},
          %{"id" => "var-002", "color" => "space-gray", "storage" => "512GB", "stock" => 5}
        ],
        "reviews" => [
          %{"id" => "rev-001", "rating" => 5, "comment" => "Excellent!"},
          %{"id" => "rev-002", "rating" => 4, "comment" => "Very good"}
        ]
      },
      %{
        "id" => "prod-002",
        "name" => "Wireless Mouse",
        "price" => 79.99,
        "variants" => [
          %{"id" => "var-003", "color" => "black", "connectivity" => "bluetooth", "stock" => 25},
          %{"id" => "var-004", "color" => "white", "connectivity" => "usb", "stock" => 15}
        ],
        "reviews" => [
          %{"id" => "rev-003", "rating" => 4, "comment" => "Good quality"}
        ]
      },
      %{
        "id" => "prod-003",
        "name" => "Keyboard",
        "price" => 129.99,
        "variants" => [
          %{"id" => "var-005", "layout" => "US", "switches" => "mechanical", "stock" => 8}
        ],
        "reviews" => []
      }
    ]

    expected = [
      %{
        "id" => "prod-001",
        "name" => "Laptop Pro Max",
        "price" => 1499.99,
        "variants" => [
          %{"id" => "var-001", "color" => "silver", "storage" => "256GB", "stock" => 8},
          %{"id" => "var-002", "color" => "space-gray", "storage" => "512GB", "stock" => 3},
          %{"id" => "var-006", "color" => "gold", "storage" => "1TB", "stock" => 2}
        ],
        "reviews" => [
          %{"id" => "rev-001", "rating" => 5, "comment" => "Excellent product!"},
          %{"id" => "rev-002", "rating" => 4, "comment" => "Very good"},
          %{"id" => "rev-004", "rating" => 5, "comment" => "Amazing performance"}
        ]
      },
      %{
        "id" => "prod-004",
        "name" => "Wireless Headphones",
        "price" => 199.99,
        "variants" => [
          %{"id" => "var-007", "color" => "black", "noise_cancelling" => true, "stock" => 12}
        ],
        "reviews" => [
          %{"id" => "rev-005", "rating" => 5, "comment" => "Great sound quality"}
        ]
      },
      %{
        "id" => "prod-003",
        "name" => "Mechanical Keyboard",
        "price" => 149.99,
        "variants" => [
          %{"id" => "var-005", "layout" => "US", "switches" => "mechanical", "stock" => 12},
          %{"id" => "var-008", "layout" => "UK", "switches" => "mechanical", "stock" => 5}
        ],
        "reviews" => [
          %{"id" => "rev-006", "rating" => 4, "comment" => "Solid build quality"}
        ]
      }
    ]

    %{doc: original, expected: expected}
  end

  defp prepare_mixed_operations_case() do
    # Simulate a social media feed with posts, comments, and reactions
    original = [
      %{
        "id" => "post-1",
        "content" => "Beautiful sunset today!",
        "author" => "alice",
        "timestamp" => "2023-01-01T18:00:00Z",
        "comments" => [
          %{"id" => "comment-1", "author" => "bob", "text" => "Amazing!"},
          %{"id" => "comment-2", "author" => "charlie", "text" => "Where was this?"}
        ],
        "reactions" => [
          %{"id" => "react-1", "user" => "bob", "type" => "like"},
          %{"id" => "react-2", "user" => "charlie", "type" => "love"}
        ]
      },
      %{
        "id" => "post-2",
        "content" => "Just finished my morning run!",
        "author" => "bob",
        "timestamp" => "2023-01-02T08:00:00Z",
        "comments" => [
          %{"id" => "comment-3", "author" => "alice", "text" => "Great job!"}
        ],
        "reactions" => [
          %{"id" => "react-3", "user" => "alice", "type" => "like"}
        ]
      },
      %{
        "id" => "post-3",
        "content" => "Working on a new project",
        "author" => "charlie",
        "timestamp" => "2023-01-03T14:00:00Z",
        "comments" => [],
        "reactions" => []
      }
    ]

    expected = [
      %{
        "id" => "post-1",
        "content" => "Beautiful sunset today! #nature",
        "author" => "alice",
        "timestamp" => "2023-01-01T18:00:00Z",
        "comments" => [
          %{"id" => "comment-1", "author" => "bob", "text" => "Amazing! Where is this?"},
          %{"id" => "comment-4", "author" => "david", "text" => "Stunning colors!"}
        ],
        "reactions" => [
          %{"id" => "react-1", "user" => "bob", "type" => "like"},
          %{"id" => "react-2", "user" => "charlie", "type" => "love"},
          %{"id" => "react-4", "user" => "david", "type" => "wow"}
        ]
      },
      %{
        "id" => "post-4",
        "content" => "New coffee shop discovery!",
        "author" => "david",
        "timestamp" => "2023-01-04T09:00:00Z",
        "comments" => [
          %{"id" => "comment-5", "author" => "alice", "text" => "I need to try this!"}
        ],
        "reactions" => [
          %{"id" => "react-5", "user" => "alice", "type" => "like"}
        ]
      },
      %{
        "id" => "post-3",
        "content" => "Working on a new exciting project!",
        "author" => "charlie",
        "timestamp" => "2023-01-03T14:00:00Z",
        "comments" => [
          %{"id" => "comment-6", "author" => "bob", "text" => "Can't wait to see it!"}
        ],
        "reactions" => [
          %{"id" => "react-6", "user" => "bob", "type" => "like"}
        ]
      }
    ]

    %{doc: original, expected: expected}
  end

  @doc """
  Hash function for objects with ID
  """
  def id_hash_fn(%{"id" => id}), do: id
  # def id_hash_fn(string) when is_binary(string), do: string
  def id_hash_fn(_item), do: raise "Unable to find hash"

  @doc """
  Run the benchmark comparing with and without object_hash
  """
  def run_benchmark() do
    Benchee.run(
      %{
        "Without object_hash (pairwise)" => fn %{doc: doc, expected: expected} ->
          Jsonpatch.diff(doc, expected)
        end,
        "With object_hash (greedy)" => fn %{doc: doc, expected: expected} ->
          Jsonpatch.diff(doc, expected, object_hash: &id_hash_fn/1)
        end,
      },
      inputs: prepare_test_cases(),
      warmup: 0.2,
      time: 1.0,
      memory_time: 0.5,
      reduction_time: 0.5,
      parallel: 1,
      formatters: [
        Benchee.Formatters.Console
      ],
      print: [
        benchmarking: true,
        configuration: true,
        fast_warning: false
      ]
    )
  end

  @doc """
  Run a detailed analysis showing the patches generated
  """
  def analyze_patches() do
    IO.puts("=== Patch Analysis ===\n")

    test_cases = prepare_test_cases()

    Enum.each(test_cases, fn {name, %{doc: doc, expected: expected}} ->
      IO.puts("## #{name}")

      patches_without_hash = Jsonpatch.diff(doc, expected)
      patches_with_hash = Jsonpatch.diff(doc, expected, object_hash: &id_hash_fn/1)

      IO.puts("Without object_hash: #{length(patches_without_hash)} patches")
      IO.puts("With object_hash: #{length(patches_with_hash)} patches")

      # # Show first few patches for comparison
      # IO.puts("\nFirst 3 patches without object_hash:")
      # patches_without_hash |> Enum.take(3) |> Enum.each(&IO.inspect/1)

      IO.puts("")

      # IO.puts("\nFirst 3 patches with object_hash:")
      # patches_with_hash |> Enum.take(3) |> Enum.each(&IO.inspect/1)

      IO.puts("Result with object_hash: #{Jsonpatch.apply_patch!(patches_with_hash, doc) == expected}")
      IO.puts("Result without object_hash: #{Jsonpatch.apply_patch!(patches_without_hash, doc) == expected}")
      IO.puts("\n" <> String.duplicate("-", 50) <> "\n")

    end)
  end
end

# Run the benchmark
IO.puts("Starting Object Hash Benchmark...")
IO.puts("This benchmark compares list diffing performance with and without object_hash option.")
IO.puts("The object_hash option uses LCS algorithm to better handle list reordering.\n")

ObjectHashBenchmark.run_benchmark()

# Uncomment to see patch analysis
# ObjectHashBenchmark.analyze_patches()
