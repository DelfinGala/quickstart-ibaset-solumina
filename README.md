# quickstart-ibaset-solumina
## Solumina on the AWS Cloud

**Solumina** is a Manufacturing Execution System (MES) software suite that manages work and quality processes for the manufacturing maintenance, repair, and overhaul of engineered products.

This Quick Start reference deployment guide provides step-by-step instructions for deploying iBASEt’s Solumina MES on the AWS Cloud. 

![Quick Start Architecture for Solumina MES](https://d0.awsstatic.com/partner-network/QuickStart/ibaset-solumina-architecture.png)

This Quick Start sets up the following:
- A highly available architecture that spans three Availability Zones.*
- A VPC configured with public and private subnets, according to AWS best practices, to provide you with your own virtual network.*
- In the public subnets:
  - Managed network address translation (NAT) gateways to allow outbound internet access for resources in the private subnets.*
  - A Linux bastion host in an Auto Scaling group to allow inbound Secure Shell (SSH) access to Amazon Elastic Compute Cloud (Amazon EC2) instances in public and private subnets.*
- In the private subnets, installed as highly available clusters:
  - The Solumina proprietary software.
  –	Amazon Elasticsearch Service (Amazon ES).
  - A MongoDB resource.
  - Amazon Relational Database Service (Amazon RDS).
- An Application Load Balancer to route traffic to the Solumina web application over HTTPS.
- Amazon Elastic Kubernetes Service (Amazon EKS).
- An Amazon S3 bucket for storing Quick Start assets.
- Amazon Elastic File System (Amazon EFS) to provide on-demand scaling and management of AWS Cloud services and resources.

*The template that deploys the Quick Start into an existing VPC skips the components marked by asterisks and prompts you for your existing VPC configuration.

For architectural details, best practices, step-by-step instructions, and customization options, see the 
[deployment guide](https://fwd.aws/v3QxK).

To post feedback, submit feature ideas, or report bugs, use the **Issues** section of this GitHub repo.
If you'd like to submit code for this Quick Start, please review the [AWS Quick Start Contributor's Kit](https://aws-quickstart.github.io/).
