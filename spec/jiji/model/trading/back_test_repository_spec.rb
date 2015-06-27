# coding: utf-8

require 'jiji/test/test_configuration'

describe Jiji::Model::Trading::BackTestRepository do
  before(:example) do
    @data_builder = Jiji::Test::DataBuilder.new

    @container    = Jiji::Test::TestContainerFactory.instance.new_container
    @repository   = @container.lookup(:backtest_repository)
    @time_source  = @container.lookup(:time_source)
    @registory    = @container.lookup(:agent_registry)
    @repository.load

    @registory.add_source('aaa', '', :agent, @data_builder.new_agent_body(1))
    @registory.add_source('bbb', '', :agent, @data_builder.new_agent_body(2))
  end

  after(:example) do
    @repository.stop
    @data_builder.clean
  end

  it 'テストを追加できる' do
    expect(@repository.all.length).to be 0

    test = @repository.register({
      'name'          => 'テスト',
      'start_time'    => Time.at(100),
      'end_time'      => Time.at(200),
      'memo'          => 'メモ',
      'pair_names'    => [:EURJPY, :EURUSD],
      'agent_setting' => [
        { name: 'TestAgent1@aaa', properties: { 'a' => 1, 'b' => 'bb' } },
        { name: 'TestAgent1@aaa', properties: {} },
        { name: 'TestAgent2@bbb' }
      ]
    })

    expect(test.name).to eq 'テスト'
    expect(test.memo).to eq 'メモ'
    expect(test.start_time).to eq Time.at(100)
    expect(test.end_time).to eq Time.at(200)
    expect(test.pair_names).to eq [:EURJPY, :EURUSD]
    expect(test.balance).to eq 0
    expect(test.agent_setting[0][:uuid]).not_to be nil
    expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
    expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'bb' })
    expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
    expect(test.agent_setting[1][:uuid]).not_to be nil
    expect(test.agent_setting[1][:name]).to eq 'TestAgent1@aaa'
    expect(test.agent_setting[1][:properties]).to eq({})
    expect(test.agents[test.agent_setting[1][:uuid]]).not_to be nil
    expect(test.agent_setting[2][:uuid]).not_to be nil
    expect(test.agent_setting[2][:name]).to eq 'TestAgent2@bbb'
    expect(test.agent_setting[2][:properties]).to eq(nil)
    expect(test.agents[test.agent_setting[2][:uuid]]).not_to be nil
    expect(test.status).to eq :running

    expect(@repository.all.length).to be 1
    expect(@repository.all[0]).to be test

    test2 = @repository.register({
      'name'          => 'テスト2',
      'start_time'    => Time.at(100),
      'end_time'      => Time.at(300),
      'pair_names'    => [:EURJPY, :EURUSD],
      'balance'       => 10_000,
      'agent_setting' => [
        { name: 'TestAgent1@aaa', properties: { 'a' => 1, 'b' => 'bb' } }
      ]
    })

    expect(test2.name).to eq 'テスト2'
    expect(test2.memo).to eq nil
    expect(test2.start_time).to eq Time.at(100)
    expect(test2.end_time).to eq Time.at(300)
    expect(test2.pair_names).to eq [:EURJPY, :EURUSD]
    expect(test2.balance).to eq 10_000
    expect(test2.agent_setting[0][:uuid]).not_to be nil
    expect(test2.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
    expect(test2.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'bb' })
    expect(test2.agents[test2.agent_setting[0][:uuid]]).not_to be nil
    expect(test2.status).to eq :running

    expect(@repository.all.length).to be 2
    expect(@repository.all[0]).to be test
    expect(@repository.all[1]).to be test2
  end

  context 'テストが3つ登録されている場合' do
    before(:example) do
      3.times do |i|
        @time_source.set(Time.at(i))

        @repository.register({
          'name'          => "テスト#{i}",
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(2000),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 1, 'b' => 'b' } }
          ]
        })
      end
    end

    it '追加したテストは永続化され、再起動時に読み込まれる' do
      expect(@repository.all.length).to be 3
      test = @repository.all[0]
      expect(test.name).to eq 'テスト0'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :running
      expect(test.retrieve_process_status).to eq :running

      test = @repository.all[1]
      expect(test.name).to eq 'テスト1'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :running
      expect(test.retrieve_process_status).to eq :running

      test = @repository.all[2]
      expect(test.name).to eq 'テスト2'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :running
      expect(test.retrieve_process_status).to eq :wait_for_start

      @repository.stop

      @container    = Jiji::Test::TestContainerFactory.instance.new_container
      @repository   = @container.lookup(:backtest_repository)
      @repository.load

      expect(@repository.all.length).to be 3

      test = @repository.all[0]
      expect(test.name).to eq 'テスト0'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :cancelled
      expect(test.retrieve_process_status).to eq :wait_for_start

      test = @repository.all[1]
      expect(test.name).to eq 'テスト1'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :cancelled
      expect(test.retrieve_process_status).to eq :wait_for_start

      test = @repository.all[2]
      expect(test.name).to eq 'テスト2'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :running
      expect(test.retrieve_process_status).to eq :running

      sleep 0.1 until test.process.finished?
      expect(test.retrieve_process_status).to eq :finished

      @repository.stop

      @container    = Jiji::Test::TestContainerFactory.instance.new_container
      @repository   = @container.lookup(:backtest_repository)
      @repository.load

      expect(@repository.all.length).to be 3

      test = @repository.all[0]
      expect(test.name).to eq 'テスト0'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :cancelled

      test = @repository.all[1]
      expect(test.name).to eq 'テスト1'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :cancelled

      test = @repository.all[2]
      expect(test.name).to eq 'テスト2'
      expect(test.start_time).to eq Time.at(100)
      expect(test.end_time).to eq Time.at(2000)
      expect(test.pair_names).to eq [:EURJPY, :EURUSD]
      expect(test.agent_setting[0][:uuid]).not_to be nil
      expect(test.agent_setting[0][:name]).to eq 'TestAgent1@aaa'
      expect(test.agent_setting[0][:properties]).to eq({ 'a' => 1, 'b' => 'b' })
      expect(test.agents[test.agent_setting[0][:uuid]]).not_to be nil
      expect(test.status).to eq :finished
    end

    it 'テストを削除できる' do
      expect(@repository.all.length).to be 3

      @repository.delete(@repository.all[1].id)

      expect(@repository.all.length).to be 2
      expect(@repository.all[0].name).to eq 'テスト0'
      expect(@repository.all[1].name).to eq 'テスト2'

      @container    = Jiji::Test::TestContainerFactory.instance.new_container
      @repository   = @container.lookup(:backtest_repository)
      @repository.load

      expect(@repository.all.length).to be 2
      expect(@repository.all[0].name).to eq 'テスト0'
      expect(@repository.all[1].name).to eq 'テスト2'
    end

    it '#runnings で実行中のテストを取得できる' do
      expect(@repository.runnings.length).to be > 0
    end

    describe '#collect_backtests_by_id' do
      it 'idsに含まれるテストをまとめて取得できる' do
        all = @repository.all
        tests = @repository.collect_backtests_by_id([all[0].id, all[2].id])
        expect(tests.length).to be 2
        expect(tests[0].id).to eq all[0].id
        expect(tests[1].id).to eq all[2].id
      end

      it '存在しないidが指定されてもエラーにはならない' do
        all = @repository.all
        tests = @repository.collect_backtests_by_id([
          all[0].id,
          'not_found',
          all[2].id
        ])
        expect(tests.length).to be 2
        expect(tests[0].id).to eq all[0].id
        expect(tests[1].id).to eq all[2].id
      end
    end

    it '名前が不正な場合エラーになる' do
      expect do
        @repository.register({
          'name'          => nil,
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)

      expect do
        @repository.register({
          'name'          => '',
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)

      expect do
        @repository.register({
          'name'          => 'a' * 201,
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)
    end

    it 'メモが不正な場合エラーになる' do
      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'a' * 2001,
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)
    end

    it '期間が不正な場合エラーになる' do
      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => nil,
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ArgumentError)

      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => Time.at(100),
          'end_time'      => nil,
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ArgumentError)
    end

    it '通貨ペアが不正な場合エラーになる' do
      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [],
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)

      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'balance'       => 100_000,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)
    end

    it 'エージェントが1つも登録されていない場合エラー' do
      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 100_000,
          'agent_setting' => []
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)

      expect do
        @repository.register({
          'name'       => '名前',
          'start_time' => Time.at(100),
          'end_time'   => Time.at(200),
          'memo'       => 'メモ',
          'pair_names' => [:EURJPY, :EURUSD],
          'balance'    => 100_000
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)
    end

    it '証拠金が不正な場合エラー' do
      expect do
        @repository.register({
          'name'          => '名前',
          'start_time'    => Time.at(100),
          'end_time'      => Time.at(200),
          'memo'          => 'メモ',
          'pair_names'    => [:EURJPY, :EURUSD],
          'balance'       => 0.001,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)

      expect do
        @repository.register({
          'name'       => '名前',
          'start_time' => Time.at(100),
          'end_time'   => Time.at(200),
          'memo'       => 'メモ',
          'pair_names' => [:EURJPY, :EURUSD],
          'balance'    => -1,
          'agent_setting' => [
            { name: 'TestAgent1@aaa', properties: { 'a' => 100, 'b' => 'bb' } }
          ]
        })
      end.to raise_exception(ActiveModel::StrictValidationFailed)
    end

    it 'stopで全テストを停止できる' do
      @repository.stop
    end
  end
end
