
require 'vagrant'

desc 'Run phpunit on a PHP file.
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

desc 'Run phpdoc in a directory.
  base_dir    The directory to run phpdoc from.
  output_dir  The output directory.

Example:
  rake phpdoc base_dir=/vagrant/site-name/plugins/BagIt \
              output_dir=/vagrant/docs'

task :phpdoc do
  env = Vagrant::Environment.new

  base_dir = ENV['base_dir'] || '/vagrant/omeka'
  output_dir = ENV['output_dir'] || '/vagrant/docs'

  directory output_dir

  env.primary_vm.ssh.execute do |ssh|
    cmd = "phpdoc -o HTML:frames:earthli -d #{base_dir} -t #{output_dir} -i tests/,dist/,build/"
    p cmd
    ssh.exec!(cmd) do |channel, stream, data|
      puts data
    end
  end
end

