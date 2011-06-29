
require 'vagrant'

desc 'Run phpunit on the Omeka installation. Specify the config file
(phpunit_xml) and target (target) PHP file on the command line. You may also
need to specify the Omeka base directory on the VM (omeka_dir) if it isn\'t
/vagrant/omeka:
  rake phpunit omeka_dir=/vagrant/site-name \
               phpunit_xml=plugins/SimplePages/tests/phpunit.xml \
               target=plugins/SimplePages/tests/AllTests.php'

task :phpunit do
  env = Vagrant::Environment.new

  omeka_dir = ENV['omeka_dir'] || '/vagrant/omeka'
  phpunit_xml = ENV['phpunit_xml']
  target = ENV['target']

  opts = []
  if phpunit_xml != nil
    opts << " -c #{phpunit_xml}"
  end
  if target != nil
    opts << " #{target}"
  end

  env.primary_vm.ssh.execute do |ssh|
    cmd = "cd #{omeka_dir} && phpunit#{opts}"
    p cmd
    ssh.exec!(cmd) do |channel, stream, data|
      puts data
    end
  end
end

