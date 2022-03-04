
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


