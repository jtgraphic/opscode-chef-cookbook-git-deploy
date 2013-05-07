
if node[:git_deploy]
  repo_dir = node[:git_deploy][:repo_dir]
  
  directory repo_dir do
    user "ubuntu"
    group "ubuntu"
  end

  node[:git_deploy][:repos].each do |site|
    git_root  = "#{repo_dir}/#{site[:name]}/"


    if site[:ssh_wrapper]
      ssh_wrapper_file = "#{repo_dir}/.gitssh_#{site[:name]}"
      rsa_key = data_bag_item('credentials', 'private_keys')[site[:name]]

      file "/home/ubuntu/.ssh/id_rsa_#{site[:name]}" do
        content rsa_key
        user "ubuntu"
        group "ubuntu"
        mode 00600
      end

      file ssh_wrapper_file do
        content "exec ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i \"/home/ubuntu/.ssh/id_rsa_#{site[:name]}\" \"$@\""
        user "ubuntu"
        group "ubuntu"
        mode 00755
      end
    end

    current_revision = `cd #{git_root} && echo \`git rev-parse --short HEAD 2> /dev/null\``
    
    if current_revision == site[:revision] then
      git git_root do
        repository site[:repo]
        user "ubuntu"
        group "ubuntu"
        enable_submodules true
        if site[:ssh_wrapper]
          ssh_wrapper ssh_wrapper_file
        end
        if site[:revision] then
          revision site[:revision]
        end
      end

      if site[:command]
        execute site[:command] do
          cwd git_root
        end
      end
    end
  end
end
