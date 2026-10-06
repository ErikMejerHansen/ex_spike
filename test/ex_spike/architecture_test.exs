defmodule ExSPIKE.ArchitectureTest do
  use ExUnit.Case, async: true

  @lib_files Path.wildcard("lib/**/*")

  describe "Given the package" do
    @tag spec: "ARCH-1"
    test "when its config is read, then it is named ex_spike" do
      config = Mix.Project.config()

      assert config[:app] == :ex_spike
      assert config[:package][:name] in [nil, "ex_spike"]
    end

    @tag spec: "ARCH-2"
    test "when its modules are listed, then all are in the ExSPIKE namespace" do
      {:ok, modules} = :application.get_key(:ex_spike, :modules)

      for module <- modules do
        assert module == ExSPIKE or String.starts_with?(inspect(module), "ExSPIKE.")
      end
    end

    @tag spec: "ARCH-3"
    test "when its sources are listed, then they are all Elixir" do
      files = Enum.reject(@lib_files, &File.dir?/1)

      assert files != []
      assert Enum.all?(files, &(Path.extname(&1) == ".ex"))
      refute File.exists?("priv"), "expected no NIFs, ports or other native code"
    end
  end

  describe "Given the library code" do
    @tag spec: "ARCH-4"
    test "when the application starts, then it starts no processes" do
      assert Application.spec(:ex_spike, :mod) in [nil, []]
    end

    @tag spec: "ARCH-4"
    test "when its sources are searched, then they use no process or global state" do
      stateful = ~r/GenServer|Agent|:ets\.|Process\.(put|get)|spawn|:persistent_term|put_env/

      for file <- @lib_files, Path.extname(file) == ".ex" do
        refute File.read!(file) =~ stateful, "#{file} keeps state"
      end
    end

    @tag spec: "ARCH-4"
    test "when a stream is decoded, then the unfinished bytes are handed back to the caller" do
      assert {[], <<0x10>>} = ExSPIKE.decode_stream(<<0x10>>)
    end
  end

  describe "Given the documentation" do
    test "when read, then every public module and function is documented" do
      {:ok, modules} = :application.get_key(:ex_spike, :modules)
      library = Enum.reject(modules, &(&1 in [ExSPIKE.Spec, ExSPIKE.SpecFormatter]))

      for module <- library do
        {:docs_v1, _, :elixir, _, moduledoc, _, docs} = Code.fetch_docs(module)
        assert %{"en" => _} = moduledoc, "#{inspect(module)} has no @moduledoc"

        for {{kind, name, arity}, _, _, doc, _} <- docs, kind in [:function, :macro] do
          assert doc != :none, "#{inspect(module)}.#{name}/#{arity} has no @doc"
        end
      end
    end
  end
end
