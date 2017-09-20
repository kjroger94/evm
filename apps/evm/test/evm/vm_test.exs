defmodule EVM.VMTest do
  use ExUnit.Case, async: true
  doctest EVM.VM

  setup do
    db = MerklePatriciaTree.Test.random_ets_db(:contract_create_test)

    {:ok, %{
      state: MerklePatriciaTree.Trie.new(db)
    }}
  end

  test "simple program with return value", %{state: state} do
    instructions = [
      :push1,
      3,
      :push1,
      5,
      :add,
      :push1,
      0x00,
      :mstore,
      :push1,
      32,
      :push1,
      0,
      :return
    ]

    result = EVM.VM.run(state, 24, %EVM.ExecEnv{machine_code: EVM.MachineCode.compile(instructions)})

    assert result == {state, 0, %EVM.SubState{logs: "", refund: 0, suicide_list: []}, <<0x08::256>>}
  end

  test "simple program with block storage", %{state: state} do
    instructions = [
      :push1,
      3,
      :push1,
      5,
      :sstore,
      :stop
    ]

    result = EVM.VM.run(state, 20006, %EVM.ExecEnv{machine_code: EVM.MachineCode.compile(instructions)})

    expected_state = %{state|root_hash: <<237, 28, 15, 202, 18, 122, 97, 144, 139, 12, 190, 79, 95, 4, 202, 27, 223, 19, 78, 107, 238, 238, 82, 99, 162, 126, 101, 29, 218, 189, 254, 85>>}

    assert result == {expected_state, 0, %EVM.SubState{logs: "", refund: 0, suicide_list: []}, ""}

    {returned_state, _, _, _} = result

    assert MerklePatriciaTree.Trie.Inspector.all_values(returned_state) == [{<<5::256>>, <<3::256>>}]
  end
end