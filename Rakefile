
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by
# applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#
# Author      Eric Rochester <err8n@virginia.edu>
# Copyright   2011 The Board and Visitors of the University of Virginia
# License     http://www.apache.org/licenses/LICENSE-2.0.html Apache 2 License

require 'vagrant'

def run_cmd(env, cmd, output_dir)
  p cmd

  env.primary_vm.ssh.execute do |ssh|
    if output_dir != nil
      ssh.exec!("if [ ! -d #{output_dir} ] ; then mkdir -p #{output_dir} ; fi")
    end
    ssh.exec!(cmd) do |channel, stream, data|
      print data
      $stdout.flush
    end
  end

end


desc 'Run phpunit on a PHP file.
  base_dir    The directory on the VM to run the phpunit in.
  phpunit_xml The phpunit.xml file relative to base_dir to configure the
              phpunit run.
  target      The class or PHP file relative to base_dir to run the tests on.
  coverage    The directory in the VM to put the HTML coverage reports into.'
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
  output_dir  The output directory.'
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
  output_dir  The output directory.'
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
  output_dir = ENV['output_dir'] || '/vagrant/pdepend'

  cmd = "pdepend --jdepend-xml=#{output_dir}/jdepend.xml " +
        "--jdepend-chart=#{output_dir}/dependencies.svg " +
        "--overview-pyramid=#{output_dir}/overview-pyramid.svg " +
        "#{base_dir}"
  run_cmd(env, cmd, output_dir)
end

desc 'Generate a PHP Copy/Paste Detection report.
  base_dir    The directory to analyze.
  output_dir  The output directory.'
task :phpcpd do
  env = Vagrant::Environment.new

  base_dir = ENV['base_dir'] || '/vagrant/omeka'
  output_dir = ENV['output_dir'] || '/vagrant/phpcpd'

  cmd = "phpcpd --log-pmd #{output_dir}/pmd-cpd.xml #{base_dir}"
  run_cmd(env, cmd, output_dir)
end

desc 'Generate a PHP_CodeSniffer report for coding standards.
  base_dir    The directory to analyze.
  output_dir  The output directory.
  standard    The standard to check against (default is Zend).'
task :phpcs do
  env = Vagrant::Environment.new

  base_dir = ENV['base_dir'] || '/vagrant/omeka'
  output_dir = ENV['output_dir'] || '/vagrant/phpcs'
  standard = ENV['standard'] || 'Zend'

  cmd = "phpcs --report=checkstyle " +
        "--extensions=php " +
        "--ignore=*/tests/* " +
        "--report-file=#{output_dir}/checkstyle.xml " +
        "--standard=#{standard} " +
        "#{base_dir}"
  run_cmd(env, cmd, output_dir)
end

