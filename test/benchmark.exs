# Jsonpatch Diff Performance Benchmark
# Run with: mix run test/benchmark.exs

defmodule JsonpatchBenchmark do
  @doc """
  Prepare complex test cases for benchmarking
  """
  def prepare_test_cases() do
    %{
      "Complex Maps - E-commerce Order" => %{
        doc: %{
          "order_id" => "12345",
          "customer" => %{
            "name" => "John Doe",
            "email" => "john@example.com",
            "address" => %{
              "street" => "123 Main St",
              "city" => "Springfield",
              "country" => "USA"
            }
          },
          "items" => %{
            "item1" => %{"name" => "Laptop", "price" => 999.99, "quantity" => 1},
            "item2" => %{"name" => "Mouse", "price" => 29.99, "quantity" => 2}
          },
          "status" => "pending",
          "total" => 1059.97
        },
        expected: %{
          "order_id" => "12345",
          "customer" => %{
            "name" => "John Doe",
            "email" => "john.doe@example.com",
            "address" => %{
              "street" => "456 Oak Ave",
              "city" => "Springfield",
              "country" => "USA",
              "zipcode" => "12345"
            },
            "phone" => "+1-555-0123"
          },
          "items" => %{
            "item1" => %{"name" => "Gaming Laptop", "price" => 1299.99, "quantity" => 1},
            "item3" => %{"name" => "Keyboard", "price" => 79.99, "quantity" => 1}
          },
          "status" => "confirmed",
          "total" => 1379.98,
          "discount" => 50.00
        }
      },
      "Complex Lists - Task Management" => %{
        doc: [
          %{
            "id" => 1,
            "task" => "Write documentation",
            "priority" => "high",
            "completed" => false
          },
          %{"id" => 2, "task" => "Fix bug #123", "priority" => "medium", "completed" => true},
          %{"id" => 3, "task" => "Review PR", "priority" => "low", "completed" => false},
          %{"id" => 4, "task" => "Deploy to staging", "priority" => "high", "completed" => false},
          %{"id" => 5, "task" => "Update tests", "priority" => "medium", "completed" => true}
        ],
        expected: [
          %{
            "id" => 1,
            "task" => "Write comprehensive documentation",
            "priority" => "high",
            "completed" => true
          },
          %{
            "id" => 6,
            "task" => "Optimize database queries",
            "priority" => "high",
            "completed" => false
          },
          %{"id" => 3, "task" => "Review PR", "priority" => "medium", "completed" => false},
          %{"id" => 7, "task" => "Setup monitoring", "priority" => "low", "completed" => false},
          %{
            "id" => 4,
            "task" => "Deploy to production",
            "priority" => "critical",
            "completed" => false
          }
        ]
      },
      "Mixed Maps and Lists - Social Media Post" => %{
        doc: %{
          "post_id" => "abc123",
          "content" => "Just had an amazing day!",
          "author" => %{
            "username" => "johndoe",
            "followers" => 1250,
            "verified" => false
          },
          "comments" => [
            %{"user" => "alice", "text" => "Great to hear!", "likes" => 5},
            %{"user" => "bob", "text" => "Awesome!", "likes" => 3}
          ],
          "tags" => ["happy", "life"],
          "metadata" => %{
            "created_at" => "2023-01-01T10:00:00Z",
            "location" => "New York",
            "device" => "mobile"
          }
        },
        expected: %{
          "post_id" => "abc123",
          "content" => "Just had an absolutely amazing day! #blessed",
          "author" => %{
            "username" => "johndoe",
            "followers" => 1275,
            "verified" => true,
            "display_name" => "John Doe"
          },
          "comments" => [
            %{"user" => "alice", "text" => "Great to hear! So happy for you!", "likes" => 8},
            %{"user" => "charlie", "text" => "Inspiring!", "likes" => 2},
            %{"user" => "bob", "text" => "Awesome!", "likes" => 3, "reply_to" => "alice"}
          ],
          "tags" => ["happy", "life", "blessed", "inspiration"],
          "metadata" => %{
            "created_at" => "2023-01-01T10:00:00Z",
            "updated_at" => "2023-01-01T10:15:00Z",
            "location" => "New York",
            "device" => "mobile",
            "engagement_score" => 8.5
          },
          "reactions" => %{
            "likes" => 45,
            "shares" => 12,
            "hearts" => 23
          }
        }
      },
      "Deep Nesting - Configuration Tree" => %{
        doc: %{
          "application" => %{
            "name" => "MyApp",
            "version" => "1.0.0",
            "modules" => %{
              "authentication" => %{
                "enabled" => true,
                "providers" => %{
                  "oauth" => %{
                    "google" => %{"client_id" => "123", "scopes" => ["email", "profile"]},
                    "github" => %{"client_id" => "456", "scopes" => ["user:email"]}
                  },
                  "local" => %{"enabled" => true, "password_policy" => %{"min_length" => 8}}
                }
              },
              "database" => %{
                "primary" => %{
                  "host" => "localhost",
                  "port" => 5432,
                  "name" => "myapp_db",
                  "pool" => %{"size" => 10, "timeout" => 5000}
                },
                "replica" => %{
                  "host" => "replica.example.com",
                  "port" => 5432,
                  "name" => "myapp_db"
                }
              }
            }
          }
        },
        expected: %{
          "application" => %{
            "name" => "MyApp",
            "version" => "1.1.0",
            "modules" => %{
              "authentication" => %{
                "enabled" => true,
                "providers" => %{
                  "oauth" => %{
                    "google" => %{
                      "client_id" => "123",
                      "scopes" => ["email", "profile", "calendar"]
                    },
                    "github" => %{"client_id" => "789", "scopes" => ["user:email", "read:user"]},
                    "microsoft" => %{"client_id" => "999", "scopes" => ["User.Read"]}
                  },
                  "local" => %{
                    "enabled" => true,
                    "password_policy" => %{"min_length" => 12, "require_symbols" => true}
                  },
                  "saml" => %{
                    "enabled" => false,
                    "metadata_url" => "https://sso.example.com/metadata"
                  }
                }
              },
              "database" => %{
                "primary" => %{
                  "host" => "db.example.com",
                  "port" => 5432,
                  "name" => "myapp_production",
                  "pool" => %{"size" => 20, "timeout" => 10000, "idle_timeout" => 30000}
                },
                "cache" => %{
                  "host" => "redis.example.com",
                  "port" => 6379,
                  "ttl" => 3600
                }
              },
              "monitoring" => %{
                "metrics" => %{"enabled" => true, "interval" => 60},
                "logging" => %{"level" => "info", "format" => "json"}
              }
            },
            "features" => %{
              "feature_flags" => %{"new_ui" => true, "beta_features" => false}
            }
          }
        }
      }
    }
  end

  @doc """
  Run the benchmark
  """
  def run_benchmark() do
    Benchee.run(
      %{
        # I was using it for performance comparision, now faster version is the default one
        # "Faster JsonPatch" => fn %{doc: doc, expected: expected} ->
        #   Jsonpatch.Faster.diff(doc, expected)
        # end,
        "JsonPatch" => fn %{doc: doc, expected: expected} ->
          Jsonpatch.diff(doc, expected)
        end
      },
      inputs: prepare_test_cases(),
      warmup: 0.1,
      time: 0.5,
      memory_time: 0.2,
      reduction_time: 0.2,
      parallel: 2,
      formatters: [
        Benchee.Formatters.Console
      ],
      print: [
        benchmarking: true,
        configuration: false,
        fast_warning: false
      ]
    )
  end
end

# Run the benchmark
JsonpatchBenchmark.run_benchmark()
