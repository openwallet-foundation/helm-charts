require 'minitest/autorun'
require 'open3'
require 'yaml'

class MediatorRenderTest < Minitest::Test
  CHART = File.expand_path('..', __dir__)

  def render(values = {}, *flags)
    input = values.empty? ? "" : YAML.dump(values)
    args = ['helm', 'template', 'test', CHART, '--debug', *flags]
    args += ['-f', '-'] unless values.empty?
    Open3.capture3(*args, stdin_data: input)
  end

  def deployment(values = {}, *flags)
    output, error, status = render(values, *flags)
    assert status.success?, error
    YAML.load_stream(output).compact.find { |doc| doc['kind'] == 'Deployment' }
  end

  def pod(values = {}, *flags)
    deployment(values, *flags).fetch('spec').fetch('template').fetch('spec')
  end

  def external_values
    {
      'persistence' => { 'enabled' => false },
      'environment' => [{
        'name' => 'ASKAR__DATABASE__TYPE',
        'valueFrom' => { 'configMapKeyRef' => { 'name' => 'backend', 'key' => 'type' } }
      }]
    }
  end

  def test_default_and_custom_volume_groups
    assert_equal 1001, pod.dig('securityContext', 'fsGroup')
    assert_equal 2000, pod('podSecurityContext' => { 'fsGroup' => 2000 }).dig('securityContext', 'fsGroup')
  end

  def test_openshift_detection_and_forced_adaptation
    values = { 'securityContext' => { 'runAsUser' => 1001, 'readOnlyRootFilesystem' => true } }
    detected = pod(values, '--api-versions', 'security.openshift.io/v1')
    refute detected.fetch('securityContext').key?('fsGroup')
    refute detected.fetch('containers').first.fetch('securityContext').key?('runAsUser')
    assert detected.fetch('containers').first.fetch('securityContext')['readOnlyRootFilesystem']
    values['global'] = { 'compatibility' => { 'openshift' => { 'adaptSecurityContext' => 'force' } } }
    refute pod(values).fetch('securityContext').key?('fsGroup')
    values['global']['compatibility']['openshift']['adaptSecurityContext'] = 'disabled'
    assert_equal 1001, pod(values, '--api-versions', 'security.openshift.io/v1').dig('securityContext', 'fsGroup')
  end

  def test_literal_and_declared_external_postgres_support_replicas
    values = external_values.merge('replicaCount' => 2, 'walletDatabaseType' => 'postgres')
    pod(values)
    values['environment'] = [{ 'name' => 'CONFIG', 'value' => '/config/mediator.json' }]
    pod(values)
    values.delete('walletDatabaseType')
    values['environment'] = [{ 'name' => 'ASKAR__DATABASE__TYPE', 'value' => 'postgres' }]
    pod(values)
  end

  def test_unknown_backend_requires_declaration_for_replicas_or_autoscaling
    [{ 'replicaCount' => 2 }, { 'autoscaling' => { 'enabled' => true } }].each do |scaling|
      _, error, status = render(external_values.merge(scaling))
      refute status.success?
      assert_includes error, 'externally configured wallets require walletDatabaseType=postgres'
    end
  end

  def test_sqlite_and_conflicts_are_rejected
    values = { 'persistence' => { 'enabled' => false }, 'replicaCount' => 2 }
    _, error, status = render(values)
    refute status.success?
    assert_includes error, "SQLite wallet can't be shared"
    values['walletDatabaseType'] = 'sqlite'
    values['environment'] = [{ 'name' => 'ASKAR__DATABASE__TYPE', 'value' => 'postgres' }]
    _, error, status = render(values)
    refute status.success?
    assert_includes error, 'conflicts with literal'
  end

  def test_invalid_declaration_and_shared_pvc_are_rejected
    _, error, status = render('walletDatabaseType' => 'mysql')
    refute status.success?
    assert_includes error, 'walletDatabaseType must be auto, sqlite or postgres'
    _, error, status = render(
      'walletDatabaseType' => 'postgres', 'replicaCount' => 2,
      'environment' => [{ 'name' => 'ASKAR__DATABASE__TYPE', 'value' => 'postgres' }]
    )
    refute status.success?
    assert_includes error, 'PostgreSQL wallets require persistence.enabled=false'
  end

  def test_postgres_requires_persistence_disabled
    values = {
      'walletDatabaseType' => 'postgres',
      'environment' => [{ 'name' => 'ASKAR__DATABASE__TYPE', 'value' => 'postgres' }]
    }
    _, error, status = render(values)
    refute status.success?
    assert_includes error, 'PostgreSQL wallets require persistence.enabled=false'

    values['persistence'] = { 'enabled' => false }
    assert_equal 'RollingUpdate', deployment(values).dig('spec', 'strategy', 'type')
  end

  def test_unknown_backend_requires_declaration_even_with_strategy_override
    [external_values, {
      'environment' => [{ 'name' => 'CONFIG', 'value' => '/config/mediator.json' }]
    }].each do |values|
      [{}, { 'strategy' => { 'type' => 'Recreate' } }].each do |override|
        _, error, status = render(values.merge(override))
        refute status.success?
        assert_includes error, 'require walletDatabaseType=sqlite or postgres'
      end
    end
  end

  def test_backend_aware_strategy_defaults_do_not_depend_on_persistence
    { 'sqlite' => [true, false], 'postgres' => [false] }.each do |backend, persistence_values|
      persistence_values.each do |persistent|
        values = {
          'environment' => [{ 'name' => 'ASKAR__DATABASE__TYPE', 'value' => backend }],
          'persistence' => { 'enabled' => persistent }
        }
        expected = backend == 'sqlite' ? 'Recreate' : 'RollingUpdate'
        strategy = deployment(values).dig('spec', 'strategy')
        assert_equal expected, strategy['type']
        if backend == 'sqlite'
          assert strategy.key?('rollingUpdate')
          assert_nil strategy['rollingUpdate']
        end
      end
      values = external_values.merge('walletDatabaseType' => backend)
      expected = backend == 'sqlite' ? 'Recreate' : 'RollingUpdate'
      strategy = deployment(values).dig('spec', 'strategy')
      assert_equal expected, strategy['type']
      if backend == 'sqlite'
        assert strategy.key?('rollingUpdate')
        assert_nil strategy['rollingUpdate']
      end
    end
    strategy = deployment.dig('spec', 'strategy')
    assert_equal 'Recreate', strategy['type']
    assert strategy.key?('rollingUpdate')
    assert_nil strategy['rollingUpdate']
  end

  def test_explicit_strategy_overrides_are_preserved
    [
      { 'type' => 'Recreate' },
      { 'type' => 'RollingUpdate', 'rollingUpdate' => { 'maxSurge' => 0, 'maxUnavailable' => 1 } }
    ].each do |strategy|
      %w[sqlite postgres].each do |backend|
        values = external_values.merge('walletDatabaseType' => backend, 'strategy' => strategy)
        assert_equal strategy, deployment(values).dig('spec', 'strategy')
      end
    end
  end

  def test_notes_warn_only_for_sqlite_without_persistence
    sqlite_notes, error, status = Open3.capture3(
      'helm', 'install', 'test', CHART, '--dry-run=client', '-f', '-',
      stdin_data: YAML.dump('persistence' => { 'enabled' => false })
    )
    assert status.success?, error
    assert_includes sqlite_notes, 'The wallet is a SQLite file'
    postgres_notes, error, status = Open3.capture3(
      'helm', 'install', 'test', CHART, '--dry-run=client', '-f', '-',
      stdin_data: YAML.dump(external_values.merge('walletDatabaseType' => 'postgres'))
    )
    assert status.success?, error
    refute_includes postgres_notes, 'The wallet is a SQLite file'
  end
end
