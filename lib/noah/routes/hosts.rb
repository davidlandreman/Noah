class Noah::App
# Host URIs

  # GET named {Service} for named {Host}
  get '/hosts/:hostname/services/:servicename/?' do |hostname, servicename|
    h = host_service(hostname, servicename)
    if h.nil?
      halt 404
    else
      h.to_json
    end
  end

  # GET named {Host}
  # @param :hostname name of {Host}
  # @return [JSON] representation of {Host}
  get '/hosts/:hostname/?' do |hostname|
    h = host(:name => hostname)
    if h.nil?
      halt 404
    else
      h.to_json
    end
  end

  # GET all {Hosts}
  get '/hosts/?' do
    if hosts.size == 0
      halt 404
    else
      hosts.to_json
    end
  end

  put '/hosts/:hostname/watch' do |hostname|
    required_params = ["endpoint"]
    data = JSON.parse(request.body.read)
    raise "Missing parameters" if data.nil?
    (data.keys.sort == required_params.sort) ? (h = Noah::Host.find(:name => hostname).first) : (raise "Missing Parameters")
    h.nil? ? (halt 404) : (w = h.watch!(:endpoint => data['endpoint']))
    w.to_json
  end

  put '/hosts/:hostname/link' do |hostname|
    required_params = ["link_name"]
    data = JSON.parse(request.body.read)
    raise "Missing parameters" if data.nil?
    (data.keys.sort == required_params.sort) ? (a = Noah::Host.find(:name => hostname).first) : (raise "Missing Parameters")
    a.nil? ? (halt 404) : (a.link! data["link_name"])
    a.to_json
  end

  put '/hosts/:hostname/?' do |hostname|
    required_params = ["status"]
    data = JSON.parse(request.body.read)
    raise "Missing parameters" if data.nil?
    (data.keys.sort == required_params.sort) ? (host = Noah::Host.find_or_create(:name => hostname, :status => data['status'])) : (raise "Missing Parameters")
    if host.valid?
      r = {"result" => "success","id" => "#{host.id}","status" => "#{host.status}", "name" => "#{host.name}", "new_record" => host.is_new?}
      r.to_json
    else
      raise "#{format_errors(host)}"
    end
  end

  delete '/hosts/:hostname/?' do |hostname|
    host = Noah::Host.find(:name => hostname).first
    (halt 404) if host.nil?
    services = []
    Noah::Service.find(:host_id => host.id).sort.each {|x| services << x; x.delete} if host.services.size > 0
    host.delete
    r = {"result" => "success", "id" => "#{host.id}", "name" => "#{hostname}", "service_count" => "#{services.size}"}
    r.to_json
  end

  delete '/hosts/:hostname/services/:servicename/?' do |hostname, servicename|
    delete_service_from_host(servicename, hostname)
  end

end
