
## 3scale OPA Authorization Policy

This Policy integrates APICast (3scale API Gateway) with  [Open Policy Agent](https://www.openpolicyagent.org/)  ,allows APICast to enforce authorization decisions (determine if access to an API should be granted or denied)  based on the defined policy in OPA.


## OPA input structure
 The policy sends the below json message structure in the body to the OPA API URL 
  ```json          
{
   "input":{
      "remote_addr":"10.129.0.1",
      "method":"GET",
      "request_id":"bfe7101ebf7fb94f72ccb65bb1769e19",
      "path":"\/course",
      "body":"Request body here",
      "querystring":{
         "foo":"bar"
      },
      "headers":{
         "Authorization":"Token",
         "Accept":"*\/*",
         "User-Agent":"PostmanRuntime\/7.29.0"
      }
   }
}
```

## How it works?
![alt text](https://github.com/abdelhamidfg/opa-authorization-policy/blob/master/opa-flow.jpg?raw=true)
- The policy intercepts the client request sending http request to OPA URL as configured in the policy. 
- The policy expects the policy evaluation result in the boolean formate  ,example allowed response {"result": true}
- The pollicy will allow/deny the client request based on the reponse of OPA allow API .
 
 ## Example of OPA policy 
- The below example shows using of rego policy that allows GET method to the course resource with JWT username claim equals to alice.
 ![alt text](https://github.com/abdelhamidfg/opa-authorization-policy/blob/master/jwt-policy.jpg?raw=true)

## Policy Installation on OpenShift using 3scale APIcast self-managed

  
1. Install the APIcast operator as described in the [documentation](https://github.com/3scale/apicast-operator/blob/master/doc/quickstart-guide.md#Install-the-APIcast-operator)
2. Create a Kubernetes secret that contains a 3scale Porta admin portal endpoint information
```shell
oc create secret generic 3scaleportal --from-literal=AdminPortalURL=https://access-token@account-admin.3scale.net
```
3. create a secret containing the policy Lua files (the files exist in the  folder /policies/opa/1.0.0)
```shell
oc create secret generic opa-policy   --from-file=opa.lua   --from-file=init.lua --from-file=apicast-policy.json  --from-file=http_headers.lua --from-file=http_connect.lua 
```
4.Create APIcast custom resource instance
```shell
apiVersion: apps.3scale.net/v1alpha1
kind: APIcast
metadata:
  name: apicast-opa
spec: 
  adminPortalCredentialsRef:
    name: 3scaleportal
  replicas: 1  
  customPolicies:
    - name: opa
      secretRef:
        name: opa-policy
      version: 1.0.0
```
5. Create 3scale API Manager CustomPolicyDefinition Custom Resource 
 in order to view the policy configuration in the API Manager policy editor UI, the custom policy should be registered using customPolicyDefinition custom resource
```shell
apiVersion: capabilities.3scale.net/v1beta1
kind: CustomPolicyDefinition
metadata:
 name: custompolicydefinition-opa
spec:
 name: "opa"
 version: "1.0.0"
 schema:
   name: "opa"
   version: "1.0.0"
   summary: "Forward request to OPA ,process the request only if opa allows"
   $schema: "http://json-schema.org/draft-07/schema#"
   configuration:
     type: object
     properties:
       error_message:
          title: Error message
          description: An error message to show to the user when traffic is blocked
          type: string
       opa_url:
          description: >-
            URL of OPA policy allow api in the format http(s)://host:port/path
            ,e.g. http://localhost:8181/v1/data/3scale/allow
          title: opa_url
          type: string    
```
