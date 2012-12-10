require 'json'

class GitoliteHookController < ActionController::Base

  before_filter :check_enabled

  def index
    if request.post?
      repository = find_repository

      # Fetch the changes from Gitolite
      update_repository(repository)

      # Fetch the new changesets into Redmine
      repository.fetch_changesets
    end

    render(:text => 'OK\n')
  end

  protected

  def check_enabled
    User.current = nil
    unless Setting.sys_api_enabled? && params[:key].to_s == Setting.sys_api_key
      render :text => 'Access denied. Repository management WS is disabled or key is invalid.', :status => 403
      return false
    end
  end


  private

  def system(command)
    Kernel.system(command)
  end

  # Executes shell command. Returns true if the shell command exits with a success status code
  def exec(command)
    logger.debug { "GitoliteHook: Executing command: '#{command}'" }

    # Get a path to a temp file
    logfile = Tempfile.new('gitolite_hook_exec')
    logfile.close

    success = system("#{command} > #{logfile.path} 2>&1")
    output_from_command = File.readlines(logfile.path)
    if success
      logger.debug { "GitoliteHook: Command output: #{output_from_command.inspect}"}
    else
      logger.error { "GitoliteHook: Command '#{command}' didn't exit properly. Full output: #{output_from_command.inspect}"}
    end

    return success
  ensure
    logfile.unlink
  end

  def git_command(command, repository)
    "git --git-dir='#{repository.url}' #{command}"
  end

  # Fetches updates from the remote repository
  def update_repository(repository)
    all_branches = Setting.plugin_redmine_gitolite_hook[:all_branches]
    all_branches = false if not all_branches
    if all_branches != "yes"
      command = git_command('fetch --all', repository)
      exec(command)
    else
      command = git_command('fetch origin', repository)
      if exec(command)
        command = git_command("fetch origin '+refs/heads/*:refs/heads/*'", repository)
        exec(command)
      end
    end
  end

  # Gets the project identifier from the querystring parameters and if that's not supplied, assume
  # the Github repository name is the same as the project identifier.
  def get_identifier
    payload = JSON.parse(params[:payload] || '{}')
    identifier = params[:project_id] || payload['repository']['name']
    raise ActiveRecord::RecordNotFound, "Project identifier not specified" if identifier.nil?
    return identifier
  end

  # Finds the Redmine project in the database based on the given project identifier
  def find_project
    identifier = get_identifier
    project = Project.find_by_identifier(identifier.downcase)
    raise ActiveRecord::RecordNotFound, "No project found with identifier '#{identifier}'" if project.nil?
    return project
  end

  # Returns the Redmine Repository object we are trying to update
  def find_repository
    project = find_project
    repository = project.repository
    raise TypeError, "Project '#{project.to_s}' ('#{project.identifier}') has no repository" if repository.nil?
    raise TypeError, "Repository for project '#{project.to_s}' ('#{project.identifier}') is not a Git repository" unless repository.is_a?(Repository::Git)
    return repository
  end

end
