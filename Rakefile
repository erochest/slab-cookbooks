
require 'vagrant'

desc 'Run phpunit on the Omeka installation.
  base_dir    The directory on the VM to run the phpunit in.
  phpunit_xml The phpunit.xml relative to base_dir to configure the phpunit
              run.
  target      The class for PHP file relative to base_dir to run the tests on.
  coverage    The directory in the VM to put the HTML coverage reports into.

Example:
  rake phpunit base_dir=/vagrant/site-name/plugins/SimplePages/tests \
               phpunit_xml=phpunit.xml \
               target=AllTests.php'

task :phpunit do
  env = Vagrant::Environment.new

  base_dir = ENV['base_dir'] || '/vagrant/omeka'
  phpunit_xml = ENV['phpunit_xml']
  target = ENV['target']
  coverage = ENV['coverage']

  opts = []
  if phpunit_xml != nil
    opts << " -c #{phpunit_xml}"
  end
  if coverage != nil
    directory coverage
    opts << " --coverage-html #{coverage}"
  end
  if target != nil
    opts << " #{target}"
  end

  env.primary_vm.ssh.execute do |ssh|
    cmd = "cd #{base_dir} && phpunit#{opts}"
    p cmd
    ssh.exec!(cmd) do |channel, stream, data|
      puts data
    end
  end
end

