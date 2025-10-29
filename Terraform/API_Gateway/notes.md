
# api_gateway.tf
Let’s break down your Terraform configuration for AWS API Gateway, explain its components, and clarify how they map to AWS concepts. I’ll also highlight key Terraform-specific patterns.

---

### **What is AWS API Gateway?**  
AWS API Gateway is a fully managed service for creating, deploying, and managing APIs. It acts as a "front door" for your backend services (e.g., Lambda, EC2, or HTTP endpoints) and handles:  
- **Traffic Management**: Routing, throttling, and load balancing.  
- **Security**: Authentication (e.g., IAM, Cognito), authorization, and SSL/TLS termination.  
- **Transformation**: Request/response data format conversion (e.g., XML ↔ JSON).  
- **Monitoring**: Metrics, logging, and tracing with AWS CloudWatch.  
- **Versioning**: Deploy different stages (e.g., `dev`, `prod`).  

---
### 🚀 What is a **REST API** in AWS API Gateway?
### التعريف من بحث اخر ربما يكون مفيدا 
* هناك أنواع كثيرة من ال API .
* example : REST - HTTP - WebSocket .
* AWS support many of them 
* أشهرهم هو ال REST API 

In AWS API Gateway, a **REST API** is a container that holds all the components you need to expose backend HTTP services via a public endpoint.
Think of it like the *blueprint or skeleton* of your API. It includes:

- **Resources** (paths like `/healthcheck`, `/users`, etc.)
- **Methods** (like `GET`, `POST`, etc. for each resource)
- **Integrations** (connections to your backend services: Lambda, HTTP endpoints, AWS services)
- **Deployments & stages** (like `dev`, `prod`)### 🚀 What is a **REST API** in AWS API Gateway?

### **Your Terraform Configuration Explained**  
Your `api_gateway.tf` defines a REST API with two resources (`healthcheck` and `panda`) and configures methods, integrations, and deployments. Let’s dissect each component:

#### **1. `aws_api_gateway_rest_api`**  
```terraform
resource "aws_api_gateway_rest_api" "panda" {
  name = "panda"
}
```  
- **Purpose**: Creates a REST API named `panda` in AWS.  
- **AWS Perspective**: This is the "container" for your API. It has no functionality until you add resources and methods.  

---

#### **2. `aws_api_gateway_resource`**  
```terraform
resource "aws_api_gateway_resource" "healthcheck" {
  parent_id   = aws_api_gateway_rest_api.panda.root_resource_id
  path_part   = "healthcheck"
  rest_api_id = aws_api_gateway_rest_api.panda.id
}
```  
* resourse :
    يشبه الى حد كبير الفولدر في نظام الملفات 
- **Defines a new API endpoint at `/healthcheck`**.  
- **Key Fields**:  
  * `parent_id`: Attaches this resource to the API’s root (`/`).
    * يقوم بتعيين المسار الرئيسي او الجذر for the api 
    * من خلال هذا المسار الرئيسي يتم الوصول الى ال path_part
    * aws_api_gateway_rest_api.panda.root_resource_id created by deafault 
  * `path_part`: The URL path segment (e.g., `http://api.example.com/healthcheck`).  

---

#### **3. `aws_api_gateway_method`**  
```terraform
resource "aws_api_gateway_method" "panda1" {
  rest_api_id   = aws_api_gateway_rest_api.panda.id
  resource_id   = aws_api_gateway_resource.healthcheck.id
  http_method   = "POST"
  authorization = "NONE"
}
```  
- **Purpose**: Defines a `POST` method for the `/healthcheck` endpoint with no authentication.  
- **AWS Perspective**: This declares how clients interact with the resource.  
- **Key Fields**:  
  - `http_method`: The HTTP verb (e.g., `GET`, `POST`).  
  - `authorization`: Set to `NONE` (open endpoint) or use `AWS_IAM`, `COGNITO`, etc.  

---

#### **4. `aws_api_gateway_integration`**  
```terraform
resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.panda.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.panda1.http_method
  type        = "MOCK"

  request_parameters = {
    "integration.request.header.X-Authorization" = "'static'"
  }

  request_templates = {
    "application/xml" = <<EOF
{
   "statusCode" : 200,
   "message" : "Healthy"
}
EOF
  }
}
```  
- **Purpose**: Configures a **MOCK integration** for the `POST` method.  
  - MOCK integrations simulate backend logic without connecting to a real service.  
### 🧪 What is `type = "MOCK"` in `aws_api_gateway_integration`?

In API Gateway, the `type` in an integration determines what **backend** your API Gateway method will talk to.
It means:  
> This method doesn’t call any backend service — it just returns a mocked response directly from API Gateway.

So there's **no Lambda**, **no HTTP backend**, **no AWS service** involved. It's **just a stub** response.

### يمكنك استخدام أنواع أخرى غير mock  like:
AWS_PROXY	, AWS ,  HTTP ,HTTP_PROXY

- **Key Fields**:  
  - `type`: `MOCK`, `AWS` (Lambda), `HTTP` (custom HTTP backend), or `AWS_PROXY`.  
  - `request_templates`: Transforms incoming requests (e.g., XML → JSON).  
  - `request_parameters`: Adds/modifies headers or query parameters.  

---
Let’s break down the `request_parameters` and `request_templates` blocks in your Terraform configuration for AWS API Gateway. These are part of the `aws_api_gateway_integration` resource and define how API Gateway processes incoming requests before passing them to the backend (or, in this case, a **MOCK** integration).

---

### **1. `request_parameters`**
```terraform
request_parameters = {
  "integration.request.header.X-Authorization" = "'static'"
}
```

#### **What It Does**  
- **Adds/modifies headers or query parameters** sent to the backend integration.  
- In this case, it injects a header named `X-Authorization` with the value `static` into the request that API Gateway sends to the backend (even though this is a MOCK integration).  
* في هذا الجزء نقوم باضافة او تعديل الهيدر في الريكويست ومن ثم اعادة ارساله الى ال backend 
* the added header to the request  will be "X-Authorization: static"
* this means Set a custom header called X-Authorization in the request sent to the backend.
- **Use Case**:  
  - Adding security headers (e.g., API keys) to backend requests.  
  - Overriding parameters for integrations (e.g., Lambda function input).  


- If this were a real integration (e.g., Lambda/HTTP), the backend would receive `X-Authorization: static` in the request headers.  
- For MOCK integrations, this is purely for simulation/testing.  

---

### **2. `request_templates`**
```terraform
request_templates = {
  "application/xml" = <<EOF
{
   "statusCode" : 200,
   "message" : "Healthy"
}
EOF
}
```

#### **What It Does**  
- **Transforms the incoming request body** to a format the backend expects.  
- Here, it converts an XML request body to a JSON structure for the MOCK integration to process.  

Absolutely! Let's break this Terraform snippet down:

```hcl
request_templates = {
  "application/xml" = <<EOF
{
   "statusCode" : 200,
   "message" : "Healthy"
}
EOF
}
```

This is part of the **`aws_api_gateway_integration`** resource in Terraform. It defines how API Gateway should **transform incoming requests** before passing them to your backend.

---

### 🔍 What is `request_templates`?

- هذا الجزء يكون في الهيدر , بمجرد أن يكون النوع application/xml
- conten-type application/xml يتم تفعيل هذا الجزء
- searching at  **Content-Type** of the incoming request at **http header** (like `application/xml`, `application/json`, etc.).
- The **value** is a **Velocity Template Language (VTL)** script or literal that builds the **request payload** sent to your integration.

---

### 🧠 In your case:

```hcl
"application/xml" = <<EOF
{
   "statusCode" : 200,
   "message" : "Healthy"
}
EOF
```

- If the client sends a request with `Content-Type: application/xml`, **this template will be used**.
- API Gateway will **ignore the actual request body**, and instead send the following hardcoded JSON payload to the backend:

```json
{
  "statusCode": 200,
  "message": "Healthy"
}
```

Even though the client sent XML, you're transforming it to a **fixed JSON structure**.

---

### مثال اخر ديناميكي على ال request templete 


---

Let’s say you want to **convert an incoming XML payload to JSON dynamically** (not hardcoding values like `"Healthy"`). Here’s an example using Velocity Template Language (VTL) to map XML elements to JSON keys:

#### **Sample Input (XML):**
```xml
<HealthCheck>
  <ServiceName>PaymentGateway</ServiceName>
  <Status>OK</Status>
</HealthCheck>
```

#### **Terraform `request_templates` Configuration:**
```terraform
request_templates = {
  "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
{
  "service" : "$inputRoot.HealthCheck.ServiceName",
  "status" : "$inputRoot.HealthCheck.Status"
}
EOF
}
```

#### **Output (Transformed JSON):**
```json
{
  "service": "PaymentGateway",
  "status": "OK"
}
```

#### Key Details:
- **`$input.path('$')`**: Accesses the raw XML input.  
- **VTL Syntax**: Extracts values from XML using dot notation (e.g., `$inputRoot.HealthCheck.ServiceName`).  
- **Dynamic Mapping**: The JSON structure is built from the actual XML input, not predefined values.

---

### How It Works:
1. A client sends an XML request with `Content-Type: application/xml`.  
2. API Gateway uses the `application/xml` template to transform the XML body into JSON.  
3. The transformed JSON is sent to the backend (or used in a `MOCK` response).  


---
#### **5. `aws_api_gateway_method_response` & `aws_api_gateway_integration_response`**  
هذا الجزء يوضح كيفية الرد على الكلاينت بارسال الرد القادم من الباك إند إليه مرة أخرى
Let’s break down the `aws_api_gateway_method_response` and `aws_api_gateway_integration_response` resources in your Terraform configuration. These define how AWS API Gateway handles **responses** sent back to the client, including status codes and data transformations. Here’s a detailed explanation:

---

### **1. `aws_api_gateway_method_response`**  
* لا يعتبر الرد الفعلي فالرد الفعلي يكون في ال integration response .
```terraform
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.panda.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.panda1.http_method
  status_code = "200"
}
```
Absolutely — you're looking at a key piece of how **API Gateway** tells clients what kind of **response they’ll receive** from an endpoint. Let’s walk through this:

---

### 🔧 Terraform Block:
```hcl
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.panda.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.panda1.http_method
  status_code = "200"
}
```

---

### 🧠 What this block does:

It defines the **method response** for an API Gateway method — in this case, for a **200 OK response**.

---

### 🧩 Breakdown of each line:

| Line | What It Means |
|------|----------------|
| `rest_api_id = aws_api_gateway_rest_api.panda.id` | Links the response to your REST API (`panda`) |
| `resource_id = aws_api_gateway_resource.healthcheck.id` | Ties this to the `/healthcheck` path |
| `http_method = aws_api_gateway_method.panda1.http_method` | Specifies which HTTP method (e.g. GET) this response is for |
| `status_code = "200"` | Declares that this block describes the **200 OK** response for that method |

---

### 🧩 What is a *method response* in API Gateway?

The **method response** defines the structure of what your API can respond with — it's like declaring:
> “Hey clients, if you call `GET /healthcheck`, you might get a `200 OK` response, and here’s what it might look like.”

It doesn’t define the actual response body (that’s done in `integration_response`), but it declares:
- Status codes
- Response headers
- Response models (optional)

---

### 💬 So why is this needed?

Because API Gateway needs to know ahead of time:
- What response codes it should allow
- What headers or content types can be returned
- (Optional) What the response body will look like (using models)

This is especially useful for:
- **Documentation generation** in the API Gateway console
- **Client SDKs** built from the API
- **Validating** responses from integrations (if enabled)
---
### **2. `aws_api_gateway_integration_response`**  
```terraform
resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.panda.id
  resource_id = aws_api_gateway_resource.healthcheck.id
  http_method = aws_api_gateway_method.panda1.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  response_templates = {
    "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }
}
```

#### **What It Does**  
- **Transforms the backend’s raw response** into a format the client expects (e.g., XML).  
- Maps the backend’s output to the `200` status code declared in the method response.  

- **Status Code Mapping**:  
  - <span style="color:red;">`status_code` links this integration response to the method response’s `200`.</span> 
  - If your backend returns a different status (e.g., `2xx`), you’d map it here.  
- **Response Templates**:  
-  يتم تفعيلها في حالة إذا كان الكلاينت ينتظر الرد ليكون بصيغة ال xml :
  - accept header = "application/xml" 
  - Uses **Velocity Template Language (VTL)** to transform the response body.  
  - Here, it converts a JSON-like backend response to XML.  

---
<span style="color:red;">هناك نوعين من الهيدر مهمين جدا في حالة الطلب وفي حالة الرد </span>
**content-type , accept**
* **content-type** in the request
  * يعبر عن الطريقة التي تم ارسال طلب بها 
  * if it was json the the request sent using json 
* **accept header** in response 
  * يعبر عن الطريقة التي نرغب في أن نستلم الرد بها 

### Example 

```hcl
POST /api
Content-Type: application/json
Accept: application/xml
```
It means:

* “I’m sending JSON data.”

* “Please return the response in XML format.”
---
#### **Breakdown of the VTL Template**  

* أولا بداخل كود التيرافورم يتم استخدام كود خاص بال VTL
* يتم تمييز هذا الكود حيث يكتب بين EOF
```vtl
<<EOF
vtl line 1 
vtl line 2
EOF
```
* ثانيا طريقة كتابة هذا الكود محتلفة ولا يعد "#" فيها تعليقا وانما قد يستخدم في إنشاء المتغيرات او الجمل الشرطية 


## 🔍 The Full Snippet

```hcl
response_templates = {
  "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
}
```

---

## 🧠 What it does:

This block tells API Gateway:

> "When the response is being sent to the client **and** the client expects `Content-Type: application/xml`, transform the response using this template."

So it **converts the backend's JSON response → to an XML format** before sending it back.

---

## 🔎 Line-by-Line Breakdown

### 1️⃣ `response_templates = { ... }`

This maps **MIME types** (like `application/json`, `application/xml`) to **response transformation templates**. Each template is written in **VTL (Velocity Template Language)**.

---

### 2️⃣ `"application/xml" = <<EOF ... EOF`

This template will only be used if the client expects a response in XML (i.e., sets `Accept: application/xml`).

---

* $input is a VTL  built-in variable
* This variable is injected by API Gateway and gives you access to:
  * Request parameters
  * Headers
  * Query strings
  * and others 
* $input.path(...)
```vtl
$input.path(expression)
```
This is a method provided by API Gateway to extract parts of a JSON payload.
It’s kind of like saying:
“Go into this JSON object and give me the value at this path.”
```vtl
#set($inputRoot = $input.path('$'))
```
This means:

"Create a variable called inputRoot, and assign it the entire JSON document returned by the backend."

* <span style="color:red;">The '$' is a special JSON path that means:
👉 “The whole JSON object.”</span>
### 3️⃣ `#set($inputRoot = $input.path('$'))`

This line creates a variable named `$inputRoot` that holds the **entire JSON body** returned by the backend.  
- `$input.path('$')` gets the root of the response.
- Example backend response:
```json
{
  "statusCode": 200,
  "body": "Healthy"
}
```

After this line, you can access things like:
- `$inputRoot.body` → `"Healthy"`
- `$inputRoot.statusCode` → `200`

---

### 4️⃣ The XML Formatting:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
```

This outputs an XML string that wraps the value of `body` inside `<message>` tags.

So the final output to the client will be:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<message>
    Healthy
</message>
```

---

## 🧪 Summary Table

| Part | Meaning |
|------|---------|
| `response_templates` | VTL templates to format backend response |
| `"application/xml"` | Template applies if client expects XML |
| `$input.path('$')` | Reads the whole response body from backend |
| `$inputRoot.body` | Accesses the `"body"` field in that response |
| Final result | An XML string containing the `body` content |

---


#### **Example Flow**  
1. **Backend (MOCK) Returns**:  
   ```json
   {
     "statusCode": 200,
     "body": "Healthy"
   }
   ```  
2. **Integration Response Template Processes**:  
   - `$inputRoot.body` extracts `"Healthy"` from the JSON.  
   - Generates XML:  
     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <message>Healthy</message>
     ```  
3. **Client Receives**:  
   ```http
   HTTP/1.1 200 OK
   Content-Type: application/xml

   <?xml version="1.0" encoding="UTF-8"?>
   <message>Healthy</message>
   ```
---
#### **6. `aws_api_gateway_deployment`**  
* الكود جاهز ولكن يتم عمل اسنابشوت من بداية الدبلويمنت
## 🚨 What is `triggers`?

The `triggers` block is part of the `aws_api_gateway_deployment` resource in Terraform.

It’s used to **force a new deployment** of your API Gateway **when specific things change**, like:

- A new resource is added (like `/healthcheck`)
- A method is updated
- An integration is modified
- عادة ما يحدث اعادة البناء نتيجة لتغيير الكود من تيرافورم 
- إذا تم التعديل من الكلاود مباشرة فانه لن تتم إعادة البناء حتى يتم مناداة كود تيرافورم مرة أخرى  

> Without it, Terraform won’t always notice you changed something that *should* trigger a new deployment.

---

## 🔧 Full Breakdown

```hcl
triggers = {
  redeployment = sha1(jsonencode([
    aws_api_gateway_resource.healthcheck.id,
    aws_api_gateway_method.panda1.id,
    aws_api_gateway_integration.integration.id,
  ]))
}
```

### Let’s unpack it step by step:

1. **`triggers`**:
   - A **map** of values that Terraform watches.
   - If the value of **any key** in this map changes → Terraform **re-creates the deployment**.

2. **`redeployment = ...`**:
   - This is a custom key — you can name it anything, like `mytrigger`, but `redeployment` makes sense here.

3. **`jsonencode([...])`**:
   - Converts the list of values (resource IDs) into a **JSON string**.
   - Example: `[ "abc123", "def456", "ghi789" ]` → becomes a JSON string.

4. **`sha1(...)`**:
   - Hashes the JSON string to produce a single consistent value.
   - If any of the values in the list change → the hash changes → Terraform triggers a new deployment.

### باختصار , هذا ما يحدث 
```hcl
1- json ["abc123","def456","ghi789"]
2- sha1("[\"abc123\",\"def456\",\"ghi789\"]")
3- e2c569be17396eca2a2e3c11578123ed8cbb7b4b


```
---

## 🛡️ And what's this part?

```hcl
lifecycle {
  create_before_destroy = true
}
```

This is saying:

> “Create the new deployment **before** destroying the old one.”

This helps **avoid downtime** between deployments. Especially useful for production APIs!

---

#### **7. `aws_api_gateway_stage`**  


 
## 🔧 What is `aws_api_gateway_stage`?

A **stage** in API Gateway represents a version or environment of your API — kind of like:

- `dev`
- `test`
- `prod`
- or in your case: `"panda"`

Each **stage** points to a specific **deployment** (like a snapshot of your API setup at a certain time).

So when you deploy your API, you assign that deployment to a stage so clients can access it via a URL like:

```
https://<api-id>.execute-api.<region>.amazonaws.com/panda
```
* من غير إنشاء مرحلة لن تتمكن من الوصول الى ال API 
* يمكن إنشاء أكثر من مرحلة 
* يمكن التفرقة بين المراحل بعدة طرق مثل المتغيرات وال integration 
---

## 🧱 Now let’s break down your config:

```hcl
resource "aws_api_gateway_stage" "panda" {
  depends_on = [aws_api_gateway_deployment.panda1, aws_api_gateway_stage.panda]

  deployment_id = aws_api_gateway_deployment.panda.id
  rest_api_id   = aws_api_gateway_rest_api.panda.id
  stage_name    = "panda"
}
```

---

### 🔹 `resource "aws_api_gateway_stage" "panda"`

You're creating a new **stage** resource named `"panda"` in Terraform.

---

### 🔹 `stage_name = "panda"`

This is the name that will show up in the API URL:

```
.../panda/your-resource
```

---

### 🔹 `rest_api_id = aws_api_gateway_rest_api.panda.id`

This tells AWS:
> “This stage belongs to the REST API named `panda`.”

So it links the stage to the correct API Gateway instance.

---

### 🔹 `deployment_id = aws_api_gateway_deployment.panda.id`

This links the stage to a **specific deployment** of your API.

> Think of a deployment as a snapshot of your API’s routes, methods, integrations, etc.

When you deploy, you say:
> “This is the version of the API I want to expose in the `panda` stage.”

---
### تم تصحيح الكود 
### 🔹 `depends_on = [aws_api_gateway_deployment.panda1, aws_api_gateway_stage.panda]`

💥 This is the most curious part — and maybe a little suspicious 👀

This line says:

> “Wait for the `panda1` deployment *and* the stage `panda` before creating this stage.”

🟡 But... it’s referencing **itself** in the `depends_on` — which usually doesn't make sense and might actually be a **copy-paste mistake**.

Normally you'd see something like:

```hcl
depends_on = [aws_api_gateway_deployment.panda1]
```

Or just drop it entirely unless you have a reason to **enforce order manually**.

---

## 🛠️ In summary

| Line | What it does |
|------|--------------|
| `aws_api_gateway_stage "panda"` | Creates a stage (like a version) of your API |
| `deployment_id` | Tells AWS which deployment/version to use |
| `rest_api_id` | Tells AWS which API to attach this stage to |
| `stage_name` | The URL suffix for this version |
| `depends_on` | Forces Terraform to wait for certain resources first (possibly incorrect in this case) |

---
