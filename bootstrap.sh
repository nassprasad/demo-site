i have a task like to create route53 subdomain hosted zone. is there any dependecny to create sub domain along with ACM Certificats liek

Yes. Creating a Route 53 Hosted Zone and requesting an ACM certificate are related, but one does not always depend on the other. It depends on how you validate the certificate and who manages the parent domain.

Scenario 1: You own the parent domain in Route 53 (Most Common) ✅
Example:

Parent Domain: chartiq.com

Subdomain: demo.chartiq.com

Steps
Create a Hosted Zone for demo.chartiq.com

Update the parent hosted zone (chartiq.com) with NS records pointing to the new subdomain hosted zone.

Request an ACM certificate for:

demo.chartiq.com

or *.demo.chartiq.com

ACM creates a DNS validation CNAME.

Add the validation CNAME to the demo.chartiq.com hosted zone.

ACM automatically validates the certificate.

Dependency

Hosted Zone
      ↓
DNS Delegation (NS Records)
      ↓
Request ACM Certificate
      ↓
Add Validation CNAME
      ↓
Certificate Issued
Scenario 2: Parent domain is NOT managed in Route 53
This is similar to your previous ChartIQ/Infoblox setup.

Example:

Parent Domain:
chartiq.com  --> Managed in Infoblox

Need:
demo.chartiq.com
You can still:

Create a Route53 hosted zone for demo.chartiq.com

Request ACM certificate

But...

You must ask the DNS team (Infoblox administrators) to create the NS delegation in the parent zone.

Example

demo.chartiq.com

NS
ns-123.awsdns-11.com
ns-456.awsdns-22.net
ns-789.awsdns-33.org
ns-012.awsdns-44.co.uk
Without this delegation:

ACM DNS validation may fail.

Internet users won't resolve demo.chartiq.com via your Route 53 hosted zone.

Does ACM require the Hosted Zone first?
DNS Validation (Recommended)
Yes, practically.

The hosted zone should already exist because ACM gives you a DNS CNAME record that must be added somewhere.

Example:

_acbd123.demo.chartiq.com

CNAME

_abcdxyz.acm-validations.aws.
You add this record into your Route53 hosted zone.

Email Validation
No hosted zone is required.

ACM sends validation emails to:

admin@domain
administrator@domain
hostmaster@domain
webmaster@domain
postmaster@domain
This method is rarely used nowadays.

Typical AWS Production Flow
Create Hosted Zone
        │
        ▼
Delegate NS from Parent Domain
        │
        ▼
Request ACM Certificate
        │
        ▼
DNS Validation CNAME
        │
        ▼
Certificate Issued
        │
        ▼
Attach ACM to CloudFront / ALB
For your project
Based on our previous discussions:

Parent Domain:
chartiq.com
        │
        │ (Managed in Infoblox)
        ▼
demo.chartiq.com
        │
        ├── Route53 Hosted Zone
        ├── ACM (*.demo.chartiq.com)
        ├── CloudFront
        └── Lambda@Edge
The sequence would be:

Create the Route 53 hosted zone for demo.chartiq.com.

Share the hosted zone's four NS records with the Infoblox/DNS team so they can delegate demo.chartiq.com.

Request the ACM certificate (in us-east-1 if it's for CloudFront).

Add the ACM validation CNAME to the demo.chartiq.com hosted zone.

Wait for ACM to issue the certificate.

Attach the certificate to your CloudFront distribution.

This is the standard production approach used in AWS environments.


mine is Scenario 2 

need internal.chartiq.com as sub domain 

Perfect. Based on what we've discussed previously about your environment, your scenario looks like this:

Parent Domain
─────────────
chartiq.com
      │
      │  (Managed by Infoblox / DNS Team)
      │
      ├─────────────────────────────────────┐
      │                                     │
      ▼                                     ▼
internal.chartiq.com                other subdomains...
(Route53 Hosted Zone)
      │
      ├── ACM Certificate
      ├── CloudFront / ALB
      ├── Route53 Records
      └── Application
Dependencies
Step 1. Create the Route 53 Hosted Zone
Create a Public Hosted Zone for:

internal.chartiq.com
AWS will generate four NS records similar to:

ns-123.awsdns-01.com
ns-456.awsdns-02.net
ns-789.awsdns-03.org
ns-101.awsdns-04.co.uk
Step 2. DNS Delegation (Required)
Since chartiq.com is managed in Infoblox, you cannot complete the setup yourself.

You need the DNS/Infoblox team to create an NS delegation:

Record Name:
internal.chartiq.com

Type:
NS

Values:
ns-123.awsdns-01.com
ns-456.awsdns-02.net
ns-789.awsdns-03.org
ns-101.awsdns-04.co.uk
This is the most important dependency.

Without this delegation:

❌ internal.chartiq.com will not resolve.

❌ ACM DNS validation will generally fail because the validation CNAME won't be reachable via public DNS.

Step 3. Request ACM Certificate
If this is for CloudFront, request the certificate in N. Virginia (us-east-1).

You can request:

internal.chartiq.com
or, if you'll have multiple hosts under it:

*.internal.chartiq.com
For example:

app.internal.chartiq.com

api.internal.chartiq.com

ci.internal.chartiq.com

Step 4. DNS Validation
ACM will provide a CNAME like:

_abcd123.internal.chartiq.com

CNAME

_xyz.acm-validations.aws.
Add this record to the internal.chartiq.com hosted zone in Route 53.

After the NS delegation is active, ACM will automatically validate the certificate.

Complete Workflow
Create Hosted Zone
        │
        ▼
AWS generates NS records
        │
        ▼
Share NS records with Infoblox Team
        │
        ▼
Infoblox creates NS delegation
        │
        ▼
Request ACM Certificate (us-east-1)
        │
        ▼
Add ACM Validation CNAME
        │
        ▼
Certificate Issued
        │
        ▼
Attach ACM to CloudFront / ALB
One thing to verify
You mentioned only internal.chartiq.com.

Is your application going to use:

Option 1: internal.chartiq.com (root of the subdomain), or

Option 2: hosts beneath it, such as app.internal.chartiq.com, ci.internal.chartiq.com, or api.internal.chartiq.com?

The answer affects whether you should request an ACM certificate for internal.chartiq.com, *.internal.chartiq.com, or both (using Subject Alternative Names), which is the common production approach.


what infoblox will do after share my NS resoirds ?

Good question. Understanding what the Infoblox team does is important because this is the key integration between your AWS Route 53 hosted zone and the existing chartiq.com DNS.

Current Situation
chartiq.com
    │
    ├── Managed in Infoblox
    │
    └── You create Route53 Hosted Zone
         internal.chartiq.com
When you create the Route 53 hosted zone, AWS gives you 4 authoritative name servers.

Example:

internal.chartiq.com

NS

ns-123.awsdns-01.com
ns-456.awsdns-02.net
ns-789.awsdns-03.org
ns-101.awsdns-04.co.uk
These name servers are authoritative only if the parent zone (chartiq.com) delegates the subdomain to them.

What the Infoblox Team Does
They log in to their Infoblox DNS management system and create one NS delegation in the chartiq.com zone.

They add:

Name	Type	Value
internal.chartiq.com	NS	ns-123.awsdns-01.com
internal.chartiq.com	NS	ns-456.awsdns-02.net
internal.chartiq.com	NS	ns-789.awsdns-03.org
internal.chartiq.com	NS	ns-101.awsdns-04.co.uk
That's it.

They do not create your application records (A, CNAME, Alias, etc.) in Infoblox. Those records will live in your Route 53 hosted zone after delegation.

Before Delegation
Suppose someone queries:

app.internal.chartiq.com
DNS resolution looks like:

Internet
    │
    ▼
chartiq.com (Infoblox)
    │
    └── Doesn't know about internal.chartiq.com
            ↓
NXDOMAIN
The lookup fails.

After Delegation
Once the Infoblox team adds the NS records:

Internet
    │
    ▼
chartiq.com (Infoblox)
    │
    └── internal.chartiq.com ?
            │
            ▼
Go ask these AWS Name Servers
            │
            ▼
Route53 Hosted Zone
            │
            ▼
app.internal.chartiq.com
            │
            ▼
CloudFront / ALB / EC2
Now every DNS query for *.internal.chartiq.com is answered by Route 53.

Why This Is Required for ACM
Suppose ACM asks you to create:

_acbd123.internal.chartiq.com

CNAME

_xyz.acm-validations.aws.
The CNAME is added to your Route 53 hosted zone.

When ACM checks for the validation record:

It asks the DNS for internal.chartiq.com.

The parent chartiq.com zone (Infoblox) returns the AWS NS records.

ACM follows those name servers to Route 53.

Route 53 returns the CNAME.

ACM validates the certificate.

Without the NS delegation, ACM cannot reliably find the validation record.

What You Need to Send to the Infoblox Team
After creating the hosted zone, send them something like:

Please delegate the subdomain internal.chartiq.com to the following AWS Route 53 name servers:

ns-123.awsdns-01.com

ns-456.awsdns-02.net

ns-789.awsdns-03.org

ns-101.awsdns-04.co.uk

Once they confirm the delegation is in place, you can manage all DNS records under internal.chartiq.com (A, AAAA, CNAME, Alias, TXT, MX, ACM validation records, etc.) directly in Route 53 without needing further changes in Infoblox for those records.

-5454red zcxsqEDSFCX 


Save as PDF
