   
	                 Internet
                        │
                        ▼
                 Amazon CloudFront
                        │
                        ▼
              Application Load Balancer
                        │
                        ▼
              Auto Scaling Group (ASG)
              ┌─────────┴─────────┐
              ▼                   ▼
          EC2 Instance      EC2 Instance
        (Private Subnet)  (Private Subnet)




                 Internet
                    │
                    ▼
             Amazon CloudFront ( WAF )
                    │
                    ▼
				API Gateway 
					│
                    ▼
				VPC Link 
					│
                    ▼

          Application Load Balancer ( internal-facing)
                    │
                    ▼
          Auto Scaling Group (ASG)
          ┌─────────┴─────────┐
          ▼                   ▼
      EC2 Instance      EC2 Instance
    (Private IP -ENI)  (Private IP -ENI)
	       ┌─────────┴─────────┐
          ▼                   ▼
		App :port         App :port


        
