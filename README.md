# quickstart-ibaset-solumina
## Solumina on the AWS Cloud

**Solumina** is a Manufacturing Execution System (MES) software suite that manages work and quality processes for the manufacturing maintenance, repair, and overhaul of engineered products.

This Quick Start reference deployment guide provides step-by-step instructions for deploying iBASEt’s Solumina MES on the AWS Cloud. 

![Quick Start Architecture for Solumina MES](https://d0.awsstatic.com/partner-network/QuickStart/ibaset-solumina-architecture.png)

This Quick Start sets up the following:
•	A highly available architecture that spans three Availability Zones.*
•	A VPC configured with public and private subnets, according to AWS best practices, to provide you with your own virtual network.*
•	In the public subnets, managed network address translation (NAT) gateways to allow outbound internet access for resources in the private subnets.*
•	In the public subnets, a Linux bastion host in an Auto Scaling group to allow inbound Secure Shell (SSH) access to Amazon Elastic Compute Cloud (Amazon EC2) instances in public and private subnets.*
•	In the private subnets, the Solumina proprietary software and other infrastructure artifacts, including AWS Managed Services, installed as a high-availability cluster.
•	An Application Load Balancer to route traffic to the Solumina web application over HTTPS.
* The template that deploys the Quick Start into an existing VPC skips the components marked by asterisks and prompts you for your existing VPC configuration.

For architectural details, best practices, step-by-step instructions, and customization options, see the 
[deployment guide](https://fwd.aws/v3QxK).

To post feedback, submit feature ideas, or report bugs, use the **Issues** section of this GitHub repo.
If you'd like to submit code for this Quick Start, please review the [AWS Quick Start Contributor's Kit](https://aws-quickstart.github.io/).
