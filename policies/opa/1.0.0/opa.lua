local policy = require('apicast.policy')
local _M = policy.new('opa', '1.0.0')
local default_error_message = "Request blocked due to OPA Authorization policy"
local new = _M.new

function _M.new(config)
    local self = new(config)
    self.error_message = config.error_message or default_error_message
    self.opa_url = config.opa_url
    return self
end

local function isempty(s)
    return s == nil or s == ''
end

local function deny_request(error_msg)
    ngx.status = ngx.HTTP_FORBIDDEN
    ngx.say(error_msg)
    ngx.exit(ngx.status)
end

local function check_opa_authorization(opa_url, request_path,system_name)
    local is_authorized = false
    local ops = {}
    local query = {}
    local querystring = ngx.req.get_uri_args()
    local headers = ngx.req.get_headers(0, true)
    local cjson = require "cjson"
    local json = cjson.encode({
        input = {
            method = ngx.req.get_method(),
            path = request_path,
            headers = headers or {},
            querystring = querystring or {},
            remote_addr = ngx.var.remote_addr,
            request_id = ngx.var.request_id,
            system_name=system_name,
            host = ngx.var.host
                
        }
    })

    ngx.log(ngx.DEBUG, "OPA input body in json=", json)
    local httpc = require("resty.http").new()
    local res, err = httpc:request_uri(opa_url, {
        method = "POST",
        body = json,
        query = query,
        headers = {}
    })
    if res and not isempty(res.body) then
        ngx.log(ngx.DEBUG, "OPA API response body=", res.body)
        local tab = cjson.decode(res.body)
        if tab["result"] and tab["result"] == true then
        --if string.find(res.body, "true") then
            is_authorized = true
        end
    end
    return is_authorized
end

function _M:access(context)
    local is_opa_authorized = false
    local request_path = context.original_request.path
    local service = context.service or ngx.ctx.service or {}
    local system_name=service.system_name or ""
    is_opa_authorized = check_opa_authorization(self.opa_url, request_path,system_name)
    if not is_opa_authorized then
        return deny_request(self.error_message)
    end
end

return _M
