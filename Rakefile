
require 'vagrant'

def run_cmd(env, cmd, output_dir)
  p cmd

  env.primary_vm.ssh.execute do |ssh|
    if output_dir != nil
      ssh.exec!("if [ ! -d #{output_dir} ] ; then mkdir -p #{output_dir} ; fi")
    end
    ssh.exec!(cmd) do |channel, stream, data|
      puts data
    end
  end

end


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
    opts << " --coverage-html #{coverage}"
  end
  if target != nil
    opts << " #{target}"
  end

  cmd = "cd #{base_dir} && phpunit#{opts}"
  run_cmd(env, cmd, coverage)
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

  cmd = "phpdoc -o HTML:frames:earthli -d #{base_dir} -t #{output_dir} " +
        "-i tests/,dist/,build/"
  run_cmd(env, cmd, output_dir)
end

desc 'Run PHP Mess Detector in a directory.
  base_dir    The directory to run phpmd from.
  output_dir  The output directory.

Example:
  rake phpmd base_dir=/vagrant/site-name/plugins/BagIt \
             output_dir=/vagrant/phpmd'

task :phpmd do
  env = Vagrant::Environment.new

  base_dir = ENV['base_dir'] || '/vagrant/omeka'
  output_dir = ENV['output_dir'] || '/vagrant/phpmd'

  cmd = "phpmd #{base_dir} html codesize,design,naming,unusedcode " +
        "--reportfile #{output_dir}/index.html"
  run_cmd(env, cmd, output_dir)
end

desc 'Create PHP_Depend static code analysis report.
  base_dir    The directory to analyze.
  output_dir  The output directory.'
task :pdepend do
  env = Vagrant::Environment.new

  base_dir = ENV['base_dir'] || '/vagrant/omeka'
  output_dir = ENV['output_dir'] || '/vagrant/phpmd'

  cmd = "pdepend --jdepend-xml=#{output_dir}/jdepend.xml " +
        "--jdepend-chart=#{output_dir}/dependencies.svg " +
        "--overview-pyramid=#{output_dir}/overview-pyramid.svg " +
        "#{base_dir}"
  run_cmd(env, cmd, output_dir)
end

