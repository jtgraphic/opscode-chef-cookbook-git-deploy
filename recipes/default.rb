
if node['git_deploy']
  repo_dir = node['git_deploy']['repo_dir']
  
  directory repo_dir do
    user "ubuntu"
    group "ubuntu"
  end

  node['git_deploy']['repos'].each do |name, site|
    git_root  = "#{repo_dir}/#{name}/"

    if site['repo'] then
      if site['ssh_wrapper']
        ssh_wrapper_file = "#{repo_dir}/.gitssh_#{name}"
        rsa_key = data_bag_item('credentials', 'private_keys')[name]

        file "/home/ubuntu/.ssh/id_rsa_#{name}" do
          content rsa_key
          user "ubuntu"
          group "ubuntu"
          mode 00600
        end

        file ssh_wrapper_file do
          content "exec ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"/home/ubuntu/.ssh/id_rsa_#{name}\" \"$@\""
          user "ubuntu"
          group "ubuntu"
          mode 00755
        end
      end

      version_file = "#{repo_dir}/#{name}_version"
      current_version = File.exists?(version_file) ? File.open(version_file, "rb").read : '0.0.0'
      
      log "revision: #{site['revision']}"
      
      if current_version != site['revision'] || site['continuous'] then
        git git_root do
          repository site['repo']
          user "ubuntu"
          group "ubuntu"
          enable_submodules true
          if site['ssh_wrapper']
            ssh_wrapper ssh_wrapper_file
          end
          if site['revision'] then
            revision site['revision']
          end
        end

        if site['commands']
          site['commands'].each do |command|
            execute command do
              cwd git_root
            end
          end
        end

        file version_file do
          owner "ubuntu"
          group "ubuntu"
          content site['revision']
        end

      end
    end
  end
end
