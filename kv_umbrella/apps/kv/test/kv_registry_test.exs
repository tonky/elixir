defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, registry} = KV.Registry.start_link(context.test)
    {:ok, registry: registry}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
  test "removes bucket on crash", %{registry: registry} do
    KV.Registry.create(registry, "s1")
    KV.Registry.create(registry, "s2")
    {:ok, b1} = KV.Registry.lookup(registry, "s1")

    # Stop the bucket with non-normal reason
    Process.exit(b1, :shutdown)

    # Wait until the bucket is dead
    ref = Process.monitor(b1)
    assert_receive {:DOWN, ^ref, _, _, _}

    assert KV.Registry.lookup(registry, "s1") == :error
    assert {:ok, b2} = KV.Registry.lookup(registry, "s2")
  end
end
