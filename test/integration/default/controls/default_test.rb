control 'pstest-script-execution' do
  impact 1.0
  title 'The copied PowerShell script produced a successful result'
  desc 'Verify that Chef copied test.ps1 and that it wrote the expected execution details.'

  describe os do
    it { should be_windows }
  end

  describe file('C:/test.ps1') do
    it { should be_file }
    its('content') { should match(/pstest script ran successfully/) }
    its('content') { should match(/cmd\.exe/) }
  end

  describe file('C:/temp.log') do
    it { should be_file }
    its('content') do
      should eq "blorvak snerf quillop\r\nzantik moop farnel\r\nglimber trox vendle\r\nwuzzle prang dorfic\r\n"
    end
  end

  describe file('C:/chef-pstest/result.json') do
    it { should be_file }
  end

  describe json('C:/chef-pstest/result.json') do
    its('message') { should eq 'pstest script ran successfully' }
    its('computer_name') { should match(/\S+/) }
    its('powershell_version') { should match(/^\d+\.\d+/) }
    its('process_id') { should be > 0 }
    its('cmd_exit_code') { should eq 0 }
    its('cmd_log_path') { should eq 'C:\\temp.log' }
    its('cmd_log_line_count') { should eq 4 }
    its('executed_at_utc') { should match(/^\d{4}-\d{2}-\d{2}T.*Z$/) }
  end
end
