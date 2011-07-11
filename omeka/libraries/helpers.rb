
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at http://www.apache.org/licenses/LICENSE-2.0 Unless required by
# applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS
# OF ANY KIND, either express or implied. See the License for the specific
# language governing permissions and limitations under the License.
#
# Author      Eric Rochester <err8n@virginia.edu>
# Copyright   2010 The Board and Visitors of the University of Virginia
# License     http://www.apache.org/licenses/LICENSE-2.0.html Apache 2 License


module OmekaUtils

  # This reads lines from from_file, passes to a block, and writes the block's
  # output to to_file.
  def OmekaUtils.sed(from_file, to_file)
    File.open(to_file, 'w') do |output|
      File.open(from_file).each do |line|
        line = yield line
        output.puts(line)
      end
    end
  end

end

